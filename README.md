# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository
2. Confirm that all in the dependencies section below have been met.
3. Follow the instructions in the instructions section below to deploy IaaS web server to Azure.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. From Azure Portal, click the **Create a resource** button then search for and select **Resource group**. Enter the name of the resource group and select your preferred region. Ensure that the same resource group and region are specified in your packer and terraform templates.
2. From Azure Portal, via the **Azure Active Directory** blade, register a new application via the **App registrations** menu. Copy the **client id** and the **client secret** of you newly created app as we will need these in a later step.
3. From Azure Portal, grant you app, contributor access to your subscription to allow your app (packer) to create resources in Azure. To do this, search for **Subscriptions** from Azure Portal then select your subscription. Click the **Access control (IAM)** menu then click the **Add role assignments** button. Select the **Contributor** role under **Roles** then search and select your app name in the last search box. Click the **Save** button to add the role assignment.
4. From the command line, navigate to the root directory of this repository then run the following command to build the packer image: `packer build -var 'client_id={your_client_id}' -var 'client_secret={your_client_secret}' -var 'subscription_id={your_subscription_id}' server.json`. Replace **client_id**, **client_secret** and **subscription_id** with your values before running the command.
5. Confirm that you are logged into azure cli and have an active subscription selected by running `az account show`. This command should return the details of your currently logged in user and the selected subscription in azure cli. The same credentials will be used by *terraform* in the next steps. If not logged in run `az login` to log into azure cli then run `az account set --subscription {your_subscription_id}` to select y**our subscription.
6. From the root directory of this repository, update configurable variables in the **vars.tf** file with your preffered **resource prefix**, **azure region** and **size** / number of nodes in your cluster e.t.c.
7. Since our resource group already exists as we created it in step 1, import it into the terraform configuration state so it can be managed by terraform going forward by running the following command: `terraform import azurerm_resource_group.main "/subscriptions/{your_subscription_id}/resourceGroups/{your_resource_group_name}"`
6. From the command line, navigate to the root directory of this repository then run the following command to verify the list of resources to be deployed by terraform to azure: `terraform plan`
7. If the preceding step returns no errors, run the following command to deploy the infrastructure and related resources for the web server application to azure using terraform: `terraform apply`

### Output
Successful execution of the steps above should create the following resources in Azure which represent infrastructure and related resources for our web server application:

1. **Resource group** - The main resource group which will contain all the deployed resources.
2. **Image** - The virtual machine image created using the packer template. This is the base image for the virtual machines.
3. **Virtual network** - The virtual network in Azure for the virtual machines. The virtual network will contain one subnet.
4. **Network security group** - This resource contains inbound and outbound rules for traffic to and from the virtual machines. This resource is linked to the network interface resources. 
5. **Network interface** - 2 or more network interface resources for the virtual machines. They will belong to the subnet contained in the virtual netowrk and will be attached to the virtual machines.
6. **Public IP address** - The public ip address for the load balancer. This resource will be attached to the load balancer and will be used to access the virtual machines via the load balancer.
7. **Load balancer** - An Azure load balancer resource whose purpose is to distribute traffic evenly to the virtual machines in our cluster based on each virtual machine's load. A front end ip configuration links it to the public ip while a back end address pool configuration configures it to route traffic to the virtual machines via the network interfaces.
8. **Availability set** - This resource provides high availability for the virtual machines by safeguarding them from server reboots, unplanned maintenance and unexpected downtimes.
9. **Disk** - At least 2 disks will be created for each of the virtual machines: A main OS disk where the host operating system will be installed and a managed data disk for additional storage.
10. **Virtual machine** - 2 or more virtual machines that will host the web servers for our application. Network interfaces are attached directly to the virtual machines to allow access to the virtual network while all external access to the virtual machines will be via the load balancer.

*See below sample output of the resources created in Azure:*

![Resources](resources.png?raw=true "Resources")