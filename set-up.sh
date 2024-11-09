#!/bin/bash

source ./variables.sh

# Verify required variables are set
if [ -z "$VPC_NAME" ] || [ -z "$AWS_REGION" ]; then
    echo "Error: Required variables are not set. Please check variables.sh"
    exit 1
fi

echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block ${VPC_CIDR} \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]' \
  --query 'Vpc.VpcId' \
  --output text)
echo "Created vpc with vpc id: ${VPC_ID}"