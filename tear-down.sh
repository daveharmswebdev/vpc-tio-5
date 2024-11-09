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

# removing resources
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
