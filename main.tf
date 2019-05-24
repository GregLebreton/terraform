provider "azurerm" {
}

# RESSOURCES GROUP
resource "azurerm_resource_group" "DEV" {

    name     = "DEV"
    location = "francecentral"
}

########################### TECH ###########################

# VIRTUAL NETWORK
resource "azurerm_virtual_network" "technetwork" {
    name                = "techVN"
    address_space       = ["${var.vnet_address_space}"]
    location            = "${azurerm_resource_group.DEV.location}"
    resource_group_name = "${azurerm_resource_group.DEV.name}"

    tags {
        environment = "TECH"
    }
}

# SUB NETWORK
resource "azurerm_subnet" "techsubnet" {
    name                 = "techSN"
    resource_group_name  = "${azurerm_resource_group.DEV.name}"
    virtual_network_name = "${azurerm_virtual_network.technetwork.name}"
    address_prefix       = "${var.vnet_address_space}"
    network_security_group_id = "${azurerm_network_security_group.techsecu.id}"
}

# LOAD BALANCER
resource "azurerm_lb" "loadbalancer" {
  name                = "TestLoadBalancer"
  location            = "francecentral"
  resource_group_name = "${azurerm_resource_group.DEV.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.techpublicip.id}"
  }
}

# resource "azurerm_lb_nat_pool" "test" {
#   resource_group_name            = "${azurerm_resource_group.DEV.name}"
#   loadbalancer_id                = "${azurerm_lb.loadbalancer.id}"
#   name                           = "SampleApplicationPool"
#   protocol                       = "Tcp"
#   frontend_port_start            = 80
#   frontend_port_end              = 81
#   backend_port                   = 8080
#   frontend_ip_configuration_name = "PublicIPAddress"
# }

resource "azurerm_lb_backend_address_pool" "test" {
  resource_group_name = "${azurerm_resource_group.DEV.name}"
  loadbalancer_id     = "${azurerm_lb.loadbalancer.id}"
  name                = "acctestpool"
}

resource "azurerm_network_interface_backend_address_pool_association" "test" {
  network_interface_id    = "${azurerm_network_interface.technetInt.id}"
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.test.id}"
}

# NETWORK INTERFACE
resource "azurerm_network_interface" "technetInt" {
    count                 = 2
    name                  = "NWI-${count.index}"
    location              = "${azurerm_resource_group.DEV.location}"
    resource_group_name   = "${azurerm_resource_group.DEV.name}"

        ip_configuration {
            name                          = "NWI-Configuration-${count.index}"
            subnet_id                     = "${azurerm_subnet.techsubnet.id}"
            private_ip_address_allocation = "Static"
            public_ip_address_id          = "${element(azurerm_public_ip.techpublicip.*.id, count.index)}"
            azurerm_network_interface_backend_address_pool_association = "${azurerm_network_interface_backend_address_pool_association.test.id}"
        }

        tags {
            environment = "TECH"
        }
}
# SECURITY 
resource "azurerm_network_security_group" "techsecu" {
  name                = "techsecu"
  location            = "${azurerm_resource_group.DEV.location}"
  resource_group_name = "${azurerm_resource_group.DEV.name}"

  security_rule {
        name                        = "techrules"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_ranges          = ["22"]
        destination_port_range      = "*"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    tags = {
        environment = "TECH"
    }
}

# PUBLIC IP 
resource "azurerm_public_ip" "techpublicip" {
    count                        = 2
    name                         = "myPublicIP-${count.index}"
    location                     = "${azurerm_resource_group.DEV.location}"
    resource_group_name          = "${azurerm_resource_group.DEV.name}"
    allocation_method            = "Static"

    tags {
        environment = "TECH"
    }
}

# TECH VMs
resource "azurerm_virtual_machine" "techvm" {
    count = 2
    name                  = "tech-VM-${count.index}"
    location              = "${azurerm_resource_group.DEV.location}"
    resource_group_name   = "${azurerm_resource_group.DEV.name}"
    network_interface_ids = ["${element(azurerm_network_interface.technetInt.*.id,count.index)}"]
    vm_size               = "${var.vm_size}"
    
    storage_os_disk {
        name              = "tech-OsDisk-${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "tech-VM-${count.index}"
        admin_username = "${var.admin_username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${var.key_data}"
        }
    }
    tags {
        environment = "TECH"
    }
}


########################### APPS ###########################

resource "azurerm_virtual_network" "appsnetwork" {
    name                = "appsVN"
    address_space       = ["${var.vnet_address_space}"]
    location            = "${azurerm_resource_group.DEV.location}"
    resource_group_name = "${azurerm_resource_group.DEV.name}"

    tags {
        environment = "APPS"
    }
}

resource "azurerm_subnet" "appssubnet" {
    name                 = "appsSN"
    resource_group_name  = "${azurerm_resource_group.DEV.name}"
    virtual_network_name = "${azurerm_virtual_network.appsnetwork.name}"
    address_prefix       = "${var.vnet_address_space}"
    network_security_group_id  = "${azurerm_network_security_group.apsssecu.id}" 

}

