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
  default     = "marketplace"
  description = "Project name, used in some resource names to make them unique in Azure cloud infrastructure"
}

variable "project_name_short" {
  type        = string
  default     = "dmp"
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
  default     = "dmpadm"
  description = "Admin user name for SSH connection"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.22.6"
  description = "Kubernetes version"
}

variable "ui_ip_address" {
  type        = string
  default     = "10.0.225.23"
  description = "UI application private external IP address in Kubernetes cluster"
}

variable "ui_port" {
  type        = string
  default     = "4200"
  description = "UI application listen port in Kubernetes cluster"
}

variable "ui_protocol" {
  type        = string
  default     = "Http"
  description = "UI application protocol in Kubernetes cluster"
}

variable "os_db_ip_address" {
  type        = string
  default     = "10.0.225.23"
  description = "UI application private external IP address in Kubernetes cluster"
}

variable "os_db_port" {
  type        = string
  default     = "4200"
  description = "OpenSearch Dashboard listen port in Kubernetes cluster"
}

variable "os_db_protocol" {
  type        = string
  default     = "Http"
  description = "OpenSearch Dashboard protocol in Kubernetes cluster"
}
