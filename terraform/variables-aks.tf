###############################################################################
# AKS variables

###
# System pool requirements: https://docs.microsoft.com/en-us/azure/aks/use-system-pools?tabs=azure-cli#system-and-user-node-pools
variable "aks_pool_system_count" {
  type        = number
  default     = 2
  description = "Number of nodes in the Kubernetes system pool"
}
variable "aks_pool_system_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "VM size in the Kubernetes system pool"
}

###
# User pool: type - master
variable "aks_pool_user_small_name" {
  type        = string
  default     = "master"
  description = "Name of the Kubernetes user pool - small machines"
}
variable "aks_pool_user_small_count" {
  type        = number
  default     = 1
  description = "Number of nodes in the Kubernetes user pool - small machines"
}
variable "aks_pool_user_small_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "VM size in the Kubernetes system user pool - small machines"
}
# User pool: type - data
variable "aks_pool_user_big_name" {
  type        = string
  default     = "data"
  description = "Name of the Kubernetes user pool - big machines"
}
variable "aks_pool_user_big_count" {
  type        = number
  default     = 1
  description = "Number of nodes in the Kubernetes user pool - big machines"
}
variable "aks_pool_user_big_vm_size" {
  type        = string
  default     = "Standard_DS4_v2"
  description = "VM size in the Kubernetes user user pool - big machines"
}

