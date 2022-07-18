###############################################################################
# Admin VM: administrative tasks for the private AKS cluster, access via Bastion

locals {
  admin_vm_name = "${var.region_code}${var.admin_vm_os_code}0001"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${local.admin_vm_name}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.vnet_subnets[local.aks_subnet_id]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "admin" {
  name                  = local.admin_vm_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  size                  = var.admin_vm_size
  admin_username        = var.admin_user
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  admin_ssh_key {
    username   = var.admin_user
    public_key = tls_private_key.admin_ssh_key.public_key_openssh
  }

  os_disk {
    name                 = "${local.admin_vm_name}data01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.admin_vm_image_publisher
    offer     = var.admin_vm_image_offer
    sku       = var.admin_vm_image_sku
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "admin" {
  virtual_machine_id    = azurerm_linux_virtual_machine.admin.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = "2300"
  timezone              = "Central Europe Standard Time"
  notification_settings {
    enabled = false
  }
}

resource "azurerm_virtual_machine_extension" "admin_post_install" {
  name = "${local.admin_vm_name}-post-install"

  virtual_machine_id   = azurerm_linux_virtual_machine.admin.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<EOF
    {
        "script": "${base64encode(file(var.cent_os_post_install))}"
    }
    EOF
}