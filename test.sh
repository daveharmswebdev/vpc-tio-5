#!/bin/bash

source ./variables.sh


if [ -f "config.env" ]; then
    source config.env
    echo "Here is your ip address: ${MY_IP}"
else
    echo "Missing config.env file. Please create it with your public IP."
    exit 1
fi

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

PRIVATE_RT_ID=$(get_resource_id route-table $PRIVATE_RT_NAME "RouteTables[0].RouteTableId")
echo "Found Private Route Table: ${PRIVATE_RT_ID}"

echo "Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)
echo "EC2 ids: ${INSTANCE_IDS}"


NAT_GW_ID=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[*].NatGatewayId" --output text)
echo "Found NAT Gateway: ${NAT_GW_ID}"
