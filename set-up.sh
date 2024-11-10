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
    --output text --no-paginate)
echo "Public Subnet created: ${PUBLIC_SUBNET_ID}"

# Create Private Subnet
echo "Creating private subnet..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block ${PRIVATE_SUBNET_CIDR} \
    --availability-zone ${AWS_REGION}b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnet}]' \
    --query 'Subnet.SubnetId' \
    --output text --no-paginate)
echo "Private Subnet created: ${PRIVATE_SUBNET_ID}"

# create internet gateway
echo "creating internet gateway"
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${IGW_NAME}}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text --no-paginate)
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
  --output text --no-paginate)
echo "Public Route Table created: ${PUBLIC_RT_ID}"

# create private route table
echo "creating private route table"
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PRIVATE_RT_NAME}}]" \
  --query 'RouteTable.RouteTableId' \
  --output text --no-paginate)
echo "Private Route Table created: ${PRIVATE_RT_ID}"

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
  --output text --no-paginate)
echo "Public subnet ${PUBLIC_SUBNET_ID} associated with Public Route Table ${PUBLIC_RT_ID}: ${PUBLIC_RT_ASSOC_ID}"

# allocate elastic ip for NAT gateway
echo "allocating elastic ip for NAT gateway..."
EIP_ALLOC_ID=$(aws ec2 allocate-address --query 'AllocationId' --output text --no-paginate)
echo "Elastic ip allocated with Allocation Id: ${EIP_ALLOC_ID}"

# Create NAT Gateway in Public Subnet
echo "Creating NAT Gateway in public subnet..."
NAT_GW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --allocation-id "$EIP_ALLOC_ID" \
    --query 'NatGateway.NatGatewayId' \
    --output text --no-paginate)

echo "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID"
echo "NAT Gateway created: ${NAT_GW_ID}"

# Add tags to NAT Gateway after creation
echo "Tagging NAT Gateway..."
aws ec2 create-tags \
    --resources "$NAT_GW_ID" \
    --tags Key=Name,Value="${NAT_GATEWAY_NAME}"
echo "NAT Gateway tagged: ${NAT_GW_ID}"

# Add Route to Private Route Table
echo "Adding route to private route table to use NAT Gateway..."
aws ec2 create-route \
    --route-table-id "$PRIVATE_RT_ID" \
    --destination-cidr-block "0.0.0.0/0" \
    --nat-gateway-id "$NAT_GW_ID"
echo "Route added to Private Route Table: ${PRIVATE_RT_ID} for NAT Gateway: ${NAT_GW_ID}"

# Associate Private Subnet with Private Route Table
echo "Associating private subnet with private route table..."
PRIVATE_RT_ASSOC_ID=$(aws ec2 associate-route-table \
  --subnet-id "$PRIVATE_SUBNET_ID" \
  --route-table-id "$PRIVATE_RT_ID" \
  --query 'AssociationId' \
  --output text --no-paginate)
echo "Private subnet ${PRIVATE_SUBNET_ID} associated with Private Route Table ${PRIVATE_RT_ID}: ${PRIVATE_RT_ASSOC_ID}"

# create security group for public instances
PUBLIC_SG_ID=$(aws ec2 create-security-group \
    --group-name "$PUBLIC_SG_NAME" \
    --description "Security group for public instances" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text --no-paginate)
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
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PUBLIC_EC2_INSTANCE_NAME}}]" \
    --query 'Instances[0].InstanceId' \
    --output text --no-paginate)
echo "Public EC2 instance launched: ${PUBLIC_INSTANCE_ID}"

# create security group for private ec2 instance
echo "Creating Security Group for private instances..."
PRIVATE_SG_ID=$(aws ec2 create-security-group \
    --group-name "$PRIVATE_SG_NAME" \
    --description "Opens security groups for ssh and icmp only from the public subnet" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text --no-paginate)
echo "Private Security Group created: ${PRIVATE_SG_ID}"

# Allow SSH from the public subnet to private instances
echo "Adding SSH inbound rule to Private Security Group..."
aws ec2 authorize-security-group-ingress \
    --group-id "$PRIVATE_SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "${PUBLIC_SUBNET_CIDR}"
echo "SSH inbound rule added to Private Security Group: ${PRIVATE_SG_ID}"

# Allow ICMP (Ping) from the public subnet to private instances
echo "Adding ICMP inbound rule to Private Security Group..."
aws ec2 authorize-security-group-ingress \
    --group-id "$PRIVATE_SG_ID" \
    --protocol icmp \
    --port -1 \
    --cidr "${PUBLIC_SUBNET_CIDR}"
echo "ICMP inbound rule added to Private Security Group: ${PRIVATE_SG_ID}"

# Launch an EC2 instance in the Private Subnet
echo "Launching EC2 instance in private subnet..."
PRIVATE_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --count 1 \
    --instance-type t2.micro \
    --key-name "${KEY_PAIR_NAME}" \
    --security-group-ids "$PRIVATE_SG_ID" \
    --subnet-id "$PRIVATE_SUBNET_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PRIVATE_EC2_INSTANCE_NAME}}]" \
    --associate-public-ip-address \
    --query 'Instances[0].InstanceId' \
    --output text --no-paginate)
echo "Private EC2 instance launched: ${PRIVATE_INSTANCE_ID}"