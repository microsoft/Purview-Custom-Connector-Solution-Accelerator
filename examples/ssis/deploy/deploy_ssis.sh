#!/bin/bash 

# dynamically load missing az dependancies without prompting
az config set extension.use_dynamic_install=yes_without_prompt --output none

# This script requires contributor and user access administrator permissions to run
source ../../../purview_connector_services/deploy/export_names.sh
source ./settings.sh

# To run in Azure Cloud CLI, comment this section out
# az login --output none
# az account set --subscription "Early Access Engineering Subscription" --output none

# Upload storage folders and data
# Create storage dir structure
echo "Create storage folders"
mkdir ssis-connector; cd ssis-connector; mkdir execution-id; touch ./execution-id/tmp; mkdir ssis-package;\
touch ./ssis-package/tmp; mkdir ssis-type-templates; touch ./ssis-type-templates/tmp; mkdir working;\
touch ./working/tmp; mkdir example-data; touch ./example-data/tmp; cd ..
# Upload dir structure to storage
az storage fs directory upload -f pccsa --account-name $storage_name -s ./ssis-connector -d ./pccsa_main --recursive --output none >> log_ssis_deploy.txt
# Remove tmp directory structure
rm -r ssis-connector
# Create public script container
az storage container create --account-name $storage_name -n scripts --public-access blob >> log_ssis_deploy.txt
az storage fs file upload -f scripts --account-name $storage_name -s ../scripts/powershell_loop_script.ps1 -p ./powershell_loop_script.ps1 --auth-mode login >> log_ssis_deploy.txt

# upload example data
az storage fs file upload -f pccsa --account-name $storage_name -s ../example_data/MovCustomers.csv -p ./pccsa_main/ssis-connector/example-data/MovCustomers.csv --auth-mode login >> log_ssis_deploy.txt

# upload templates
az storage fs file upload -f pccsa --account-name $storage_name -s ../meta_model/example_templates/legacy_ssis_package_process_template.json -p ./pccsa_main/ssis-connector/ssis-type-templates/legacy_ssis_package_process_template.json --auth-mode login
az storage fs file upload -f pccsa --account-name $storage_name -s ../meta_model/example_templates/legacy_ssis_package_template.json -p ./pccsa_main/ssis-connector/ssis-type-templates/legacy_ssis_package_template.json --auth-mode login

# deploy automation
echo "deploy log analytics and automation"
# upload secrets to keyvault
az keyvault secret set --vault-name $key_vault_name --name vm-password --value $vm_password --output none >> log_ssis_deploy.txt
# setup service names
ps_loopscript_location="https://$storage_name.blob.core.windows.net/scripts/powershell_loop_script.ps1"
automationName=$prefix"automation"$suffix
logAnalyticsName=$prefix"loganalytics"$suffix
runbookName=$prefix"runbook"$suffix
webhookName=$prefix"webhook"$suffix
vmCredsName=$prefix"vmcreds"$suffix
# get keyvault reference
refid_keyvault="/subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.KeyVault/vaults/$key_vault_name"
# setup params
params="{\"ps_loopscript_location\":{\"value\":\"$ps_loopscript_location\"},"\
"\"automationName\":{\"value\":\"$automationName\"},"\
"\"logAnalyticsName\":{\"value\":\"$logAnalyticsName\"},"\
"\"vmAdminUserName\":{\"value\":\"$vmAdminUserName\"},"\
"\"vmCredsName\":{\"value\":\"$vmCredsName\"},"\
"\"runbookName\":{\"value\":\"$runbookName\"},"\
"\"webhookName\":{\"value\":\"$webhookName\"},"\
"\"vmAdminPassword\":{\"reference\":{\"keyVault\":{\"id\":\"$refid_keyvault\"},\"secretName\":\"vm-password\"}}}"
# deploy - hybrid runbook worker group must be manually configured: https://docs.microsoft.com/en-us/azure/automation/automation-windows-hrw-install#manual-deployment
web_hook_uri=$(az deployment group create --resource-group $resource_group --parameters $params --template-file ./arm/deploy_automation.json --query properties.outputs.webhookUri.value)

# deploy vm networking
echo "deploy vm networking"
# setup service names
publicIpAddressName=$prefix"pubip"$suffix
networkSecurityGroupName=$prefix"nsg"$suffix
networkInterfaceName=$prefix"nic"$suffix
vnetName=$prefix"vnet"$suffix
subnetName=$prefix"subnet"$suffix
# setup params
params="{\"publicIpAddressName\":{\"value\":\"$publicIpAddressName\"},"\
"\"networkSecurityGroupName\":{\"value\":\"$networkSecurityGroupName\"},"\
"\"networkInterfaceName\":{\"value\":\"$networkInterfaceName\"},"\
"\"vnetName\":{\"value\":\"$vnetName\"},"\
"\"subnetName\":{\"value\":\"$subnetName\"}}"
# deploy
az deployment group create --resource-group $resource_group --parameters $params --template-file ./arm/deploy_vm_networking.json --output none >> log_ssis_deploy.txt

# deploy sql server vm
echo "deploy sql server vm"
# setup service names
vm_name=$prefix"vm"$suffix
# vm name cannot be more than 15 chars long
vm_name=${vm_name:0:15}

# Get workspace info for vm extension
workspace_id=$(az monitor log-analytics workspace show --resource-group $resource_group --workspace-name $logAnalyticsName --query customerId -o tsv)
workspace_key=$(az monitor log-analytics workspace get-shared-keys --resource-group $resource_group --workspace-name $logAnalyticsName --query primarySharedKey -o tsv)
# setup service names
existingSubnetName=$vnetName/$subnetName
# setup params
params="{\"workSpaceId\":{\"value\":\"$workspace_id\"},"\
"\"workSpaceIdKey\":{\"value\":\"$workspace_key\"},"\
"\"virtualMachineName\":{\"value\":\"$vm_name\"},"\
"\"existingVirtualNetworkName\":{\"value\":\"$vnetName\"},"\
"\"existingSubnetName\":{\"value\":\"$subnetName\"},"\
"\"adminUsername\":{\"value\":\"$vmAdminUserName\"},"\
"\"adminPassword\":{\"reference\":{\"keyVault\":{\"id\":\"$refid_keyvault\"},\"secretName\":\"vm-password\"}}}"
# deploy
az deployment group create --resource-group $resource_group --parameters $params --template-file ./arm/deploy_sql_server_vm.json --output none >> log_ssis_deploy.txt

# Azure VM info
vm_public_ip=$(az vm show -d -g $resource_group -n $vm_name --query publicIps -o tsv)
sql_con_str="data source = localhost; initial catalog = SSISDB; trusted_connection = true; user id = $vmAdminUserName; password = $vm_password"

az keyvault secret set --vault-name $key_vault_name --name "sql-connection-string" --value "$sql_con_str" --output none >> log_ssis_deploy.txt

echo vm_name=$vm_name >> ../../../purview_connector_services/deploy/export_names.sh
echo web_hook_uri=$web_hook_uri >> ../../../purview_connector_services/deploy/export_names.sh
echo vm_public_ip=$vm_public_ip >> ../../../purview_connector_services/deploy/export_names.sh

# Enable log analytics agent for hybrid automation runbook
az monitor log-analytics workspace pack enable --name AzureAutomation --resource-group $resource_group --workspace-name $logAnalyticsName >> log_ssis_deploy.txt

./deploy_ssis_synapse.sh

