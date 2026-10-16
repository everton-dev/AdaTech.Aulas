variable "resource_group_name" {
  type    = string
  default = "azure-for-devs"
}

variable "location" {
  type    = string
  default = "brazilsouth"
}

variable "storage_account_name" {
  type    = string
  default = "adatechstorage"
}

variable "service_plan_os" {
  type    = string
  default = "Linux"
}

variable "function_app_name" {
  type    = string
  default = "adatech-cars-everton"
}

variable "functions_version" {
  type    = string
  default = "4"
}

variable "functions_os" {
  type    = string
  default = "linux"
}

variable "sku_storage" {
  type    = string
  default = "Standard_LRS"
}

variable "storage_replication_type" {
  type    = string
  default = "LRS"
}