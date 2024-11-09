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
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" \
  --query 'Vpc.VpcId' \
  --output text)
echo "Created vpc with vpc id: ${VPC_ID}"

# Enable DNS hostname support for the VPC
echo "Enabling DNS hostnames for VPC: ${VPC_ID}"
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames '{"Value":true}'
echo "DNS hostnames enabled for VPC: ${VPC_ID}"

# Create Public Subnet
echo "Creating public subnet..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block ${PUBLIC_SUBNET_CIDR} \
    --availability-zone ${AWS_REGION}a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet}]' \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Public Subnet created: ${PUBLIC_SUBNET_ID}"

# Create Private Subnet
echo "Creating private subnet..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block ${PRIVATE_SUBNET_CIDR} \
    --availability-zone ${AWS_REGION}b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnet}]' \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Private Subnet created: ${PRIVATE_SUBNET_ID}"

# create internet gateway
echo "creating internet gateway"
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${IGW_NAME}}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)
echo "Internet Gateway created: ${IGW_ID}"

# attach internet gateway to vpc
echo "attaching internet gateway ${IGW_ID} to vpc ${VPC_ID}"
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID
echo "internet gateway ${IGW_ID} attached to vpc ${VPC_ID}"
