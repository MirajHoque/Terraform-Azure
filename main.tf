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
    virtual_machine {
      delete_os_disk_on_deletion = true
      skip_shutdown_and_force_delete = true
    }
  }
}

#resource group
resource "azurerm_resource_group" "resourcegroup" {
    name     = "TFTestRG01"
  location = "CentralUS"
}

#data block
data "azurerm_subnet" "vmsubnet" {
  name                 = var.subname
  virtual_network_name = var.vnetname
  resource_group_name  = var.vnetrg
}

#calling the existing module
module "vm" {
  source     = "./WinServer"
  rgname     = azurerm_resource_group.resourcegroup.name
  location   = azurerm_resource_group.resourcegroup.location
  vmname     = "TFTestServer"
  size       = "Standard_B2ms"
  localadmin = "locadmin"
  adminpw    = var.adminpw
  subnetid   = data.azurerm_subnet.vmsubnet.id
}