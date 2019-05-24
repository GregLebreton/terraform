
variable "location" {
    default = [
    "uksouth",
    "southeastasia",
    ]
}

variable "vnet_address_space" {
    default = [
    "10.0.0.0/16",
    "10.1.0.0/16",
    ]
}

variable "vm_size" {}

variable "admin_username" {}

variable "private_ip_address_allocation" {}

variable "key_data" {}


