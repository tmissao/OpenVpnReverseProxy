output "openvpn" {
  value = module.openvpn
}

output "storage_account_endpoind" {
  value = azurerm_private_dns_a_record.storage.fqdn
}

output "vnet_route" {
  value = [module.network1.vnet_route, module.network2.vnet_route]
}

output "proxy_vm_public_ip" {
  value = azurerm_public_ip.proxy_vm.ip_address
}

output "api_vm_private_ip" {
  value = azurerm_network_interface.vm_api.private_ip_address
}