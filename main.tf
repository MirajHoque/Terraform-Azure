terraform {
  //used to set provider source & version being used 
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "3.55.0"
    }
  }
}

//Add cloud provider 
provider "azurerm" {
  subscription_id = "d8026e85-c3a9-4a33-acb5-88d88c4daf6c"
  client_id = "a34d4f82-4be8-4e70-8ecf-2ec7650f1f16"
  client_secret = "K_G8Q~5CuEX7CHBJ57xaxvGmQJzqdvqWWqo~vb_w"
  tenant_id = "cec0703b-aa1e-474f-a0b6-774a05568b47"
  #required
  features {
    //optional
  }
}

//Resource Group
resource "azurerm_resource_group" "rg_app" {
  name     = "rg-app"
  location = "Canada Central"
}