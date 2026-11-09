terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
  use_oidc         = true
  use_azuread_auth = true
}
}
# Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "reactapp-infra-rg"
  location = var.location
}
# 2. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "reactapp-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}
# 3. Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "reactapp-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# 4. Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "reactapp-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # Allow SSH only from your public IP
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
  # Allow HTTP
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# 5. Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "reactapp-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# 6. Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "reactapp-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}
# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# 7. Azure Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "reactapp-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  # Cloud-Init configuration
  custom_data = base64encode(
    file("${path.module}/cloud-init.yaml")
  )
  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }
}