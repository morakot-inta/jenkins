# azurerm provider
provider "azurerm" {
  subscription_id = "fd37b54f-84ba-4c3d-a8aa-65304aee1db4"
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "rg-jenkins-qa-${var.location}"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-jenkins-qa-${var.location}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.0.0.0/24"]
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "this" {
  name                 = "snet-01"
  address_prefixes     = ["10.0.0.0/24"]
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_network_interface" "this" {
  name                = "nic-jenkins-qa-${var.location}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }


  depends_on = [azurerm_public_ip.this]
}

resource "azurerm_public_ip" "this" {
  name                = "pip-jenkins-qa-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "vm-jenkins-qa-${var.location}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  computer_name       = "vmjenkinsqa"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }



}
