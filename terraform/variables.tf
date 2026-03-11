variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_compute_subnets" {
  description = "List of private compute subnet CIDRs"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "private_control_subnets" {
  description = "List of private control subnet CIDRs"
  type        = list(string)
  default     = ["10.10.20.0/24", "10.10.21.0/24"]
}

variable "storage_subnets" {
  description = "List of storage subnet CIDRs"
  type        = list(string)
  default     = ["10.10.30.0/24", "10.10.31.0/24"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "ai-platform"
    Project     = "aws-ai-platform"
  }
}
