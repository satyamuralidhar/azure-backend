provider "azurerm" {
   subscription_id = "${var.subscriptionid}"
   client_id       = "${var.clientid}"
   client_secret   = "${var.clientsecret}"
   tenant_id       = "${var.tenantid}"
}


terraform {
    backend "azurerm" {
        resource_group_name = "${azurerm_resource_group}"
        storage_account_name = "${var.prefix}-sa"
        container_name="${var.prefix}-blob"
        key="terraform.tfstate"
    }
}

resource "azurerm_resource_group" "satya" {
  name     = "${var.prefix}-rsg"
  location = "${var.location}"
}
resource "azurerm_virtual_network" "myvnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.satya.name}"
}

resource "azurerm_subnet" "subnetone" {
    name                 = "${var.prefix}-sub1"
  virtual_network_name = "${azurerm_virtual_network.muralidhar.name}"
   resource_group_name = "${azurerm_resource_group.rsg.name}"
  address_prefix       = "10.0.1.0/24"

}

resource "azurerm_subnet" "subnettwo" {
    name                 = "${var.prefix}-sub2"
  virtual_network_name = "${azurerm_virtual_network.myvnet.name}"
   resource_group_name = "${azurerm_resource_group.satya.name}"
  address_prefix       = "10.0.2.0/24"

}

resource "azurerm_network_security_group" "murali" {
  name                = "${var.prefix}-nsg"
  location            = "${azurerm_resource_group.satya.location}"
  resource_group_name = "${azurerm_resource_group.satya.name}"

  security_rule {
    name                       = "firewall"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "terraform-nsg"
  }
}

resource "azurerm_public_ip" "publicip" {
    name = "terraformip"
    resource_group_name = "${azurerm_resource_group.satya.name}"
    location = "${var.location}"
    public_ip_address_allocation = "dynamic"

}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  resource_group_name = "${azurerm_resource_group.satya.name}"
  location = "${var.location}"

  ip_configuration {
    name                          = "terraformipconfig"
    subnet_id                     = "${azurerm_subnet.sub1.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
  }
}

resource "azurerm_virtual_machine" "myvm" {
    name = "${var.prefix}-vm"
    resource_group_name = "${azurerm_resource_group.satya.name}"
    location = "${var.location}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size               = "Standard_B1s"
    #to delete os disk after vm deleted and data
    delete_os_disk_on_termination = true
    delete_data_disk_on_termination = true

     storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name              = "myosdisk1"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

  os_profile {
        computer_name  = "${azurerm_virtual_machine.myvm.name}"
        admin_username = "${var.user_name}"
        admin_password = "${file(sample.txt)}"
    }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "remote-exec" {
    connection {
      user     = "satya"
      password = "$file{sample.txt}"
    }

    inline = [
      "sudo apt-get update",
      "sudo apt-get install apache2 -y"
    ]
  }
}




