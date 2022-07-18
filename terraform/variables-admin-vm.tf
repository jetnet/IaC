###############################################################################
# Admin VM variables

variable "admin_vm_size" {
  type        = string
  default     = "Standard_B1ls"
  description = "VM size of the VM for administrative tasks"
}

# Azure OS image details
variable "admin_vm_image_publisher" {
  type        = string
  default     = "OpenLogic"
  description = "Admin VM OS image publisher"
}
variable "admin_vm_image_offer" {
  type        = string
  default     = "CentOS"
  description = "Admin VM OS image offer"
}
variable "admin_vm_image_sku" {
  type        = string
  default     = "7.7"
  description = "CentOS 7 SKU"
}
variable "cent_os_post_install" {
  type        = string
  default     = "scripts/CentOS-post-install.sh"
  description = "CentOS 7 post-install script"
}

# client specific
variable "admin_vm_os_code" {
  type        = string
  default     = "US"
  description = "VM OS code (WS - Windows Server, US - Unix Server)"
}
