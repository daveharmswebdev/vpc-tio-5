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

### Final Thoughts:
This was incredibly tedious.  This is the exact reason Terraform was created.
However, this is certainly better then using the console or executing one line at a time.

Its tedious to
+ Constantly check in the UI what resources have been created and what has been deleted
+ To develop without reliable code complete (Terraform has that).
+ Write your own tear down script (Terraform has a command for that).

But this was a good exercise.  Will never do this on the job though.  
