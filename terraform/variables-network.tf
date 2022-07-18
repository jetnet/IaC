###############################################################################
# VNet variables
variable "vnet_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VNet address range (CIDR)"
}

variable "vnet_dns_server_default" {
  type        = string
  default     = "168.63.129.16"
  description = "Azure default internal DNS server IP address"
}

variable "vnet_dns_server_custom" {
  type        = string
  default     = "10.0.255.1"
  description = "IP address of the Kubernetes internal DNS exposed to VNet"
}

variable "subnet_cidr_aks" {
  type        = string
  default     = "10.0.224.0/19"
  description = "Subnet CIDR for subnet: AKS"
}
variable "subnet_cidr_ag" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Subnet CIDR for subnet: Application Gateway"
}
variable "subnet_cidr_bastion" {
  type        = string
  default     = "10.0.2.0/24"
  description = "Subnet CIDR for subnet: Bastion"
}
variable "subnet_cidr_func_app" {
  type        = string
  default     = "10.0.3.0/24"
  description = "Subnet CIDR for subnet: Function App"
}

