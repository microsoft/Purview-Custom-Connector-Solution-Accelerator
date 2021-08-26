#!/bin/bash 

# dynamically load missing az dependancies without prompting
az config set extension.use_dynamic_install=yes_without_prompt --output none

# This script requires contributor and user access administrator permissions to run
source ../../../purview_connector_services/deploy/export_names.sh

# To run in Azure Cloud CLI, comment this section out
# az login --output none
# az account set --subscription "Early Access Engineering Subscription" --output none

# Upload storage folders and data
# Create storage dir structure
echo "Create storage folders"
mkdir tag-db-connector; cd tag-db-connector; mkdir tag-db-json; touch ./tag-db-json/tmp; mkdir tag-db-processed;\
touch ./tag-db-processed/tmp; mkdir tag-db-purview-json; touch ./tag-db-purview-json/tmp; mkdir tag-db-xml;\
touch ./tag-db-xml/tmp; cd ..
# Upload dir structure to storage
az storage fs directory upload -f pccsa --account-name $storage_name -s ./tag-db-connector -d ./pccsa_main --recursive --output none
# Remove tmp directory structure
rm -r tag-db-connector

# Upload sample data
az storage fs file upload -f pccsa --account-name $storage_name -s ../example_data/tag-db-xml-sample.xml -p ./pccsa_main/tag-db-connector/tag-db-xml/tag-db-xml-sample.xml --auth-mode login

# Configure Synapse Notebooks and Pipelines

# Data set
echo "Creating TAG_DB Datasets"
az synapse dataset create --workspace-name $synapse_name --name TAG_DB_JSON --file @../synapse/dataset/TAG_DB_JSON.json
az synapse dataset create --workspace-name $synapse_name --name TAG_DB_Metadata_XML --file @../synapse/dataset/TAG_DB_Metadata_XML.json

# Notebook
echo "Creating Purview TAG_DB Scan Notebook"
az synapse notebook create --workspace-name $synapse_name --spark-pool-name notebookrun --name Purview_TAG_DB_Scan --file @../synapse/notebook/Purview_TAG_DB_Scan.ipynb

# Pipeline
echo "Creating TAG_DB pipeline"
# Build substitutions for pipeline json - note sed can use any delimeter so url changed to avoid conflict with slash char
pipeline_sub="s@<tag_storage_account>@$storage_name@"
sed $pipeline_sub '../synapse/pipeline/Converte TAG DB XML Metadata to Json.json' > '../synapse/pipeline/Converte TAG DB XML Metadata to Json-tmp.json'
# Create pipeline in Synapse
az synapse pipeline create --workspace-name $synapse_name --name 'Converte TAG DB XML Metadata to Json' --file '@../synapse/pipeline/Converte TAG DB XML Metadata to Json-tmp.json' --debug
# Delete the tmp json
rm '../synapse/pipeline/Converte TAG DB XML Metadata to Json-tmp.json'