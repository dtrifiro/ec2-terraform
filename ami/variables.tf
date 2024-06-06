variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS Region"
}

variable "name" {
  type        = string
  default     = "dtrifiro-gpu-debian"
  description = "Name for the ami"
}

variable "instance_id" {
  type        = string
  description = "Instance id to create the ami from"
}
