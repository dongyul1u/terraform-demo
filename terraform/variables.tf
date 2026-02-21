variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_cidr" {
  type        = string
  description = "Allowed CIDR for SSH (use your IP/32)."
  default     = "0.0.0.0/0"
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair name for SSH. Leave empty to create instance without SSH access."
  default     = "terraform-demo-key"
}
