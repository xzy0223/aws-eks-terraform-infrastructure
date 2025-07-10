variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = "my-project"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones"
  type        = number
  default     = 3
  
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "AZ count must be between 2 and 6."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "public_subnet_newbits" {
  description = "Number of additional bits for public subnet CIDR (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
  
  validation {
    condition     = var.public_subnet_newbits >= 1 && var.public_subnet_newbits <= 16
    error_message = "Subnet newbits must be between 1 and 16."
  }
}

variable "private_subnet_newbits" {
  description = "Number of additional bits for private subnet CIDR (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
  
  validation {
    condition     = var.private_subnet_newbits >= 1 && var.private_subnet_newbits <= 16
    error_message = "Subnet newbits must be between 1 and 16."
  }
}

variable "custom_public_subnet_cidrs" {
  description = "Custom CIDR blocks for public subnets (optional, overrides automatic calculation)"
  type        = list(string)
  default     = []
}

variable "custom_private_subnet_cidrs" {
  description = "Custom CIDR blocks for private subnets (optional, overrides automatic calculation)"
  type        = list(string)
  default     = []
}
