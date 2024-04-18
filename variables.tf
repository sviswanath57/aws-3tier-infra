variable "environment" {
    type = string
  default = "3tier"
}

# variable "vpc_cidr" {
#     type = string
# }

# variable "enable_dns_hostnames" {
#   type = bool
#   default = true
# }

# variable "subnet_tags" {
#   type = map
#   default = {}
# }

# # variable "availability_zone" {
# # type = string
# # default = "us-east-1a"
# # }

# variable "vpc_tags" {
#     type = map
#   default = {}
# }

# variable "project_name" {
#   type = string
# }

# variable "environment_name" {
#   type = string
# }

# variable "igw_tags" {
#   type = map
#   default = {}
# }

# variable "pri_subnet_cidr" {
#     type = list
#     validation {
#       condition = length(var.pri_subnet_cidr) == 2
#       error_message = "Pleae give 2 private subnets CIDR"
#     }
# }

# variable "pub_subnet_cidr" {
#     type = list
#     validation {
#       condition = length(var.pub_subnet_cidr) == 2
#       error_message = "Pleae give 2 public subnets CIDR"
#     }
# }

# variable "db_subnet_cidr" {
#   type = list
#   default = []
# }
variable "destination_cidr_block" {
  type = string
  default = "0.0.0.0/0"
}

# variable "aws_availability_zones" {
#   type = list
#   default = []
# }

# # variable "owner_vpc_id" {
# #   description = "Owner VPC Id"
# # }

# variable "accepter_vpc_id" {
#   description = "Accepter VPC Id"
#   default = ""
# }

# variable "is_peering_required" {
#   type = bool
#   default = false
# }