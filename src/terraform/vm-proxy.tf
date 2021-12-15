resource "azurerm_public_ip" "proxy_vm" {
  name = "proxy_vm_name"
  location =  var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
}

resource "azurerm_network_interface" "proxy_vm" {
  name = var.proxy_vm_name
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  ip_configuration {
    name = var.proxy_vm_name
    subnet_id = module.network3.subnet_id
    public_ip_address_id = azurerm_public_ip.proxy_vm.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.subnet3_address, 10)
  }
}

resource "azurerm_network_security_group" "proxy_vm" {
  name                = var.proxy_vm_name
  location            = var.location
  resource_group_name =  azurerm_resource_group.rg.name
  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "proxy_vm" {
  network_interface_id      = azurerm_network_interface.proxy_vm.id
  network_security_group_id = azurerm_network_security_group.proxy_vm.id
}

resource "azurerm_linux_virtual_machine" "proxy_vm" {
  name = var.proxy_vm_name
  admin_username = var.openvpnserver_vm_user
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.proxy_vm.id]
  size = var.proxy_vm_size
  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  os_disk {
    caching = "None"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = var.openvpnserver_vm_user
    public_key = file(var.openvpnserver_vm_user_ssh_path)
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "null_resource" "setup_proxy" {
  triggers = {
    setup-proxy = filebase64sha256("${path.module}/scripts/setup-proxy.sh")
  }
  connection {
    type     = "ssh"
    user     = var.openvpnserver_vm_user
    host     = azurerm_public_ip.proxy_vm.ip_address
    private_key = file(var.openvpnserver_vm_user_ssh_private_key_path)
  }
  provisioner "file" {
    source = "${path.module}/${var.openvpn_client_name}.ovpn"
    destination = "${var.openvpn_client_name}.ovpn"
  }
  provisioner "file" {
    content = local.nginx_conf
    destination = "nginx.conf"
  }
  provisioner "file" {
    source = "${path.module}/scripts/setup-proxy.sh"
    destination = "setup-proxy.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 700 setup-proxy.sh",
      "./setup-proxy.sh ${var.openvpn_client_name}.ovpn nginx.conf",
    ]
  }
  depends_on = [ 
    azurerm_linux_virtual_machine.proxy_vm,
    null_resource.generate_vpnclient,
  ]
}