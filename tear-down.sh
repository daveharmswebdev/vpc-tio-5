#!/bin/bash

source ./variables.sh

# Function to get resource ID by tag name
get_resource_id() {
    local resource_type=$1
    local tag_value=$2
    local query=$3

    aws ec2 describe-"${resource_type}"s \
        --filters "Name=tag:Name,Values=${tag_value}" \
        --query "${query}" \
        --output text
}

echo "Starting teardown process..."

# gathering resource ids
VPC_ID=$(get_resource_id vpc $VPC_NAME "Vpcs[0].VpcId")
echo "Found VPC: ${VPC_ID}"

PUBLIC_SUBNET_ID=$(get_resource_id subnet PublicSubnet "Subnets[0].SubnetId")
echo "Found Public Subnet: ${PUBLIC_SUBNET_ID}"

PRIVATE_SUBNET_ID=$(get_resource_id subnet PrivateSubnet "Subnets[0].SubnetId")
echo "Found Private Subnet: ${PRIVATE_SUBNET_ID}"

IGW_ID=$(get_resource_id internet-gateway $IGW_NAME "InternetGateways[0].InternetGatewayId")
echo "Found Internet Gateway: ${IGW_ID}"

PUBLIC_RT_ID=$(get_resource_id route-table $PUBLIC_RT_NAME "RouteTables[0].RouteTableId")
echo "Found Public Route Table: ${PUBLIC_RT_ID}"

# Get Security Group IDs
PUBLIC_SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${PUBLIC_SG_NAME}" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
echo "Found Public Security Group: ${PUBLIC_SG_ID}"

# removing resources

# Terminate EC2 instances
echo "Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Terminating EC2 instances: ${INSTANCE_IDS}"
    aws ec2 terminate-instances --instance-ids "${INSTANCE_IDS}"
    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids" ${INSTANCE_IDS}"
    echo "EC2 instances terminated: ${INSTANCE_IDS}"
fi

# Delete Security Groups
echo "Deleting security groups..."
if [ -n "$PUBLIC_SG_ID" ] && [ "$PUBLIC_SG_ID" != "None" ]; then
    echo "Deleting Public Security Group: ${PUBLIC_SG_ID}"
    aws ec2 delete-security-group --group-id "${PUBLIC_SG_ID}"
    echo "Public Security Group deleted: ${PUBLIC_SG_ID}"
fi

# delete route table association and routes
PUBLIC_RT_ASSOC_ID=$(aws ec2 describe-route-tables \
  --route-table-id "${PUBLIC_RT_ID}" \
  --query 'RouteTables[0].Associations[0].RouteTableAssociationId' \
  --output text)
echo "Deleting public route table association: ${PUBLIC_RT_ASSOC_ID}"
aws ec2 disassociate-route-table --association-id "${PUBLIC_RT_ASSOC_ID}"
echo "Deleted ${PRIVATE_RT_ASSOC_ID}"

# Deleting public route table
if [ -n "$PUBLIC_RT_ID" ] && [ "$PUBLIC_RT_ID" != "None" ]; then
    echo "Deleting public route table ${PUBLIC_RT_ID}"
    aws ec2 delete-route-table --route-table-id "${PUBLIC_RT_ID}"
    echo "Deleted public route table ${PUBLIC_RT_ID}"
fi

if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
  echo "Detaching Internet Gateway: ${IGW_ID}"
  aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}"
  echo "Deleting Internet Gateway: ${IGW_ID}"
  aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}"
  echo "Internet Gateway deleted: ${IGW_ID}"
fi

# Delete Subnets
echo "Deleting subnets..."
if [ -n "$PRIVATE_SUBNET_ID" ] && [ "$PRIVATE_SUBNET_ID" != "None" ]; then
    echo "Deleting Private Subnet: ${PRIVATE_SUBNET_ID}"
    aws ec2 delete-subnet --subnet-id "${PRIVATE_SUBNET_ID}"
    echo "Private Subnet deleted: ${PRIVATE_SUBNET_ID}"
fi

if [ -n "$PUBLIC_SUBNET_ID" ] && [ "$PUBLIC_SUBNET_ID" != "None" ]; then
    echo "Deleting Public Subnet: ${PUBLIC_SUBNET_ID}"
    aws ec2 delete-subnet --subnet-id "${PUBLIC_SUBNET_ID}"
    echo "Public Subnet deleted: ${PUBLIC_SUBNET_ID}"
fi

echo "Getting vpc id for ${VPC_NAME}"

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
    echo "Error: Could not find VPC with name ${VPC_NAME}"
    exit 1
fi

echo "Deleting vpc: ${VPC_NAME} with id: ${VPC_ID}"
aws ec2 delete-vpc --vpc-id "${VPC_ID}"
echo "Vpc deleted"
