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
Created vpc with vpc id: vpc-0a9572e5a79623e94
Enabling DNS hostnames for VPC: vpc-0a9572e5a79623e94
DNS hostnames enabled for VPC: vpc-0a9572e5a79623e94
Creating public subnet...
Public Subnet created: subnet-00365c44cdd14310e
Creating private subnet...
Private Subnet created: subnet-0c964548a2d6a32ae
creating internet gateway
Internet Gateway created: igw-083907608657e3c85
attaching internet gateway igw-083907608657e3c85 to vpc vpc-0a9572e5a79623e94
internet gateway igw-083907608657e3c85 attached to vpc vpc-0a9572e5a79623e94
creating public route table
Public Route Table created: rtb-019a70fb88ef05a1f
creating private route table
Private Route Table created: rtb-05636d9ef9a3421f6
Creating route to internet gateway in public route table...
Route to Internet Gateway created in public route table: rtb-019a70fb88ef05a1f
Associating public subnet with public route table
Public subnet subnet-00365c44cdd14310e associated with Public Route Table rtb-019a70fb88ef05a1f: rtbassoc-0831e2ac59fa9ac3e
allocating elastic ip for NAT gateway...
Elastic ip allocated with Allocation Id: eipalloc-016b30ff2bb1371fa
Creating NAT Gateway in public subnet...
Waiting for NAT Gateway to become available...
NAT Gateway created: nat-024fa905f8b8080c9
Tagging NAT Gateway...
NAT Gateway tagged: nat-024fa905f8b8080c9
Adding route to private route table to use NAT Gateway...
Route added to Private Route Table: rtb-05636d9ef9a3421f6 for NAT Gateway: nat-024fa905f8b8080c9
Associating private subnet with private route table...
Private subnet subnet-0c964548a2d6a32ae associated with Private Route Table rtb-05636d9ef9a3421f6: rtbassoc-04037bf3b1e1baf4b
Public Security Group created: sg-002b3547855575fa4
Adding SSH inbound rule to Public Security Group...
SSH inbound rule added to Public Security Group: sg-002b3547855575fa4
Adding HTTP inbound rule to Public Security Group...
HTTP inbound rule added to Public Security Group: sg-002b3547855575fa4
Launching EC2 instance in public subnet...
Public EC2 instance launched: i-0d2d00f263aeb437c
Creating Security Group for private instances...
Private Security Group created: sg-05c194b90a6a1b266
Adding SSH inbound rule to Private Security Group...
SSH inbound rule added to Private Security Group: sg-05c194b90a6a1b266
Adding ICMP inbound rule to Private Security Group...
ICMP inbound rule added to Private Security Group: sg-05c194b90a6a1b266
Launching EC2 instance in private subnet...
Private EC2 instance launched: i-05a51c6b350c191d2
```

### Tear down printout:
```bash
❯ ./tear-down.sh
Starting teardown process...
Found VPC: vpc-0a9572e5a79623e94
Found Public Subnet: subnet-00365c44cdd14310e
Found Private Subnet: subnet-0c964548a2d6a32ae
Found Internet Gateway: igw-083907608657e3c85
Found Public Route Table: rtb-019a70fb88ef05a1f
Found Private Route Table: rtb-05636d9ef9a3421f6
Found Public Security Group: sg-002b3547855575fa4
Found Private Security Group: sg-05c194b90a6a1b266
Found NAT Gateway: nat-024fa905f8b8080c9
Found Elastic IP Allocation ID: None
Terminating EC2 instances...
Terminating EC2 instances: i-0d2d00f263aeb437c  i-05a51c6b350c191d2
Waiting for instances to terminate...
EC2 instances terminated: i-0d2d00f263aeb437c   i-05a51c6b350c191d2
Deleting security groups...
Deleting Public Security Group: sg-002b3547855575fa4
Public Security Group deleted: sg-002b3547855575fa4
Deleting Private Security Group: sg-05c194b90a6a1b266
Private Security Group deleted: sg-05c194b90a6a1b266
Deleting NAT Gateway: nat-024fa905f8b8080c9
Waiting for NAT Gateway to be deleted...
NAT Gateway deleted: nat-024fa905f8b8080c9
Releasing Elastic IP: None
Elastic IP released: None
Deleting route table associations and route tables...
Disassociating public route table: rtbassoc-0831e2ac59fa9ac3e
Public route table disassociated 
Disassociating Private Route Table: rtbassoc-04037bf3b1e1baf4b
Private Route Table disassociated: rtbassoc-04037bf3b1e1baf4b
Deleting public route table rtb-019a70fb88ef05a1f
Deleted public route table rtb-019a70fb88ef05a1f
Deleting Private Route Table: rtb-05636d9ef9a3421f6
Deleted Private Route Table: rtb-05636d9ef9a3421f6
Detaching Internet Gateway: igw-083907608657e3c85
Deleting Internet Gateway: igw-083907608657e3c85
Internet Gateway deleted: igw-083907608657e3c85
Deleting subnets...
Deleting Private Subnet: subnet-0c964548a2d6a32ae
Private Subnet deleted: subnet-0c964548a2d6a32ae
Deleting Public Subnet: subnet-00365c44cdd14310e
Public Subnet deleted: subnet-00365c44cdd14310e
Getting vpc id for gl-vpc
Deleting vpc: gl-vpc with id: vpc-0a9572e5a79623e94
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

