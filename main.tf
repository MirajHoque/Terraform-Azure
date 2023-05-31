terraform {
  //used to set provider source & version being used 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.58.0"
    }
  }
}

//Add cloud provider 
provider "azurerm" {
  subscription_id = ""
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""
  #required
  features {
    //optional
  }
}

//locals: local variable that will only be used current terraform configuration file
locals {
  resource_group_name = "mtc-resource"
  location            = "Canada Central"
}


#Resource Group
resource "azurerm_resource_group" "mtc_rg" {
  name     = local.resource_group_name
  location = local.location
}

#vnet

resource "azurerm_virtual_network" "app_vnet" {
  name                = "app-vnet"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  address_space       = ["10.0.0.0/16"]

  depends_on = [
    azurerm_resource_group.mtc_rg
  ]
}

#subnet
resource "azurerm_subnet" "subnetA" {
  name                 = "subnetA"
  resource_group_name  = azurerm_resource_group.mtc_rg.name
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.app_vnet
  ]
}

#Network interface
resource "azurerm_network_interface" "app_nic1" {
  name                = "app-nic1"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_virtual_network.app_vnet,
    azurerm_subnet.subnetA
  ]
}

resource "azurerm_network_interface" "app_nic2" {
  name                = "app-nic2"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_virtual_network.app_vnet,
    azurerm_subnet.subnetA
  ]
}

#windows vm
resource "azurerm_windows_virtual_machine" "app_vm1" {
  name                = "app-vm1"
  resource_group_name = azurerm_resource_group.mtc_rg.name
  location            = azurerm_resource_group.mtc_rg.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  availability_set_id = azurerm_availability_set.app_aset.id

  network_interface_ids = [
    azurerm_network_interface.app_nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_nic1,
    azurerm_availability_set.app_aset
  ]
}

resource "azurerm_windows_virtual_machine" "app_vm2" {
  name                = "app-vm2"
  resource_group_name = azurerm_resource_group.mtc_rg.name
  location            = azurerm_resource_group.mtc_rg.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  availability_set_id = azurerm_availability_set.app_aset.id

  network_interface_ids = [
    azurerm_network_interface.app_nic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_nic2,
    azurerm_availability_set.app_aset
  ]
}

#availability set
resource "azurerm_availability_set" "app_aset" {
  name                         = "app-aset"
  location                     = azurerm_resource_group.mtc_rg.location
  resource_group_name          = azurerm_resource_group.mtc_rg.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3

  depends_on = [
    azurerm_resource_group.mtc_rg
  ]

  tags = {
    environment = "Production"
  }
}

#storage account
resource "azurerm_storage_account" "mt_storageac" {
  name                          = "mtstoraccount"
  resource_group_name           = azurerm_resource_group.mtc_rg.name
  location                      = azurerm_resource_group.mtc_rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true

  tags = {
    environment = "staging"
  }

  depends_on = [
    azurerm_resource_group.mtc_rg
  ]
}

#storage container
resource "azurerm_storage_container" "mt_container" {
  name                  = "mtc"
  storage_account_name  = azurerm_storage_account.mt_storageac.name
  container_access_type = "blob"

  depends_on = [
    azurerm_storage_account.mt_storageac
  ]
}

#add data to the container
resource "azurerm_storage_blob" "IIS_config" {
  name                   = "IIS_config.ps1"
  storage_account_name   = azurerm_storage_account.mt_storageac.name
  storage_container_name = azurerm_storage_container.mt_container.name
  type                   = "Block"
  source                 = "C:/Users/USER/OneDrive/Documents/IIS_config.ps1"

  depends_on = [
    azurerm_storage_container.mt_container
  ]
}

#vm extension
resource "azurerm_virtual_machine_extension" "vm_extension1" {
  name                 = "vm-extension1"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  depends_on = [
    azurerm_storage_blob.IIS_config
  ]

  settings = <<SETTINGS
 {
  "fileUris": ["https://${azurerm_storage_account.mt_storageac.name}.blob.core.windows.net/mtc/IIS_config.ps1"],
  "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_config.ps1"   
 }
SETTINGS


  tags = {
    environment = "Production"
  }
}

resource "azurerm_virtual_machine_extension" "vm_extension2" {
  name                 = "vm-extension2"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  depends_on = [
    azurerm_storage_blob.IIS_config
  ]

  settings = <<SETTINGS
 {
  "fileUris": ["https://${azurerm_storage_account.mt_storageac.name}.blob.core.windows.net/mtc/IIS_config.ps1"],
  "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_config.ps1"   
 }
SETTINGS


  tags = {
    environment = "Production"
  }
}

#nsg
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

#nsg association
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id

  depends_on = [
    azurerm_network_security_group.app_nsg
  ]
}

#public ip address
resource "azurerm_public_ip" "lb_pip" {
  name                = "lb-pip"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#load balancer
resource "azurerm_lb" "app_lb" {
  name                = "app_lb"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }

  depends_on = [
    azurerm_public_ip.lb_pip
  ]
}

#backend poll
resource "azurerm_lb_backend_address_pool" "demo_bp" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "demo-bp"

  depends_on = [
    azurerm_lb.app_lb
  ]
}

#load balancer backend address poll address
resource "azurerm_lb_backend_address_pool_address" "vm1_address" {
  name                    = "vm1-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.demo_bp.id
  virtual_network_id      = azurerm_virtual_network.app_vnet.id
  ip_address              = azurerm_network_interface.app_nic1.private_ip_address

  depends_on = [
    azurerm_lb_backend_address_pool.demo_bp
  ]
}

resource "azurerm_lb_backend_address_pool_address" "vm2_address" {
  name                    = "vm2-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.demo_bp.id
  virtual_network_id      = azurerm_virtual_network.app_vnet.id
  ip_address              = azurerm_network_interface.app_nic2.private_ip_address

  depends_on = [
    azurerm_lb_backend_address_pool.demo_bp
  ]
}

#Health probe
resource "azurerm_lb_probe" "test_hp" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "test_hp"
  port            = 80

  depends_on = [
    azurerm_lb.app_lb
  ]
}

#load balancing rule
resource "azurerm_lb_rule" "test_lb_rule" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "test-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.demo_bp.id]
  probe_id                       = azurerm_lb_probe.test_hp.id

  depends_on = [
    azurerm_lb.app_lb,
    azurerm_lb_probe.test_hp
  ]
}