resource "azurerm_network_interface" "vm_api" {
  name = var.vm_api_name
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  ip_configuration {
    name = var.vm_api_name
    subnet_id = module.network2.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.subnet2_address, 10)
  }
}

data "template_file" "vm_api" {
  template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "vm_api_shell-script" {
  template = file("${path.module}/scripts/setup-api.sh")
}

data "template_cloudinit_config" "vm_api" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.vm_api.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.vm_api_shell-script.rendered
  }
}

resource "azurerm_linux_virtual_machine" "vm_api" {
  name = var.vm_api_name
  admin_username = var.openvpnserver_vm_user
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_api.id]
  size = var.vm_api_size
  custom_data = data.template_cloudinit_config.vm_api.rendered
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

resource "azurerm_network_security_group" "vm_api" {
  name                = var.vm_api_name
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
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_api" {
  network_interface_id      = azurerm_network_interface.vm_api.id
  network_security_group_id = azurerm_network_security_group.vm_api.id
}