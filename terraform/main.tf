terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- Default VPC & Subnet (simplest for demo) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Pick the first default subnet
locals {
  subnet_id = data.aws_subnets.default_in_vpc.ids[0]
}

# --- Latest Amazon Linux 2023 AMI ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# --- Security group: allow SSH (optional) + allow outbound for pip installs ---
resource "aws_security_group" "ml_demo_sg" {
  name        = "ml-demo-sg"
  description = "Security group for Terraform + user_data ML demo"
  vpc_id      = data.aws_vpc.default.id

  # SSH (optional)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  # outbound open
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 instance that runs user_data on first boot ---
resource "aws_instance" "ml_demo" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.ml_demo_sg.id]
  associate_public_ip_address = true

  key_name = var.key_name

  user_data = file("${path.module}/user_code.sh")

  tags = {
    Name = "ml-terraform-userdata-demo"
  }
}
