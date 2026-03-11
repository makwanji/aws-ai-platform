output "bastion_security_group_id" {
  description = "Security group ID for bastion instances"
  value       = aws_security_group.bastion.id
}

output "private_security_group_id" {
  description = "Security group ID for private instances"
  value       = aws_security_group.private.id
}
