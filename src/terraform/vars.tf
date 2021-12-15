locals {
  nginx_conf = templatefile("${path.module}/templates/nginx_conf.tpl", {
    API_ADDRESS = azurerm_network_interface.vm_api.private_ip_address
    API_PORT = 3000
  })
}

data "azurerm_client_config" "current" {}

variable "project_name" { 
  default = "openvpn" 
}

variable "location" {
  default = "East US"
}

variable "vnet_name" {
  default = "openpvn-vnet"
}

variable "vnet_address" {
  default = "20.20.0.0/16"
}

variable "subnet_address" {
  default = "20.20.0.224/27"
}

variable "vnet2_name" {
  default = "openpvn-paired"
}

variable "vnet2_address" {
  default = "30.30.0.0/16"
}

variable "subnet2_address" {
  default = "30.30.0.0/24"
}

variable "vnet3_name" {
  default = "proxy-net"
}

variable "vnet3_address" {
  default = "40.40.0.0/16"
}

variable "subnet3_address" {
  default = "40.40.0.0/24"
}

variable "openvpnserver_vm_user" {
  default = "adminuser"
}

variable "openvpnserver_vm_user_ssh_path" {
  default = "../../keys/key.pub"
}

variable "openvpnserver_vm_user_ssh_private_key_path" {
  default = "../../keys/key"
}

variable "openvpn_protocol" {
  default = "udp"
}

variable "openvpn_port" {
  default = "1194"
}

variable "openvpn_address" {
  default = "10.10.5.0/24"
}

variable "openvpn_ca_values" {
  default = {
    country = "BR"
    province = "SP"
    city = "Itu"
    organization = "CodeFeeling"
    email = "contato@ecodefeeling.com.br"
  }
}

variable "openvpnserver_vm_size" {
  default = "Standard_B2s"
}

variable "private_dns_name" {
  default = "vpn.internal"
}

variable "storage_account_name" {
  default = "missaoprivateaccess"
}
variable "storage_account_tier" {
  default = "Standard"
}
variable "storage_account_kind" {
  default = "StorageV2"
}
variable "storage_account_replication_type" {
  default = "LRS"
}

variable "openvpn_client_name" {
  default = "demo"
}

variable "vm_api_name" {
  default = "simple-api"
}

variable "vm_api_size" {
  default = "Standard_B2s"
}

variable "proxy_vm_name" {
  default = "proxy-vm"
}

variable "proxy_vm_size" {
  default = "Standard_B2s"
}