# TIO-5

These scripts are for the setup and teardown of the VPC, subnets
gateways, route tables and ec2 instances as required by the TIO-5
exercise.

Please check the commit history, as this will illustrate how these
scripts were composed. 

If you are trying to execute these scripts on your own you will
have to have [AWS CLI installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

Each script will have to modified to be made an executable.  For example:

```bash
chmod +x test.sh
```

### Setup Printout:

```bash
❯ ./set-up.sh
Creating VPC...
Created vpc with vpc id: vpc-0f1d8810f59dd6611
Enabling DNS hostnames for VPC: vpc-0f1d8810f59dd6611
DNS hostnames enabled for VPC: vpc-0f1d8810f59dd6611
Creating public subnet...
Public Subnet created: subnet-0a5b814ea9334c3ee
Creating private subnet...
Private Subnet created: subnet-0719f89a5c1691606
creating internet gateway
Internet Gateway created: igw-0e0d890f67e638d22
attaching internet gateway igw-0e0d890f67e638d22 to vpc vpc-0f1d8810f59dd6611
internet gateway igw-0e0d890f67e638d22 attached to vpc vpc-0f1d8810f59dd6611
creating public route table
Public Route Table created: rtb-0a6631be826cf8f1c
Creating route to internet gateway in public route table...
Route to Internet Gateway created in public route table: rtb-0a6631be826cf8f1c
Associating public subnet with public route table
Public subnet subnet-0a5b814ea9334c3ee associated with Public Route Table rtb-0a6631be826cf8f1c: rtbassoc-0d3d859d41829f800
```

### Tear down printout:
```bash
❯ ./tear-down.sh
Starting teardown process...
Found VPC: vpc-0f1d8810f59dd6611
Found Public Subnet: subnet-0a5b814ea9334c3ee
Found Private Subnet: subnet-0719f89a5c1691606
Found Internet Gateway: igw-0e0d890f67e638d22
Found Public Route Table: rtb-0a6631be826cf8f1c
Deleting public route table association: rtbassoc-0d3d859d41829f800
Deleted 
Deleting public route table rtb-0a6631be826cf8f1c
Deleted public route table rtb-0a6631be826cf8f1c
Detaching Internet Gateway: igw-0e0d890f67e638d22
Deleting Internet Gateway: igw-0e0d890f67e638d22
Internet Gateway deleted: igw-0e0d890f67e638d22
Deleting subnets...
Deleting Private Subnet: subnet-0719f89a5c1691606
Private Subnet deleted: subnet-0719f89a5c1691606
Deleting Public Subnet: subnet-0a5b814ea9334c3ee
Public Subnet deleted: subnet-0a5b814ea9334c3ee
Getting vpc id for gl-vpc
Deleting vpc: gl-vpc with id: vpc-0f1d8810f59dd6611
Vpc deleted
```

### Mistakes that I learned from

This was wrong.  Because it was assigning an object to my variable: PUBLIC_RT_ID

```bash
# create public route table
echo "creating public route table"
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PUBLIC_RT_NAME}}]")
echo "Public Route Table created: ${PUBLIC_RT_ID}"
```

And when I was trying to create a route in my route table, I was passing the object and not the id to the command.  And an error would be generated.

Correction:

```bash
echo "creating public route table"
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PUBLIC_RT_NAME}}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)
echo "Public Route Table created: ${PUBLIC_RT_ID}"
```

What's going on here is that we create the route table but we drill into the json object:

```json
{
    "RouteTable": {
        "Associations": [],
        "PropagatingVgws": [],
        "RouteTableId": "rtb-0f77f71e87d1fbbb2",
        "Routes": [
            {
                "DestinationCidrBlock": "10.0.0.0/16",
                "GatewayId": "local",
                "Origin": "CreateRouteTable",
                "State": "active"
            }
        ],
        "Tags": [
            {
                "Key": "Name",
                "Value": "PublicRT"
            }
        ],
        "VpcId": "vpc-0582a156c922d9305",
        "OwnerId": "417355468534"
    },
    "ClientToken": "49936469-2182-415c-b336-82c90758b3f8"
}
```

to get the RouteTableId and return it as text to the variable.

### Final Thoughts:
This was incredibly tedious.  This is the exact reason Terraform was created.
However, this is certainly better then using the console or executing one line at a time.

Its tedious to
+ Constantly check in the UI what resources have been created and what has been deleted
+ To develop without reliable code complete (Terraform has that).
+ Write your own tear down script (Terraform has a command for that).

But this was a good exercise.  Will never do this on the job though.  
