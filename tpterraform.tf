provider "azurerm" {
}

# RESSOURCES GROUP
resource "azurerm_resource_group" "tpterra" {
    count    = "${length(var.location)}"
    name     = "rg-global-vnet-peering-${count.index}"
    location = "${element(var.location, count.index)}"
}

# VIRTUAL NETWORK
resource "azurerm_virtual_network" "myterraformnetwork" {
    count               = "${length(var.location)}"
    name                = "gregVN-${count.index}"
    address_space       = ["${element(var.vnet_address_space, count.index)}"]
    location            = "${element(azurerm_resource_group.tpterra.*.location, count.index)}"
    resource_group_name = "${element(azurerm_resource_group.tpterra.*.name, count.index)}"

    tags {
        environment = "Terraform Demo"
    }
}

# SUB NETWORK
resource "azurerm_subnet" "myterraformsubnet" {
    count                = "${length(var.location)}"
    name                 = "mySubnet-${count.index}"
    resource_group_name  = "${element(azurerm_resource_group.tpterra.*.name, count.index)}"
    virtual_network_name = "${element(azurerm_virtual_network.myterraformnetwork.*.name, count.index)}"
    #virtual_network_name = "${element(myterraformnetwork.tpterra.*.name, count.index)}"
    #address_prefix       = "${cidrsubnet("${element(azurerm_virtual_network.myterraformnetwork.*.address_space[count.index], count.index)}", 13, 0)}" # /2address_prefix       = "10.0.0.0/16"
    address_prefix       = "${cidrsubnet("${element(azurerm_virtual_network.myterraformnetwork.*.address_space[count.index], count.index)}", 0, 0)}"
}


# PUBLIC IP 1
resource "azurerm_public_ip" "myterraformpublicip" {
    count = 3
    name                         = "myPublicIP-${count.index}"
    location                     = "${element(azurerm_resource_group.tpterra.*.location, 0)}"
    resource_group_name          = "${element(azurerm_resource_group.tpterra.*.name, 0)}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# PUBLIC IP 2
resource "azurerm_public_ip" "myterraformpublicip2" {
    count = 2
    name                         = "myPublicIP-${count.index}"
    location                     = "${element(azurerm_resource_group.tpterra.*.location, 1)}"
    resource_group_name          = "${element(azurerm_resource_group.tpterra.*.name, 1)}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# NETWORK INTERFACE 1
resource "azurerm_network_interface" "myterraformnic" {
    count               = 3
    name                = "myNIC-${count.index}"
    location            = "${element(azurerm_resource_group.tpterra.*.location, 0)}"
    resource_group_name = "${element(azurerm_resource_group.tpterra.*.name, 0)}"
    # network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration-${count.index}"
        subnet_id                     = "${element(azurerm_subnet.myterraformsubnet.*.id, 0)}"
        private_ip_address_allocation = "${var.private_ip_address_allocation}"
        public_ip_address_id          = "${element(azurerm_public_ip.myterraformpublicip.*.id, count.index)}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# NETWORK INTERFACE 2
resource "azurerm_network_interface" "myterraformnic2" {
    count               = 2
    name                = "myNIC-${count.index + 3}"
    location            = "${element(azurerm_resource_group.tpterra.*.location,1)}"
    resource_group_name = "${element(azurerm_resource_group.tpterra.*.name, 1)}"
    # network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration-${count.index}"
        subnet_id                     = "${element(azurerm_subnet.myterraformsubnet.*.id, 1)}"
        private_ip_address_allocation = "${var.private_ip_address_allocation}"
        public_ip_address_id          = "${element(azurerm_public_ip.myterraformpublicip2.*.id, count.index+3)}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# VM 3
resource "azurerm_virtual_machine" "myterraformvm" {
    count = 3
    name                  = "myVM-${count.index}"
    location              = "${element(azurerm_resource_group.tpterra.*.location, 0)}"
    resource_group_name   = "${element(azurerm_resource_group.tpterra.*.name, 0)}"
    network_interface_ids = ["${element(azurerm_network_interface.myterraformnic.*.id,count.index)}"]
    vm_size               = "${var.vm_size}"

    storage_os_disk {
        name              = "myOsDisk-${count.index}"
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
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfnlhuPRBjUP2Qt4iw6s5QltpN1HpB4UV2ob7fTeBNBjgjZAgmeRKan6PU7HCae/XiUI554scVL9/SKc+CshGBG5rMtaGYWlpCjMqdmkR7s1atyu8NH4D9jE1FhjJrGKDH2CPVSJKffTqVMZLQ45jqeMytcmudkXRLw7hKR1LA6rE3KCN3vmI1zfvfXXkca7RVZqGMa7eSpOTBZwmMoPQGyJEBS8ft1aJEkzg4EOZdFiE/j1sBbNTTqR/3SHkB65fJrDX5ftPDAxk6UVmWOv9psp1z0r1Yx7pLTeMhhjSOZIKUuD16dkJ1oDRk6Qa3SbkpSkEqSAfCkVDu/9wJCdY1 greg@linux-2.home"
        }
    }
}

# vm 2
resource "azurerm_virtual_machine" "myterraformvm2" {
    count = 2
    name                  = "myVM-${count.index+3}"
    location              = "${element(azurerm_resource_group.tpterra.*.location, 1)}"
    resource_group_name   = "${element(azurerm_resource_group.tpterra.*.name, 1)}"
    network_interface_ids = ["${element(azurerm_network_interface.myterraformnic2.*.id,count.index + 3)}"]
    vm_size               = "${var.vm_size}"

    storage_os_disk {
        name              = "myOsDisk-${count.index+3}"
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
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfnlhuPRBjUP2Qt4iw6s5QltpN1HpB4UV2ob7fTeBNBjgjZAgmeRKan6PU7HCae/XiUI554scVL9/SKc+CshGBG5rMtaGYWlpCjMqdmkR7s1atyu8NH4D9jE1FhjJrGKDH2CPVSJKffTqVMZLQ45jqeMytcmudkXRLw7hKR1LA6rE3KCN3vmI1zfvfXXkca7RVZqGMa7eSpOTBZwmMoPQGyJEBS8ft1aJEkzg4EOZdFiE/j1sBbNTTqR/3SHkB65fJrDX5ftPDAxk6UVmWOv9psp1z0r1Yx7pLTeMhhjSOZIKUuD16dkJ1oDRk6Qa3SbkpSkEqSAfCkVDu/9wJCdY1 greg@linux-2.home"
        }
    }
}