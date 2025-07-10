variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion host will be deployed"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet"
  type        = string
  default     = "10.0.100.0/24"
}

variable "availability_zone" {
  description = "Availability zone for bastion subnet"
  type        = string
}

variable "public_route_table_id" {
  description = "Public route table ID for bastion subnet association"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "region" {
  description = "AWS region"
  type        = string
}
