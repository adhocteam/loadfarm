# loadfarm

This is a barebones Terraform configuration that you can use to spin up a cluster of EC2 instances and have them all run the same code.

This was borne out of a need to run multi-region load testing scripts, but could easily be reused to run any arbitrary code across AWS.

## Getting Started

This requires Terraform, an AWS account, and a working local AWS command line environment.

First, generate a SSH keypair to use to connect to instances.

```bash
ssh-keygen -t rsa -b 2048 -f files/default.pem
```

Next, create a workspace:

```bash
terraform init
terraform workspace new us-east-1
```

Note: The name should match the AWS availability zone you intend to use, i.e. `us-east-1`, `us-west-2`, etc.

Next, add the code you want to run on each instance to `files/instance_user_data`. Refer to the [AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) to see what's supported. In this (contrived) example, we fetch a URL 10 times then shutdown.

```bash
echo <<EOF
#!/bin/bash

for i in {1..10}
do
   curl -s http://www.example.com/
done

/sbin/shutdown -h now

EOF
```

Next, run Terraform to create your infrastructure:

```bash
terraform apply -var workers=10
```

To scale the number of workers up and down, re-run the command with higher or lower values for `workers`.

When you are done running your code, you may either redeploy with `-var workers=0` to kill the instances, but preserve the network infrastructure, or run `terraform destroy` to remove everything you created.

## Known Issues

This project is barebones by design, so don't expect a whole lot! That said, here's bits I know can be improved:

- EC2 instances could launch with instance profiles to grant/restrict access to other AWS services
- Task logging & reporting is left to the implementer
- There's no provision for remote state. The default implementation will store Terraform state in a local directory

## License

MIT

## Credits

First implementation by Chris Gansen (chris@adhoc.team).

Your name could be here! Open a PR!

