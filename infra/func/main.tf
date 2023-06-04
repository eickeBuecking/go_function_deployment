
### INPUT VARs ###
variable "LOCATION" {}
variable "RESOURCE_GROUP" {}
variable "STORAGE_ACC_NAME" {}
variable "STORAGE_ACC_KEY" {}
variable "STORAGE_CONNECTION_STRING" {}
variable "KEY_VAULT_ID" {}

resource "azurerm_application_insights" "noise_event_collector_insights" {
  name                = "noise-event-collector-insights"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  application_type    = "other"
}

resource "azurerm_service_plan" "noise_processor_app_service_plan" {
  name                = "noise-collector-app-service-plan"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  os_type = "Linux"
  sku_name = "Y1"
}

resource "azurerm_linux_function_app" "noise_event_processor_app" {
  name                = "noise-event-collector-app"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  service_plan_id = azurerm_service_plan.noise_processor_app_service_plan.id
  app_settings = {
    //FUNCTIONS_WORKER_RUNTIME = "Custom",
    AzureWebJobsStorage = var.STORAGE_CONNECTION_STRING,
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.noise_event_collector_insights.instrumentation_key,
    WEBSITE_RUN_FROM_PACKAGE = "1",
    SCM_DO_BUILD_DURING_DEPLOYMENT: "true",
    ENABLE_ORYX_BUILD: "true",
    FUNCTIONS_WORKER_RUNTIME="custom"
  }
  https_only                 = "true"
  storage_account_name       = var.STORAGE_ACC_NAME
  storage_account_access_key = var.STORAGE_ACC_KEY

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }

  # FIXME: Use DNS names instead of enabling CORS
  site_config {
    cors {
      allowed_origins = ["*"]
    }
  }
}

//Add resources for a Cosmos MongoDB, name of the resource should be event-store. 
resource "azurerm_cosmosdb_account" "event_store" {
  name                = "materialized-event-store"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  offer_type          = "Standard"
  kind                = "MongoDB"
  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }
  geo_location {
    location          = var.LOCATION
    failover_priority = 0
  }
  capabilities {
    name = "EnableServerless"
  }
  capabilities {
    name = "EnableMongo"
  }
  capabilities {
    name = "MongoDBv3.4"
  }
}

data "azurerm_cosmosdb_account" "event_store_data" {
  name                = azurerm_cosmosdb_account.event_store.name
  resource_group_name = azurerm_cosmosdb_account.event_store.resource_group_name
}

resource "azurerm_key_vault_secret" "event_store_access_key" {
  name         = "event-store-access-key"
  value        = data.azurerm_cosmosdb_account.event_store_data.primary_key
  key_vault_id = var.KEY_VAULT_ID
}