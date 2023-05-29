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
  
  depends_on = [ 
    azurerm_resource_group.mtc_rg
   ]
}

#azure web app
resource "azurerm_app_service" "test_web" {
  name                = "test-webapp32444"
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  app_service_plan_id = azurerm_app_service_plan.app_plan.id

  source_control {
    repo_url           = "https://github.com/MirajHoque/ProductApp.git"
    branch             = "master"
    manual_integration = true
    use_mercurial      = false
  }

  depends_on = [
    azurerm_app_service_plan.app_plan
  ]

}

#mssql server
resource "azurerm_mssql_server" "mt_server" {
  name                         = "mtserver32444"
  resource_group_name          = azurerm_resource_group.mtc_rg.name
  location                     = azurerm_resource_group.mtc_rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "azure@123"
}

#mssql database
resource "azurerm_mssql_database" "mt_db" {
  name           = "mtdb"
  server_id      = azurerm_mssql_server.mt_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true

  depends_on = [
    azurerm_mssql_server.mt_server
  ]

  tags = {
    foo = "bar"
  }
}


#add firewall rule to the sql server
resource "azurerm_sql_firewall_rule" "mt_server_firewall_rule_Azure_services" {
  name                = "mt-server-firewall-rule-Azure-services"
  resource_group_name = azurerm_resource_group.mtc_rg.name
  server_name         = azurerm_mssql_server.mt_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"

  depends_on = [
    azurerm_mssql_server.mt_server
  ]
}


#add firewall rule to the sql server
resource "azurerm_sql_firewall_rule" "mt_server_firewall_rule_Client_IP" {
  name                = "mt-server-firewall-client-ip"
  resource_group_name = azurerm_resource_group.mtc_rg.name
  server_name         = azurerm_mssql_server.mt_server.name
  start_ip_address    = "27.147.172.202"
  end_ip_address      = "27.147.172.202"

  depends_on = [
    azurerm_mssql_server.mt_server
  ]
}

#create table & add data to the table
resource "null_resource" "database_table" {
  provisioner "local-exec" {
    command = "sqlcmd -S mtserver32444.database.windows.net -U sqladmin -P azure@123 -d mtdb -i init.sql"
  }

  depends_on = [
    azurerm_mssql_server.mt_server
  ]
}