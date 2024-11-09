#!/bin/bash

# region
export AWS_REGION="us-east-1"

# resources
export VPC_NAME="gl-vpc"
export IGW_NAME="gl-igw"
export PUBLIC_RT_NAME="PublicRT"

# cidr blocks
export VPC_CIDR="10.0.0.0/16"
export PUBLIC_SUBNET_CIDR="10.0.1.0/24"
export PRIVATE_SUBNET_CIDR="10.0.2.0/24"
