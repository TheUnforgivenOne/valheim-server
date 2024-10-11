variable "region" {
  type        = string
  description = "AWS region"
}

variable "profile" {
  type        = string
  description = "AWS CLI account"
}

variable "server_ami" {
  type        = string
  description = "AMI of EC2 server instance"
}

variable "server_ec2_type" {
  type        = string
  description = "EC2 instance type for the server"
  default     = "t2.micro"
}

variable "ec2_user" {
  type        = string
  description = "EC2 user to log in"
}

variable "bootstrap_script" {
  type        = string
  description = "Bootstrap .sh script name to execute on EC2 create"
}