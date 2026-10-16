variable "resource_group_name" {
  type    = string
  default = "azure-for-devs-terraform"
}

variable "location" {
  type    = string
  default = "brazilsouth"
}

variable "sql_server_name" {
  type    = string
  default = "adatechsrv"
}

variable "admin_username" {
  type    = string
  default = "ada"
}

variable "admin_password" {
  type    = string
  default = "@datech123"
}

variable "database_name" {
  type    = string
  default = "AdaTechDb"
}

variable "firewall_rule_name" {
  type    = string
  default = "EvertonRules"
}

variable "start_ip_address" {
  type    = string
  default = "0.0.0.0"
}

variable "end_ip_address" {
  type    = string
  default = "255.255.255.255"
}

variable "fruta_amarela" {
  type    = string
  default = "banana"
}