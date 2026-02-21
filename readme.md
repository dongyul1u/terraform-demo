# Terraform EC2 ML Demo

This project uses Terraform to create an AWS EC2 instance and run a `user_data` script on first boot.
The script installs Python packages and trains a small scikit-learn model automatically.

## What this deploys

- 1 EC2 instance (Amazon Linux 2023)
- 1 security group:
	- inbound SSH (port 22) from `ssh_cidr`
	- outbound open to internet (for package install)
- `user_data` execution from `terraform/user_code.sh`

## Prerequisites

- AWS account and IAM permissions for EC2/VPC/Security Group
- AWS CLI configured locally (`aws configure`)
- Terraform >= 1.4
- An EC2 Key Pair for SSH access

## Project structure

```text
terraform-demo/
	terraform/
		main.tf
		variables.tf
		outputs.tf
		user_code.sh
```

## Configure variables

Go to the Terraform folder:

```bash
cd terraform
```

Important variables (in `variables.tf`):

- `region` (default: `us-east-1`)
- `instance_type` (default: `t3.micro`)
- `ssh_cidr` (default: `0.0.0.0/0`, recommended to narrow to your public IP `/32`)
- `key_name` (change the default to your aws key pair name)

You can override values by creating `terraform.tfvars`:

```hcl
region        = "us-east-1"
instance_type = "t3.micro"
ssh_cidr      = "YOUR_PUBLIC_IP/32"
key_name      = "terraform-demo-key"
```

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

After apply succeeds, Terraform outputs:

- `instance_public_ip`
- `ssh_hint`

## Verify on EC2

SSH to the instance (if you configured key pair):

```bash
ssh -i terraform-demo-key.pem ec2-user@<instance_public_ip>
```

Check bootstrap logs:

```bash
sudo cat /var/log/ml-demo-user-data.log
cat /home/ec2-user/ml-demo-user-data.log
```

Expected demo artifacts:

- `/home/ec2-user/metrics.json`
- `/home/ec2-user/model.pkl`

## Destroy resources

```bash
terraform destroy
```

## Security notes

- Avoid committing secrets or private key files (`*.pem`) to Git.
- Restrict `ssh_cidr` instead of using `0.0.0.0/0` in non-demo environments.