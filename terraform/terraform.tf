provider "azurerm" {
  features {}
  use_cli = true
  subscription_id = "xxxx"
}

resource "azurerm_resource_group" "rg" {
  name     = "wordpress-resources"
  location = "Central US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "wordpress-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "wordpress-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "wordpress-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "wordpress-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "wordpress-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                = "Standard_B1s"

  admin_username      = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
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
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "wordpress-mysql-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name            = "B_Standard_B1ms"
  administrator_login = "xxxxxxx"
  administrator_password = "xxxxxxx"

  version = "8.0.21"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_mysql_flexible_database" "db" {
  name                = "wordpress-db"
  server_name         = azurerm_mysql_flexible_server.mysql.name
  resource_group_name = azurerm_resource_group.rg.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
  depends_on = [azurerm_mysql_flexible_server.mysql]
}
