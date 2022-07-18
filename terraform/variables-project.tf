###############################################################################
# Project settings

variable "env" {
  type        = string
  default     = "dev"
  description = "Environment name, used in the global names for some resources"
}

variable "client_lable" {
  type        = string
  default     = "cln"
  description = "Client name, used in some resource names to make them unique in Azure cloud infrastructure"
}

variable "global_index" {
  type        = string
  default     = "001"
  description = "An index used as a suffix in some resource names to make them unique in Azure cloud infrastructure"
}

variable "project_name" {
  type        = string
  default     = "market"
  description = "Project name, used in some resource names to make them unique in Azure cloud infrastructure"
}

variable "project_name_short" {
  type        = string
  default     = "mkt"
  description = "A short project name, used in some resource names to make them unique in Azure cloud infrastructure. Some resources have limitation on the length of their names."
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure Location of resources"
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group name - should be specified as a command line parameter, since not compliant with the naming policy"
}

variable "region_code" {
  type        = string
  default     = "a2"
  description = "Client specific region codes (a1 - APAC, a2 - Europe, a3 - LATAM, a4 - NA)"
}

variable "aad_group_admins" {
  type        = string
  description = "Azure AD security group for administrators"
}

variable "aad_group_developers" {
  type        = string
  description = "Azure AD security group for developers"
}

variable "admin_user" {
  type        = string
  default     = "adm"
  description = "Admin user name for SSH connection"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.22.6"
  description = "Kubernetes version"
}
