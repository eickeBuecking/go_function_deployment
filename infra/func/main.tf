
### INPUT VARs ###
variable "LOCATION" {}
variable "RESOURCE_GROUP" {}
variable "STORAGE_ACC_NAME" {}
variable "STORAGE_ACC_KEY" {}
variable "STORAGE_CONNECTION_STRING" {}

resource "azurerm_application_insights" "noise_event_processor_insights" {
  name                = "noise-event-processor-insights"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  application_type    = "Node.JS"
}

resource "azurerm_app_service_plan" "noise_processor_app_service_plan" {
  name                = "noise-processor-app-service-plan"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  kind                = "FunctionApp"
  reserved = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "noise_event_processor_app" {
  name                = "noise-event-processor-app"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  app_service_plan_id = azurerm_app_service_plan.noise_processor_app_service_plan.id
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node",
    AzureWebJobsStorage = var.STORAGE_CONNECTION_STRING,
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.noise_event_processor_insights.instrumentation_key,
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
  https_only                 = "true"
  os_type                    = "linux"
  storage_account_name       = var.STORAGE_ACC_NAME
  storage_account_access_key = var.STORAGE_ACC_KEY
  version                    = "~3"

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