variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}

variable "root_block_device" {
  description = "Root block device configuration"
  type = list(object({
    volume_size = number
    volume_type = string
  }))
  default = [{
    volume_size = 20
    volume_type = "gp3"
  }]
}

variable "tags" {
  description = "Additional tags for the instance"
  type        = map(string)
  default     = {}
}