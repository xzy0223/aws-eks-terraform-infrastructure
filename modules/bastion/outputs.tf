output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_subnet_id" {
  description = "ID of the bastion subnet"
  value       = aws_subnet.bastion.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "bastion_iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion.arn
}

output "ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.bastion.public_ip}"
}
