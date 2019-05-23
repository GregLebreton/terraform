
provider "azurerm" {
}

# refer to a resource group
data "azurerm_resource_group" "rGroup" {
  name = "test-dupli-VMs"
}

data "azurerm_virtual_network" "vNetwork" {
  name = "${data.azurerm_resource_group.rGroup.name}-vnet"
  resource_group_name = "${data.azurerm_resource_group.rGroup.name}"
}

data "azurerm_subnet" "myterraformsubnet" {
    name = "default"
    virtual_network_name = "${data.azurerm_virtual_network.vNetwork.name}"
    resource_group_name = "${data.azurerm_resource_group.rGroup.name}"
}

# PUBLIC IP 
resource "azurerm_public_ip" "myterraformpublicip" {
    count = 3
    name                         = "myPublicIP-${count.index}"
    location                     = "${data.azurerm_resource_group.rGroup.location}"
    resource_group_name          = "${data.azurerm_resource_group.rGroup.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# NETWORK INTERFACE
resource "azurerm_network_interface" "myNetInt" {
    count                 = 3
    name                  = "myNetInt-${count.index}"
    location              = "${data.azurerm_resource_group.rGroup.location}"
    resource_group_name   = "${data.azurerm_resource_group.rGroup.name}"

        ip_configuration {
            name                          = "myNicConfiguration-${count.index}"
            subnet_id                     = "${data.azurerm_subnet.myterraformsubnet.id}"
            private_ip_address_allocation = "Dynamic"
            public_ip_address_id          = "${element(azurerm_public_ip.myterraformpublicip.*.id, count.index)}"
        }

        tags {
            environment = "Terraform Demo"
        }
}

# VM (3)
resource "azurerm_virtual_machine" "myVm" {
    count                 = 3
    name                  = "VM-${count.index}"
    location              = "${data.azurerm_resource_group.rGroup.location}"
    resource_group_name   = "${data.azurerm_resource_group.rGroup.name}"
    vm_size               = "Standard_B1ms"
    network_interface_ids = ["${element(azurerm_network_interface.myNetInt.*.id, count.index)}"]

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
        computer_name = "myVM-${count.index}"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfnlhuPRBjUP2Qt4iw6s5QltpN1HpB4UV2ob7fTeBNBjgjZAgmeRKan6PU7HCae/XiUI554scVL9/SKc+CshGBG5rMtaGYWlpCjMqdmkR7s1atyu8NH4D9jE1FhjJrGKDH2CPVSJKffTqVMZLQ45jqeMytcmudkXRLw7hKR1LA6rE3KCN3vmI1zfvfXXkca7RVZqGMa7eSpOTBZwmMoPQGyJEBS8ft1aJEkzg4EOZdFiE/j1sBbNTTqR/3SHkB65fJrDX5ftPDAxk6UVmWOv9psp1z0r1Yx7pLTeMhhjSOZIKUuD16dkJ1oDRk6Qa3SbkpSkEqSAfCkVDu/9wJCdY1 greg@linux-2.home"
        }
    }
}
