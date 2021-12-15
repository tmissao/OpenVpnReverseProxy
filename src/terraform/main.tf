resource "azurerm_resource_group" "rg" {
  name = var.project_name
  location = var.location
}

resource "azurerm_private_dns_zone" "dns" {
  name                = var.private_dns_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "privatelink_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

module network1 {
  source = "../modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name = var.vnet_name
  vnet_address = var.vnet_address
  vnet_location = azurerm_resource_group.rg.location
  subnet_address = var.subnet_address
  subnet_enforce_private_link_endpoint_network_policies = true
  linked_dns_domains = {
    (azurerm_private_dns_zone.dns.name) = { registration_enabled = true },
    (azurerm_private_dns_zone.privatelink_dns.name) = { registration_enabled = false }
  }
}

module network2 {
  source = "../modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name = var.vnet2_name
  vnet_address = var.vnet2_address
  vnet_location = azurerm_resource_group.rg.location
  subnet_address = var.subnet2_address
  subnet_enforce_private_link_endpoint_network_policies = true
  linked_dns_domains = {
    (azurerm_private_dns_zone.dns.name) = { registration_enabled = true },
    (azurerm_private_dns_zone.privatelink_dns.name) = { registration_enabled = false }
  }
}

module network3 {
  source = "../modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name = var.vnet3_name
  vnet_address = var.vnet3_address
  vnet_location = azurerm_resource_group.rg.location
  subnet_address = var.subnet3_address
  subnet_enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                      = "${var.vnet_name}-to-${var.vnet2_name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.network1.vnet_name
  remote_virtual_network_id = module.network2.vnet_id
}

resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                      = "${var.vnet2_name}-to-${var.vnet_name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.network2.vnet_name
  remote_virtual_network_id = module.network1.vnet_id
}

module "openvpn" {
  source = "../modules/openvpn"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_address = var.vnet_address
  vnet_location = azurerm_resource_group.rg.location
  subnet_address = var.subnet_address
  subnet_id = module.network1.subnet_id
  openvpnserver_vm_user = var.openvpnserver_vm_user
  openvpnserver_vm_size = var.openvpnserver_vm_size
  openvpnserver_vm_user_ssh_path = var.openvpnserver_vm_user_ssh_path
  openvpnserver_vm_user_ssh_private_key_path = var.openvpnserver_vm_user_ssh_private_key_path
  openvpn_ca_values = var.openvpn_ca_values
  openvpn_address = var.openvpn_address
  openvpn_port = var.openvpn_port
  openvpn_protocol = var.openvpn_protocol
  openvpn_routes = [module.network1.vnet_route, module.network2.vnet_route]
}

resource "null_resource" "generate_vpnclient" {
  provisioner "local-exec" {
    command = "/bin/bash ./scripts/generate-vpnclient.sh"
    environment = {
      OPENVPN_SERVER     = module.openvpn.openvpn_public_ip
      OPENVPN_USER = var.openvpnserver_vm_user
      CLIENT_NAME = var.openvpn_client_name
      SSH_KEY = var.openvpnserver_vm_user_ssh_private_key_path
    }
  }
  depends_on = [ 
    module.openvpn
  ]
}