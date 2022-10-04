variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = list(any)
  default     = ["10.76.192.0/20", "10.70.192.0/20"]

}

variable "name" {
  description = "name"
  type        = string
  default     = ""

}



variable "cidr-subnets" {
  description = "The CIDR block for the VPC"
  type        = list(any)
  default     = ["10.76.193.0/24", "10.76.194.0/24", "10.76.195.0/24", "10.76.196.0/24", "10.70.193.0/24", "10.70.194.0/24", "10.70.195.0/24", "10.70.196.0/24"]

}