resource "azurerm_network_interface" "appsIntTech" {
    name                  = "NWIapps"
    location              = "${azurerm_resource_group.DEV.location}"
    resource_group_name   = "${azurerm_resource_group.DEV.name}"

        ip_configuration {
            name                          = "NWI-Configuration-apps"
            subnet_id                     = "${azurerm_subnet.appssubnet.id}"
            private_ip_address_allocation = "Dynamic"
            public_ip_address_id          = "${azurerm_public_ip.appspublicip.id}"
        }

    tags {
        environment = "APPS"
    }
}

# SECURITY
resource "azurerm_network_security_group" "apsssecu" {
  name                = "appsecu"
  location            = "${azurerm_resource_group.DEV.location}"
  resource_group_name = "${azurerm_resource_group.DEV.name}"

  security_rule {
    name                        = "apssrules"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "7050"
    destination_port_range      = "7050"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
    tags = {
      environment = "APPS"
    }
}

# PUBLIC IP APPS
resource "azurerm_public_ip" "appspublicip" {
    name                         = "appsPublicIP"
    location                     = "${azurerm_resource_group.DEV.location}"
    resource_group_name          = "${azurerm_resource_group.DEV.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "APPS"
    }
}

# APPS VM
resource "azurerm_virtual_machine" "appsvm" {
    name                  = "appVM"
    location              = "${azurerm_resource_group.DEV.location}"
    resource_group_name   = "${azurerm_resource_group.DEV.name}"
    network_interface_ids = ["${azurerm_network_interface.appsIntTech.id}"]
    vm_size               = "${var.vm_size}"
    
    storage_os_disk {
        name              = "OsDiskapps"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm-${count.index}"
        admin_username = "${var.admin_username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${var.key_data}"
        }
    }

    tags {
        environment = "APPS"
    }
}



########################### DATA ###########################

resource "azurerm_virtual_network" "datanetwork" {
    name                = "dataVN"
    address_space       = ["${var.vnet_address_space}"]
    location            = "${azurerm_resource_group.DEV.location}"
    resource_group_name = "${azurerm_resource_group.DEV.name}"

    tags {
        environment = "DATA"
    }
}


resource "azurerm_subnet" "datasubnet" {
    name                 = "dataSN"
    resource_group_name  = "${azurerm_resource_group.DEV.name}"
    virtual_network_name = "${azurerm_virtual_network.datanetwork.name}"
    address_prefix       = "${var.vnet_address_space}"
    network_security_group_id  = "${azurerm_network_security_group.datasecu.id}" 

}

resource "azurerm_network_interface" "NetIntdata" {
    name                  = "NWIDATA"
    location              = "${azurerm_resource_group.DEV.location}"
    resource_group_name   = "${azurerm_resource_group.DEV.name}"

        ip_configuration {
            name                          = "NWI-Configuration-apps"
            subnet_id                     = "${azurerm_subnet.datasubnet.id}"
            private_ip_address_allocation = "Dynamic"
            public_ip_address_id          = "${azurerm_public_ip.datapublicip.id}"
        }

        tags {
            environment = "DATA"
        }
}

# SECURITY
resource "azurerm_network_security_group" "datasecu" {
  name                = "datasecu"
  location            = "${azurerm_resource_group.DEV.location}"
  resource_group_name = "${azurerm_resource_group.DEV.name}"
  
  security_rule {
    name                        = "datarules"
    priority                    = 120
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "1251"
    destination_port_range      = "1251"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                        = "datarules2"
    priority                    = 130
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "445"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"  
    }

  tags {
    environment = "DATA"      
  }
}

# INBOUND
# resource "azurerm_network_security_rule" "datarulesIN" {
#   name                        = "datarules"
#   priority                    = 120
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "1251"
#   destination_port_range      = "1251"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = "${azurerm_resource_group.DEV.name}"
#   network_security_group_name = "${azurerm_network_security_group.datasecu.name}"
# }

# # OUTBOUND
# resource "azurerm_network_security_rule" "datarulesOUT" {
#   name                        = "datarules"
#   priority                    = 100
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "445"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = "${azurerm_resource_group.DEV.name}"
#   network_security_group_name = "${azurerm_network_security_group.datasecu.name}"

#   tags = {
#     environment = "DATA"
#   }
# }

# PUBLIC IP DATA
resource "azurerm_public_ip" "datapublicip" {
    name                         = "dataPublicIP"
    location                     = "${azurerm_resource_group.DEV.location}"
    resource_group_name          = "${azurerm_resource_group.DEV.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "DATA"
    }
}

# DATA VM
resource "azurerm_virtual_machine" "datavm" {
    name                  = "dataVM"
    location              = "${azurerm_resource_group.DEV.location}"
    resource_group_name   = "${azurerm_resource_group.DEV.name}"
    network_interface_ids = ["${azurerm_network_interface.NetIntdata.id}"]
    vm_size               = "${var.vm_size}"
    
    storage_os_disk {
        name              = "OsDiskdata"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "data-vm-${count.index}"
        admin_username = "${var.admin_username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${var.key_data}"
        }
    }

    tags {
        environment = "DATA"
    }
}