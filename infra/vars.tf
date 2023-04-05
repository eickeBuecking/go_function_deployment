# SECRETS, PLEASE PROVIDE THESE VALUES IN A TFVARS FILE
variable "SUBSCRIPTION_ID" {
    type = string
    sensitive = true
}
variable "TENANT_ID" {
    type = string
    sensitive = true
}

# GLOBAL VARIABLES
variable "RESOURCE_GROUP" {
  default = "noise-event-collector"
}
variable "LOCATION" {
  default = "northeurope"
}