terraform {
  //used to set provider source & version being used 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.57.0"
    }
  }
}

//Add cloud provider 
provider "azurerm" {
  subscription_id = "d8026e85-c3a9-4a33-acb5-88d88c4daf6c"
  client_id       = "a34d4f82-4be8-4e70-8ecf-2ec7650f1f16"
  client_secret   = "K_G8Q~5CuEX7CHBJ57xaxvGmQJzqdvqWWqo~vb_w"
  tenant_id       = "cec0703b-aa1e-474f-a0b6-774a05568b47"
  #required
  features {
    //optional
  }
}

#locals: local variable that will only be used current terraform configuration file
locals {
  resource_group_name = "mtc-resource"
  location            = "Canada Central"
}

#install nginx via cloud init config
data "template_cloudinit_config" "vm_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "packages: ['nginx']"
  }

}

#Resource Group
resource "azurerm_resource_group" "mtc_rg" {
  name     = local.resource_group_name
  location = local.location
}

#vnet
resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  depends_on = [
    azurerm_resource_group.mtc_rg
  ]

  tags = {
    environment = "Production"
  }
}

#subnet
resource "azurerm_subnet" "subnetA" {
  name                 = "subnet-A"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

#Network interface
resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  location            = local.location
  resource_group_name = azurerm_resource_group.mtc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic" //comes from the subnet within vnet
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_public_ip,
  ]
}

#virtual machine - Linux
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                            = "app-vm"
  resource_group_name             = azurerm_resource_group.mtc_rg.name
  location                        = azurerm_resource_group.mtc_rg.location
  size                            = "Standard_DS1_v2"
  admin_username                  = "adminuser"
  admin_password                  = "azure@123"
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.vm_config.rendered
  network_interface_ids = [
    azurerm_network_interface.app_nic.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_nic
  ]
}

#public ip address
resource "azurerm_public_ip" "app_public_ip" {
  name                    = "app-public-ip"
  location                = azurerm_resource_group.mtc_rg.location
  resource_group_name     = azurerm_resource_group.mtc_rg.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  depends_on = [
    azurerm_resource_group.mtc_rg
  ]

  tags = {
    environment = "test"
  }
}
