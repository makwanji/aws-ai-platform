variable "vpc_id" {
  description = "VPC ID where NAT Gateway will be created"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet to host the NAT Gateway"
  type        = string
}

variable "private_route_table_ids" {
  description = "List of private route table IDs that should use the NAT Gateway"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}