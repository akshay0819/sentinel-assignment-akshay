variable "name" {
  type        = string
  description = "Name for VPC peering connection"
}

variable "vpc_id_requester" {
  type        = string
  description = "VPC ID of the requester (e.g., gateway VPC)"
}

variable "vpc_id_accepter" {
  type        = string
  description = "VPC ID of the accepter (e.g., backend VPC)"
}

variable "requester_vpc_cidr" {
  type        = string
  description = "CIDR block of requester VPC"
}

variable "accepter_vpc_cidr" {
  type        = string
  description = "CIDR block of accepter VPC"
}

variable "requester_private_subnet_route_table_ids" {
  type        = list(string)
  description = "Route table IDs for requester private subnets"
}

variable "accepter_private_subnet_route_table_ids" {
  type        = list(string)
  description = "Route table IDs for accepter private subnets"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
}
