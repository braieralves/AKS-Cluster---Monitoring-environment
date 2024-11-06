#!/bin/bash

#  Script created by Braier Alexandre.
#  The purpose of this script is to automate a complete environment for Container Insights testing.
#  Resources created by this script: - Resource Group in "East US 2" region - Log Analytics Workspace 
#  - Azure Monitor Workspace (Managed Prometheus) 
#   - Managed Grafana 
#   - AKS cluster enabled Container Insights, managed Prometheus and Managed Grafana 
#   - DCRs for Container Insights and Managed Prometheus

########################################################################################################

# How to use this script
# 1 - Access Azure Portal > Cloud Shell > Bash 
# 2 - Create a file called "aks-monitoring.sh" - Command "nano aks-monitoring.sh"
# 3 - Copy the content of this script
# 4 - Paste the copied content in the file "aks-monitoring.sh"
# 5 - Give teh execution permission to the file "aks-monitoring.sh" - Command "chmod +x aks-monitoring.sh"
# 6 - Execute the script with command "sh aks-monitoring.sh"
# 7 - Inform the names of the resources

# This take some minutes to create the complete environment

########################################################################################################

# Script execution start!!!!

# Choose resources names
echo "Choose the Resource Group name"
read rg_name

echo "Choose the AKS name"
read aks_name

echo "Choose the Log Analytics Workspace name"
read law_name

echo "Choose the Managed Prometheus name"
read amw_name

echo "Choose the Managed Grafana name"
read amg_name


# Create a New Resource Group in East US 2
az group create --name $rg_name --location eastus2

# Create a Log Analytics Workspace in the New Resource Group
az monitor log-analytics workspace create --resource-group $rg_name --workspace-name $law_name --location eastus2

# Create a Managed Prometheus (Azure monitor Workspace) in the New Resource Group
az monitor account create --resource-group $rg_name --name $amw_name --location eastus2

# Create a Managed Grafana in the New Resource Group
az grafana create --resource-group $rg_name --workspace-name $amg_name --sku-tier Standard --public-network-access Enabled --location eastus2

# Create an AKS Cluster in the New Resource Group with Monitoring addon Enabled

# The first command retrieves the ID of a specified Log Analytics workspace and stores it in the workspaceId variable.
workspaceId=$(az monitor log-analytics workspace show --resource-group $rg_name --workspace-name $law_name --query id -o tsv)

# The second command creates an AKS cluster with monitoring enabled, linking it to the Log Analytics workspace using the retrieved ID. This setup integrates Azure Monitor for containers with the AKS cluster.
az aks create --resource-group $rg_name --name $aks_name --node-count 1 --enable-addons monitoring --generate-ssh-keys --workspace-resource-id $workspaceId

# The third command retrieves the ID of a specified Managed Prometheus and stores it in the workspaceId variable.
prometheusId=$(az monitor account show --resource-group $rg_name -n $amw_name --query id -o tsv)

# The fourth command retrieves the ID of a specified Managed Grafana and stores it in the workspaceId variable.
grafanaId=$(az grafana show --resource-group $rg_name -n $amg_name --query id -o tsv)

# The fifth update the AKS cluster to be monitored by Managed Prometheus and Managed Grafana
az aks update --enable-azure-monitor-metrics --name $aks_name --resource-group $rg_name --azure-monitor-workspace-resource-id $prometheusId --grafana-resource-id $grafanaId


