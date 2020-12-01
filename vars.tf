variable "prefix" {
  description = "The prefix for all the resources for this project"
  default = "udacity-web-server"
}

variable "location" {
  description = "The azure location in which all resources in this project will be created."
  default = "East US"
}

variable "username" {
  description = "The admin username of the virtual machine in this project."
  default = "azureadmin"
}

variable "password" {
  description = "The password of the admin username of the virtual machine in this project."
  default = "P@ssw0rd1234!"
}

variable "size" {
  description = "The number of nodes and corresponding resources to create in our cluster."
  default = 2
}
