#!/bin/bash

# region
export AWS_REGION="us-east-1"

# resources
export VPC_NAME="gl-vpc"
export IGW_NAME="gl-igw"
export NAT_GATEWAY_NAME="GlNATGateway"
export PUBLIC_RT_NAME="PublicRT"
export PRIVATE_RT_NAME="PrivateRT"
export PUBLIC_SG_NAME="PublicSG"
export PRIVATE_SG_NAME="PrivateSG"
export PUBLIC_EC2_INSTANCE_NAME="PublicInstance"
export PRIVATE_EC2_INSTANCE_NAME="PrivateInstance"

# cidr blocks
export VPC_CIDR="10.0.0.0/16"
export PUBLIC_SUBNET_CIDR="10.0.1.0/24"
export PRIVATE_SUBNET_CIDR="10.0.2.0/24"

# ec2 configuration
export AMI_ID="ami-0984f4b9e98be44bf"
export INSTANCE_TYPE="t2.micro"
export KEY_PAIR_NAME="liftshift"
