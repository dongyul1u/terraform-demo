output "instance_public_ip" {
  value = aws_instance.ml_demo.public_ip
}

output "ssh_hint" {
  value = "ssh -i terraform-demo-key.pem ec2-user@${aws_instance.ml_demo.public_ip}"
}
