terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {} 
  client_id       = "a185c1ad-4d48-45d3-8f40-3c41d0cd40f4"
  client_secret   = "ARU8Q~BDoAUXVd-uCSwwD_TlpHpysVV02vrFDa7d"
  tenant_id       = "023d861a-1653-4531-9e1e-5d8c8d05bfb1"
  subscription_id = "4ec5f1f7-a399-43dd-a4cc-2f51e3a7a86b"
}

terraform {
  backend "azurerm" {
    storage_account_name = "tfstorageacc16"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"

    # rather than defining this inline, the Access Key can also be sourced
    # from an Environment Variable - more information is available below.
    access_key = "7hlFTh8wIbsMuF/5V+KrwBwZ47ReMbYC9NOrQriTcHmjwyhDYdgev+Bx5Vtxn9+PbntKIwv8JFlX+AStfJEwkw=="
  }
}

resource "azurerm_resource_group" "example" {
  name              =   "${var.rgname}"
  location          =   "${var.rglocation}"
}

resource "azurerm_virtual_network" "example" {
  name                =     "${var.prefix}-10"
  resource_group_name =     "${azurerm_resource_group.example.name}"
  location            =     "${azurerm_resource_group.example.location}"
  address_space       =     ["${var.vnet_cidr_prefix}"]
}

resource "azurerm_subnet" "example" {
  name                  =     "${var.subnet}"
  resource_group_name   =     "${azurerm_resource_group.example.name}"
  virtual_network_name  =     "${azurerm_virtual_network.example.name}"
  address_prefixes      =     ["${var.subnet1_cidr_prefix}"]
}

resource "azurerm_public_ip" "example" {
  name                  =         "${var.prefix}-pip"
  resource_group_name   =         "${azurerm_resource_group.example.name}"
  location              =         "${azurerm_resource_group.example.location}"
  allocation_method     =         "Dynamic"
}

resource "azurerm_network_security_group" "example" {
  name                  =   "${var.prefix}-nsg"
  location              =   "${azurerm_resource_group.example.location}"
  resource_group_name   =   "${azurerm_resource_group.example.name}"

  security_rule {
    name                       = "RDP"
    #priority                   = 1001
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  resource_group_name = "${azurerm_resource_group.example.name}"
  location            = "${azurerm_resource_group.example.location}"

  ip_configuration {
    name                            = "internal"
    subnet_id                       = azurerm_subnet.example.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = "${azurerm_public_ip.example.id}"
  }

  depends_on=[
      azurerm_network_security_group.example,
      azurerm_subnet.example,
      azurerm_public_ip.example,
      ]
}

resource "azurerm_windows_virtual_machine" "example" {
  name                      =   "${var.prefix}-vm"
  location                  =   "${azurerm_resource_group.example.location}"
  resource_group_name       =   "${azurerm_resource_group.example.name}"
  network_interface_ids     =   [azurerm_network_interface.example.id]
  size                      =   "Standard_B1s"
  computer_name             =   "${var.computer_name}"
  admin_username            =   "${var.admin_username}"
  admin_password            =   "${var.admin_passwd}"

   os_disk {
    caching                 =   "ReadWrite"
    storage_account_type    =   "Standard_LRS"
   }

   source_image_reference {
     publisher          =   "MicrosoftWindowsServer"
     offer              =   "WindowsServer"
     sku                =   "2019-Datacenter"
     version            =   "latest"
   }

}
