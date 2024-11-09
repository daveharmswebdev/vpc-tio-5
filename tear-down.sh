#!/bin/bash

source ./variables.sh

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
