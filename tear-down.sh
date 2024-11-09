#!/bin/bash

source ./variables.sh

# Function to get resource ID by tag name
get_resource_id() {
    local resource_type=$1
    local tag_value=$2
    local query=$3

    aws ec2 describe-${resource_type}s \
        --filters "Name=tag:Name,Values=${tag_value}" \
        --query "${query}" \
        --output text
}

echo "Starting teardown process..."

PUBLIC_SUBNET_ID=$(get_resource_id subnet PublicSubnet "Subnets[0].SubnetId")
echo "Found Public Subnet: ${PUBLIC_SUBNET_ID}"

PRIVATE_SUBNET_ID=$(get_resource_id subnet PrivateSubnet "Subnets[0].SubnetId")
echo "Found Private Subnet: ${PRIVATE_SUBNET_ID}"

# Delete Subnets
echo "Deleting subnets..."
if [ ! -z "$PRIVATE_SUBNET_ID" ] && [ "$PRIVATE_SUBNET_ID" != "None" ]; then
    echo "Deleting Private Subnet: ${PRIVATE_SUBNET_ID}"
    aws ec2 delete-subnet --subnet-id ${PRIVATE_SUBNET_ID}
    echo "Private Subnet deleted: ${PRIVATE_SUBNET_ID}"
fi

if [ ! -z "$PUBLIC_SUBNET_ID" ] && [ "$PUBLIC_SUBNET_ID" != "None" ]; then
    echo "Deleting Public Subnet: ${PUBLIC_SUBNET_ID}"
    aws ec2 delete-subnet --subnet-id ${PUBLIC_SUBNET_ID}
    echo "Public Subnet deleted: ${PUBLIC_SUBNET_ID}"
fi

echo "Getting vpc id for ${VPC_NAME}"

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=${VPC_NAME}" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "Found vpc: ${VPC_ID}"

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
    echo "Error: Could not find VPC with name ${VPC_NAME}"
    exit 1
fi

echo "Deleting vpc: ${VPC_NAME} with id: ${VPC_ID}"
aws ec2 delete-vpc --vpc-id ${VPC_ID}
echo "Vpc deleted"
