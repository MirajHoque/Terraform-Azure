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

//Resource Group
resource "azurerm_resource_group" "mtc-rg" {
  name     = "mtc-resources"
  location = "Canada Central"
}

//storage account 
resource "azurerm_storage_account" "demo-sta" {
  name                          = "demostorage32444"
  resource_group_name           = "mtc-resources"
  location                      = "Canada Central"
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true

  tags = {
    environment = "dev"
  }
}

//stroage container
resource "azurerm_storage_container" "test-container" {
  name                  = "mt32444"
  storage_account_name  = "demostorage32444"
  container_access_type = "blob"
}

//this is used to upload a local file on the container
resource "azurerm_storage_blob" "sample" {
  name                   = "bkashDevOps.txt"
  storage_account_name   = "demostorage32444"
  storage_container_name = "mt32444"
  type                   = "Block"
  source                 = "C:/Users/USER/OneDrive/Documents/bkashDevOps.txt"

  //Manage dependencies
  depends_on = [
    azurerm_storage_container.test-container
    //resourceType.ResourceName
  ]
}