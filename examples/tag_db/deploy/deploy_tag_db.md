# Deploy Tag Database Source Example

## Components

![PCCSA Block Diagram](../../../assets/images/osi_pi_deploy_blocks.svg)

## Prerequisite

Follow the instructions for deploying the base solution under [purview_connector_services](../../../purview_connector_services/deploy/deploy_sa.md)

## Run Installation Script

* start the cloud CLI in bash mode
* cd to the cloud storage directory (clouddrive)
* navigate to the PurviewACC/examples/tag_db/deploy directory 
* run './deploy_tag_db.sh'

## Reference - script actions

* Sets up the blob storage directory structure for the Tag DB example
* In Synapse
  * Imports dataset definitions
  * Imports the notebook
  * Imports the pipeline definitions
