variable "admin_cidr" {
  default     = "0.0.0.0/0"
  description = "CIDR block to allow admin connectivity"
}

variable "workers" {
  default     = 1
  description = "number of instances to run in a region"
}

variable "instance_type" {
  default = "m5.2xlarge"
  description = "class of ec2 instance to launch"
}