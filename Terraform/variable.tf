variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}


variable "region" {
  description = "CIDR block for the region"
  type        = string
}

variable "public_subnet_az1_cidr" {
  description = "CIDR block for the public subnet in AZ1"
  type        = string
}

variable "private_subnet_az1_cidr" {
  description = "CIDR block for the private subnet in AZ1"
  type        = string
}

variable "ami_id" {
    description = "value for ami"
    type        = string
  }

 variable "instance_type" {
    description = "instance type for EC2"
    type        = string
  }
 variable "allowed_cidr" {
    description = "allowed cidr block"
    type        = list(string)
  }

  variable "key_pair" {
    description = "key pair name"
    type        = string
  }
