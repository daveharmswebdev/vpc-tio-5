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

```bashsupport pro zsh
❯ ./set-up.sh
Creating VPC...
Created vpc with vpc id: vpc-084f2ea31d3bd3d7c
Enabling DNS hostnames for VPC: vpc-084f2ea31d3bd3d7c
DNS hostnames enabled for VPC: vpc-084f2ea31d3bd3d7c
Creating public subnet...
Public Subnet created: subnet-0f270e3a6f9399be9
Creating private subnet...
Private Subnet created: subnet-01efaa8d6863d95ad
creating internet gateway
Internet Gateway created: igw-0f09271a8546c8ae8
attaching internet gateway igw-0f09271a8546c8ae8 to vpc vpc-084f2ea31d3bd3d7c
internet gateway igw-0f09271a8546c8ae8 attached to vpc vpc-084f2ea31d3bd3d7c
creating public route table
Public Route Table created: {
    "RouteTable": {
        "Associations": [],
        "PropagatingVgws": [],
        "RouteTableId": "rtb-05e582794ce99d97d",
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
        "VpcId": "vpc-084f2ea31d3bd3d7c",
        "OwnerId": "417355468534"
    },
    "ClientToken": "278424e7-a26b-4484-819a-7a57e0bd031a"
}

```

### Tear down printout:
```bashsupport pro zsh
❯ ./tear-down.sh
Starting teardown process...
Found VPC: vpc-084f2ea31d3bd3d7c
Found Public Subnet: subnet-0f270e3a6f9399be9
Found Private Subnet: subnet-01efaa8d6863d95ad
Found Internet Gateway: igw-0f09271a8546c8ae8
Found Public Route Table: rtb-05e582794ce99d97d
Deleting public route table rtb-05e582794ce99d97d
Deleted public route table rtb-05e582794ce99d97d
Detaching Internet Gateway: igw-0f09271a8546c8ae8
Deleting Internet Gateway: igw-0f09271a8546c8ae8
Internet Gateway deleted: igw-0f09271a8546c8ae8
Deleting subnets...
Deleting Private Subnet: subnet-01efaa8d6863d95ad
Private Subnet deleted: subnet-01efaa8d6863d95ad
Deleting Public Subnet: subnet-0f270e3a6f9399be9
Public Subnet deleted: subnet-0f270e3a6f9399be9
Getting vpc id for gl-vpc
Deleting vpc: gl-vpc with id: vpc-084f2ea31d3bd3d7c
Vpc deleted

```


### Final Thoughts:
This was incredibly tedious.  This is the exact reason Terraform was created.
However, this is certainly better then using the console or executing one line at a time.

Its tedious to
+ Constantly check in the UI what resources have been created and what has been deleted
+ To develop without reliable code complete (Terraform has that).
+ Write your own tear down script (Terraform has a command for that).

But this was a good exercise.  Will never do this on the job though.  
