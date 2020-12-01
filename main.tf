provider "azurerm" {
  features {}
}

# Create the main resource group if doesn't exist
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Create the main virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Create a subnet within the main network
resource "azurerm_subnet" "default" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create the network security group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "AllowVnetInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInBound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "AllowVnetOutBound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowInternetOutBound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerOutBound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "AzureLoadBalancer"
  }

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Create the network interface
resource "azurerm_network_interface" "main" {
  count               = var.size
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "default"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Associate the network security group with the network interface
resource "azurerm_network_interface_security_group_association" "main" {
    count                     = var.size
    network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
    network_security_group_id = azurerm_network_security_group.main.id
}

# Create the public ip
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Create the load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Create the load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "main" {
  name                = "BackEndAddressPool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
}

# Create network interface backend address pool address association 
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.size
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "default"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# Create a load balancer rule
resource "azurerm_lb_rule" "main" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-lb-rl"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
}

# Create the virtual machine availability set
resource "azurerm_availability_set" "main" {
  name                         = "${var.prefix}-as"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Create the managed disk
resource "azurerm_managed_disk" "main" {
  count                = var.size
  name                 = "${var.prefix}-md-${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"

  tags = {
    project = "Udacity-Web-Server"
  }
}

# Reference the packer image
data "azurerm_image" "main" {
  name                = "${var.prefix}-img"
  resource_group_name = azurerm_resource_group.main.name
}

# Create the virtual machine
resource "azurerm_virtual_machine" "main" {
  count                 = var.size
  name                  = "${var.prefix}-vm-${count.index}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  vm_size               = "Standard_B1s"
  availability_set_id   = azurerm_availability_set.main.id

  storage_image_reference {
    id = data.azurerm_image.main.id
  }

  storage_os_disk {
    name              = "MainDisk-${count.index}"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  storage_data_disk {
   name            = element(azurerm_managed_disk.main.*.name, count.index)
   managed_disk_id = element(azurerm_managed_disk.main.*.id, count.index)
   create_option   = "Attach"
   lun             = 1
   disk_size_gb    = element(azurerm_managed_disk.main.*.disk_size_gb, count.index)
 }

  os_profile {
    computer_name  = var.prefix
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    project = "Udacity-Web-Server"
  }
}
