#!/bin/bash

source ./variables.sh

# config.env is a private gitignored file that is used to store your own ip address
if [ -f "config.env" ]; then
    source config.env
else
    echo "Missing config.env file. Please create it with your public IP."
    exit 1
fi

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
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames '{"Value":true}'
echo "DNS hostnames enabled for VPC: ${VPC_ID}"

# Create Public Subnet
echo "Creating public subnet..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block ${PUBLIC_SUBNET_CIDR} \
    --availability-zone ${AWS_REGION}a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet}]' \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Public Subnet created: ${PUBLIC_SUBNET_ID}"

# Create Private Subnet
echo "Creating private subnet..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
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
  --vpc-id "$VPC_ID" \
  --internet-gateway-id "$IGW_ID"
echo "internet gateway ${IGW_ID} attached to vpc ${VPC_ID}"

# create public route table
echo "creating public route table"
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PUBLIC_RT_NAME}}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)
echo "Public Route Table created: ${PUBLIC_RT_ID}"

# add route to IGW in public route table
echo "Creating route to internet gateway in public route table..."
aws ec2 create-route \
  --route-table-id "$PUBLIC_RT_ID" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID"
echo "Route to Internet Gateway created in public route table: ${PUBLIC_RT_ID}"

# associate public subnet with public route table
echo "Associating public subnet with public route table"
PUBLIC_RT_ASSOC_ID=$(aws ec2 associate-route-table \
  --subnet-id "$PUBLIC_SUBNET_ID" \
  --route-table-id "$PUBLIC_RT_ID" \
  --query 'AssociationId' \
  --output text)
echo "Public subnet ${PUBLIC_SUBNET_ID} associated with Public Route Table ${PUBLIC_RT_ID}: ${PUBLIC_RT_ASSOC_ID}"


# create security group for public instances
PUBLIC_SG_ID=$(aws ec2 create-security-group \
    --group-name "$PUBLIC_SG_NAME" \
    --description "Security group for public instances" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)
echo "Public Security Group created: ${PUBLIC_SG_ID}"

# Allow inbound SSH to public instances
echo "Adding SSH inbound rule to Public Security Group..."
aws ec2 authorize-security-group-ingress \
    --group-id "$PUBLIC_SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "${MY_IP}/32"
echo "SSH inbound rule added to Public Security Group: ${PUBLIC_SG_ID}"

echo "Adding HTTP inbound rule to Public Security Group..."
aws ec2 authorize-security-group-ingress \
    --group-id "$PUBLIC_SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
echo "HTTP inbound rule added to Public Security Group: ${PUBLIC_SG_ID}"

# Launch EC2 instance in public subnet
echo "Launching EC2 instance in public subnet..."
PUBLIC_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --count 1 \
    --instance-type t2.micro \
    --key-name "${KEY_PAIR_NAME}" \
    --security-group-ids "$PUBLIC_SG_ID" \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --associate-public-ip-address \
    --user-data file://public-user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=PublicInstance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Public EC2 instance launched: ${PUBLIC_INSTANCE_ID}"