### Proof of NatGateway Success

```bash
❯ scp -i liftshift.pem ./liftshift.pem ec2-user@ec2-3-93-168-247.compute-1.amazonaws.com:/home/ec2-user/liftshift.pem
❯ ssh -i "liftshift.pem" ec2-user@ec2-54-162-148-78.compute-1.amazonaws.com
The authenticity of host 'ec2-54-162-148-78.compute-1.amazonaws.com (54.162.148.78)' can't be established.
ED25519 key fingerprint is SHA256:XkA0OZjj81qu6Muky+U/3cV/cTlni6ueHmRXLyWW1zM.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ec2-54-162-148-78.compute-1.amazonaws.com' (ED25519) to the list of known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2
  ~~  \_#####\
  ~~     \###|       AL2 End of Life is 2025-06-30.
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /    A newer version of Amazon Linux is available!
      ~~._.   _/
         _/ _/       Amazon Linux 2023, GA and supported until 2028-03-15.
       _/m/'           https://aws.amazon.com/linux/amazon-linux-2023/

[ec2-user@ip-10-0-1-229 ~]$ exit
logout
Connection to ec2-54-162-148-78.compute-1.amazonaws.com closed.
❯ scp -i liftshift.pem ./liftshift.pem ec2-54-162-148-78.compute-1.amazonaws.com:/home/ec2-user/liftshift.pem
walterharms@ec2-54-162-148-78.compute-1.amazonaws.com: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
scp: Connection closed
❯ ssh -i "liftshift.pem" ec2-user@ec2-54-162-148-78.compute-1.amazonaws.com
Last login: Sat Nov  9 22:41:29 2024 from 69.226.237.216
   ,     #_
   ~\_  ####_        Amazon Linux 2
  ~~  \_#####\
  ~~     \###|       AL2 End of Life is 2025-06-30.
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /    A newer version of Amazon Linux is available!
      ~~._.   _/
         _/ _/       Amazon Linux 2023, GA and supported until 2028-03-15.
       _/m/'           https://aws.amazon.com/linux/amazon-linux-2023/

[ec2-user@ip-10-0-1-229 ~]$ exit
logout
Connection to ec2-54-162-148-78.compute-1.amazonaws.com closed.
❯ scp -i liftshift.pem ./liftshift.pem ec2-user@ec2-54-162-148-78.compute-1.amazonaws.com:/home/ec2-user/liftshift.pem
liftshift.pem                                                                                                                               100% 1678    70.7KB/s   00:00
❯ ssh -i "liftshift.pem" ec2-user@ec2-54-162-148-78.compute-1.amazonaws.com
Last login: Sat Nov  9 22:42:22 2024 from 69.226.237.216
   ,     #_
   ~\_  ####_        Amazon Linux 2
  ~~  \_#####\
  ~~     \###|       AL2 End of Life is 2025-06-30.
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /    A newer version of Amazon Linux is available!
      ~~._.   _/
         _/ _/       Amazon Linux 2023, GA and supported until 2028-03-15.
       _/m/'           https://aws.amazon.com/linux/amazon-linux-2023/

[ec2-user@ip-10-0-1-229 ~]$ ssh -i "liftshift.pem" ec2-user@ec2-18-234-157-136.compute-1.amazonaws.com
The authenticity of host 'ec2-18-234-157-136.compute-1.amazonaws.com (10.0.2.171)' can't be established.
ECDSA key fingerprint is SHA256:C+jOsJayV2x5G8dqWyKfpoS37YWa/f/aX6plvAO+flE.
ECDSA key fingerprint is MD5:74:3c:eb:27:de:bb:89:ce:58:9c:a2:f7:90:06:25:71.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'ec2-18-234-157-136.compute-1.amazonaws.com,10.0.2.171' (ECDSA) to the list of known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2
  ~~  \_#####\
  ~~     \###|       AL2 End of Life is 2025-06-30.
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /    A newer version of Amazon Linux is available!
      ~~._.   _/
         _/ _/       Amazon Linux 2023, GA and supported until 2028-03-15.
       _/m/'           https://aws.amazon.com/linux/amazon-linux-2023/

[ec2-user@ip-10-0-2-171 ~]$ curl http://example.com
<!doctype html>
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style type="text/css">
    body {
        background-color: #f0f0f2;
        margin: 0;
        padding: 0;
        font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;

    }
    div {
        width: 600px;
        margin: 5em auto;
        padding: 2em;
        background-color: #fdfdff;
        border-radius: 0.5em;
        box-shadow: 2px 3px 7px 2px rgba(0,0,0,0.02);
    }
    a:link, a:visited {
        color: #38488f;
        text-decoration: none;
    }
    @media (max-width: 700px) {
        div {
            margin: 0 auto;
            width: auto;
        }
    }
    </style>
</head>

<body>
<div>
    <h1>Example Domain</h1>
    <p>This domain is for use in illustrative examples in documents. You may use this
    domain in literature without prior coordination or asking for permission.</p>
    <p><a href="https://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>
[ec2-user@ip-10-0-2-171 ~]$ sudo yum update
Loaded plugins: extras_suggestions, langpacks, priorities, update-motd
amzn2-core                                                                                                                                             | 3.6 kB  00:00:00
No packages marked for update
[ec2-user@ip-10-0-2-171 ~]$ exit
logout
Connection to ec2-18-234-157-136.compute-1.amazonaws.com closed.
[ec2-user@ip-10-0-1-229 ~]$ exit
logout
Connection to ec2-54-162-148-78.compute-1.amazonaws.com closed.
```

### Security groups
Rather than allow wide open ssh, set to 0.0.0.0/0.  I did configure that to my personal ip.

I created a config.env file which was gitignored and not checked into my repo.

```bash
MY_IP="<Personal Ip Address>"
```
This file is sourced like the variables from the variables.sh and MY_IP is available in the 
set_up script.

### Final Thoughts:
This was incredibly tedious.  This is the exact reason Terraform was created.
However, this is certainly better then using the console or executing one line at a time.

Its tedious to
+ Constantly check in the UI what resources have been created and what has been deleted
+ To develop without reliable code complete (Terraform has that).
+ Write your own tear down script (Terraform has a command for that).

But this was a good exercise.  Will never do this on the job though.  
