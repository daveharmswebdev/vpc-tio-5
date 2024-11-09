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
