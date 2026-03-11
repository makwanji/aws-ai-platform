output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the instance"
  value       = aws_instance.this.public_dns
}

output "instance_private_dns" {
  description = "The private DNS name of the instance"
  value       = aws_instance.this.private_dns
}

output "ami_id" {
  description = "The AMI ID used for the instance"
  value       = aws_instance.this.ami
}