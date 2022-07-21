terraform {
  required_version = ">=1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.11.0"
      # use_msi = true
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.24.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.0.1"
    }
  }

  backend "azurerm" {
    # resource_group_name  = "" # env specific, defined in tf-backend-ENV.conf
    # storage_account_name = "" # env specific, defined in tf-backend-ENV.conf
    container_name = "tfstate" # the container must be created manually
    key            = "terraform.tfstate"
  }
}

provider "azuread" {
  # tenant_id = "00000000-0000-0000-0000-000000000000"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  # The Azure Provider will automatically register all of the Resource Providers which it supports on launch
  skip_provider_registration = true
}

provider "random" {
}
