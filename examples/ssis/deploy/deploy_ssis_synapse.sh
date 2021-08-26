#!/bin/bash 

# Pull in base deploy service names
source ../../../purview_connector_services/deploy/export_names.sh
source ./settings.sh

# Configure Synapse Notebooks and Pipelines

# Data set
az synapse dataset create --workspace-name $synapse_name --name Xml1 --file @../synapse/dataset/Xml1.json >> log_ssis_deploy.txt
az synapse dataset create --workspace-name $synapse_name --name Xml2 --file @../synapse/dataset/Xml2.json >> log_ssis_deploy.txt
az synapse dataset create --workspace-name $synapse_name --name Json1 --file @../synapse/dataset/Json1.json >> log_ssis_deploy.txt

# Notebook
az synapse notebook create --workspace-name $synapse_name  --spark-pool-name notebookrun --name SSIS_Scan_Package --file @../synapse/notebook/SSIS_Scan_Package.ipynb >> log_ssis_deploy.txt
az synapse notebook create --workspace-name $synapse_name  --spark-pool-name notebookrun --name SSISDB_Get_Params --file @../synapse/notebook/SSISDB_Get_Params.ipynb >> log_ssis_deploy.txt

# Gather pipeline data
client_secret_uri=$(az keyvault secret show --name client-secret --vault-name $key_vault_name --query 'id' -o tsv)
sql_con_str_uri=$(az keyvault secret show --name sql-connection-string --vault-name $key_vault_name --query 'id' -o tsv)
storage_account_key_uri=$(az keyvault secret show --name storage-account-key --vault-name $key_vault_name --query 'id' -o tsv)
tag_sql_pwd_uri=$(az keyvault secret show --name vm-password --vault-name $key_vault_name --query 'id' -o tsv)

# Pipeline
echo "Creating SSIS pipeline"
# Build multiple substitutions for pipeline json - note sed can use any delimeter so url changed to avoid conflict with slash char
pipeline_sub="s/<tag_vm_name_or_ip>/$vm_public_ip/;"\
"s/<tag_blob_account_name>/$storage_name/;"\
"s/<tag_key_vault_name>/$key_vault_name/;"\
"s/<tag_vm_user_name>/$vmAdminUserName/;"\
"s@<tag_web_hook_uri>@$web_hook_uri@;"\
"s@<tag_sql_con_str_uri>@$sql_con_str_uri@;"\
"s@<tag_storage_account_key_uri>@$storage_account_key_uri@;"\
"s@<tag_sql_pwd_uri>@$tag_sql_pwd_uri@"
sed $pipeline_sub '../synapse/pipeline/SSIS_Package_Pipeline.json' > '../synapse/pipeline/SSIS_Package_Pipeline-tmp.json'
# Create pipeline in Synapse
az synapse pipeline create --workspace-name $synapse_name --name 'SSIS_Package_Pipeline' --file '@../synapse/pipeline/SSIS_Package_Pipeline-tmp.json' --output none >> log_ssis_deploy.txt
# Delete the tmp json
rm '../synapse/pipeline/SSIS_Package_Pipeline-tmp.json'