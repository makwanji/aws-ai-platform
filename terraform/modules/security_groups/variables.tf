variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "tags" {
  description = "Tags to apply to security groups"
  type        = map(string)
  default     = {}
}
