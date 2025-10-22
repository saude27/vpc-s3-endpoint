output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_ec2_id" {
  value = aws_instance.private_ec2.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
