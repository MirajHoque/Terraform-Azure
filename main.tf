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

#sql server

resource "azurerm_sql_server" "mt_server" {
  name                         = "mt-sqlserver"
  resource_group_name          = azurerm_resource_group.mtc_rg.name
  location                     = azurerm_resource_group.mtc_rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "azure@123"
  tags = {
    environment = "production"
  }
}

#sql database
resource "azurerm_sql_database" "mt_db" {
  name                = "mt-db"
  resource_group_name = local.resource_group_name
  location            = local.location
  server_name         = azurerm_sql_server.mt_server.name

  depends_on = [
    azurerm_sql_server.mt_server
  ]
}

#add firewall rule to the sql server
resource "azurerm_sql_firewall_rule" "mt_server_firewall" {
  name                = "mt-server-firewall"
  resource_group_name = azurerm_resource_group.mtc_rg.name
  server_name         = azurerm_sql_server.mt_server.name
  start_ip_address    = "27.147.172.202"
  end_ip_address      = "27.147.172.202"

  depends_on = [ 
    azurerm_sql_server.mt_server
   ]
}