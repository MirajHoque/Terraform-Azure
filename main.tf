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

#Resource Group
resource "azurerm_resource_group" "mtc_rg" {
  name     = local.resource_group_name
  location = local.location
}

#app service plan
resource "azurerm_app_service_plan" "app_plan" {
  name                = "app-serviceplan"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name

  sku {
    tier = "Free"
    size = "F1"
  }
}

#azure web app

resource "azurerm_app_service" "test_web" {
  name                = "test-webapp32444"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  app_service_plan_id = azurerm_app_service_plan.app_plan.id

}

