terraform {
  //used to set provider source & version being used 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.55.0"
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

//variable
variable "storage_account_name" {
  type        = string
  description = "Please enter the storage account name"
}

//locals: local variable that will only be used current terraform configuration file
locals {
  resource_group_name = "mtc-resource"
  location            = "Canada Central"
}

//Resource Group
resource "azurerm_resource_group" "mtc-rg" {
  name     = local.resource_group_name
  location = local.location
}

//storage account 
resource "azurerm_storage_account" "demo-sta" {
  name                          = var.storage_account_name
  resource_group_name           = local.resource_group_name
  location                      = local.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true

  tags = {
    environment = "dev"
  }

  depends_on = [
    azurerm_resource_group.mtc-rg
  ]
}

//stroage container
resource "azurerm_storage_container" "test-container" {
  name                  = "mt32444"
  storage_account_name  = var.storage_account_name
  container_access_type = "blob"

  depends_on = [
    azurerm_storage_account.demo-sta
  ]
}

//this is used to upload a local file on the container
resource "azurerm_storage_blob" "sample" {
  name                   = "bkashDevOps.txt"
  storage_account_name   = var.storage_account_name
  storage_container_name = "mt32444"
  type                   = "Block"
  source                 = "C:/Users/USER/OneDrive/Documents/bkashDevOps.txt"

  //Manage dependencies
  depends_on = [
    azurerm_storage_container.test-container
    //resourceType.ResourceName
  ]
}