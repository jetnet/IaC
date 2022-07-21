###############################################################################
# Function app VM variables

variable "app_sp_fa_os_type" {
  type        = string
  default     = "Linux"
  description = "OS type for the service plan of the function app: metadata enrichment"
}

variable "app_sp_fa_sku" {
  type        = string
  default     = "S1"
  description = "SKU for the service plan of the function app: metadata enrichment"
}

variable "func_app_md_app_sett_conn_str_name" {
  type        = string
  default     = "CONNECTION_STRING"
  description = "A parameter name of the function app 'metadata enrichment' for the storage account"
}

variable "func_app_md_runtime_type" {
  type        = string
  default     = "python"
  description = "Runtime environment for the func-app 'metadata enrichment'"
}

variable "func_app_md_runtime_version" {
  type        = string
  default     = "3.9"
  description = "Runtime environment version for the func-app 'metadata enrichment'"
}

variable "func_app_md_image_name" {
  type        = string
  default     = "clnt/azurefunction"
  description = "Docker image path for the func-app 'metadata enrichment'"
}

variable "func_app_md_image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag for the func-app 'metadata enrichment'"
}

# client specific
variable "func_app_md_os_code" {
  type        = string
  default     = "US"
  description = "VM OS code for the metadata enrichment func app (WS - Windows Server, US - Unix Server)"
}
