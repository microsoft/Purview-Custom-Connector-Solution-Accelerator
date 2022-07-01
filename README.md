---
page_type: sample
languages:
- python
- bash
products:
- microsoft-purview
- azure-synapse-analytics
---
![Purview Custom Connector Solution Accelerator Banner](./assets/images/pccsa.png)

# Purview Custom Connector Solution Accelerator

Microsoft Purview is a unified data governance service that helps you manage and govern your on-premises, multi-cloud, and software-as-a-service (SaaS) data. Microsoft Purview Data Map provides the foundation for data discovery and effective data governance, however, no solution can support scanning metadata for all existing data sources or lineage for every ETL tool or process that exists today. That is why Purview was built for extensibility using the open Apache Atlas API set. This API set allows customers to develop their own scanning capabilities for data sources or ETL tools which are not yet supported out of the box. This Solution Accelerator is designed to jump start the development process and provide patterns and reusable tooling to help accelerate the creation of Custom Connectors for Microsoft Purview.

The accelerator includes documentation, resources and examples to inform about the custom connector development process, tools, and APIs. It further works with utilities to make it easier to create a meta-model for your connector (Purview Custom Types Tool) with examples including ETL tool lineage as well as a custom data source. It includes infrastructure / architecture to support scanning of on-prem and complex data sources using Azure Synapse Spark for compute and Synapse pipelines for orchestration.

## Applicability

There are multiple ways to integrate with Purview.  Apache Atlas integration (as demonstrated in this Solution Accelerator) is appropriate for most integrations.  For integrations requiring ingestion of a large amount of data into Purview / high scalability, it is recommended to integrate through the [Purview Kafka endpoint](https://docs.microsoft.com/en-us/azure/purview/manage-kafka-dotnet). This will be demonstrated through an example in a future release of this accelerator.

The examples provided demonstrate how the design and services can be used to accelerate the creation of custom connectors, but are not designed to be generic production SSIS or Tag Database connectors. Work will be required to support specific customer use cases.

## Prerequisites

- This solution accelerator is designed to be combined with the [Purview Custom Types Tool SA](https://github.com/microsoft/Purview-Custom-Types-Tool-Solution-Accelerator). Installation of this accelerator is required to run the examples in this accelerator.

## Solution Overview

### Architecture

![Purview Custom Connector Solution Accelerator Design](./assets/images/pccsa-design.svg)

This accelerator uses Azure Synapse for compute and orchestration. Getting and transforming source metadata is done using Synapse notebooks, and is orchestrated and combined with other Azure Services using Synapse pipelines. Once a solution is developed (see development process below) running the solution involves the following steps:

1. Scan of custom source is triggered through Synapse pipeline
2. Custom source notebook code pulls source data and transforms into Atlas json - predefined custom types
3. Data is written into folder in ADLS
4. Data write triggers Purview Entity import notebook pipeline
5. Scan data is written into Purview

### Connector Development Process

![pccsa_dev_processing.svg](./assets/images/pccsa_dev_process.svg)

#### Determine data available from custom source

The first step in the development process is to determine what metadata is available for the target source, and how to access the metadata. This is a foundational decision and there are often a number of considerations. Some sources might have readily accessible meta-data that can be queried through an API, others may have various file types that need to be transformed and parsed. Some sources require deep access to the virtual machine or on prem server requiring some type of agent (see the SSIS example). For some it might make sense to use the source logs as the meta-data to distinguish between what is defined in a transformation document, and what has been actually applied to the data. For examples of this process, see the [SSIS Meta-data](./examples/ssis/ssis.md#pull-ssis-meta-data) and [Tag DB Meta-data](./examples/tag_db/tag_db.md#pull-tag-db-meta-data) examples.

#### Define types for custom source

Purview uses Apache Atlas defined types which allows for inter-connectivity with existing management tools and a standardized way to define source types. After determining what meta-data is available for the particular source, the next step is how to represent that data in Purview using Atlas types. This step is called defining the meta-model and there are multiple ways this can be accomplished depending on the metadata source, and the desired visualization of the information. It is easy to derive new types from existing ones, ore create types from scratch using the [Purview Custom Type Tool](https://github.com/microsoft/Purview-Custom-Types-Tool-Solution-Accelerator). The examples in this accelerator make use of this tool to define their meta-models (see [SSIS Meta-model](./examples/ssis/ssis.md#define-the-ssis-meta-model), and [Tag DB Meta-model](./examples/tag_db/tag_db.md#define-the-tag-db-meta-model))

#### Develop script for translation of source entity data to purview entities / lineage

Meta-data parsing is one of the more time consuming aspects of Purview Custom Connector development. It is also an activity which, by its nature, is very bespoke to the particular data source targeted. The parsing examples are provided to illustrate how parsers can be plugged into the solution, and the use of generic Purview templates based on the meta-model types to transform the metadata. There are also some libraries and tools such as [Apache Tika](https://tika.apache.org/) which may be helpful for parsing certain kinds of metadata. Parsing examples can be found here: [SSIS Parsing](./examples/ssis/ssis.md#parsing-the-ssis-package), [Tag DB Parsing](./examples/tag_db/tag_db.md). The resulting entity definition file is passed to the [Purview Connector Services](./purview_connector_services/purview_connector_services.md) for ingestion into Purview.

#### Define pipeline and triggers for source connection

All of the above activities are orchestrated through a Synapse pipeline. The [SSIS Pipeline](./examples/ssis/ssis.md#define-the-ssis-pipeline) demonstrates a complex example designed to mimic what is found in real customer scenarios. The [Tag DB](./examples/tag_db/tag_db.md) example focuses more on the meta-modeling and Purview visualization of the data.

Using Synapse pipelines and Spark pools for connector development offers a number of advantages including:

* UI view of pipeline and parameters allowing operators to run and configure pipelines and view results in a standardized way
* Built in support for logging
* Built in scalability by running jobs in a Spark Cluster

## Getting Started

### Deploy Resources / Configuration

#### Deploy Base Services

Instructions for deploying the base connector services, which includes deployment of Synapse, Purview, and Synapse notebooks and pipelines for ingesting custom types into Purview can be found in the [Base Services Deployment Doc](./purview_connector_services/deploy/deploy_sa.md)

#### Deploy the Purview Custom Types Tool

To setup and run the example connectors, you will need to install the [Purview Custom Type Tool](https://github.com/microsoft/Purview-Custom-Types-Tool-Solution-Accelerator). This should be done after the creation of the Application Security Principle and the Purview instance it will connect to (as part of Base Service deployment). The security principle information and Purview instance are required to initialize the tool.

#### Deploy Examples

Deploying the example connectors requires running a script from the Cloud Command Shell, along with some manual steps for the more involved SSIS example.  Detailed steps can be found in the following documents:
* [ETL Tool Lineage (SSIS) Example Deployment](./examples/ssis/deploy/deploy_ssis.md)
* [Data Source (Tag DB) Example Deployment](./examples/tag_db/deploy/deploy_tag_db.md)

### Run Example Connectors

For Steps to run the example connectors, please see the example connector documentation ([SSIS](./examples/ssis/ssis.md#running-the-example-solution), [Tag DB](./examples/tag_db/tag_db.md#running-the-example-solution))

## Purview Development Resources

* [Tutorial](https://docs.microsoft.com/en-us/azure/purview/tutorial-using-rest-apis) on using the REST API in MS Docs
API [methods supported by Purview](https://docs.microsoft.com/en-us/azure/purview/tutorial-using-rest-apis#view-the-rest-apis-documentation)
* PyApacheAtlas
[training video](https://www.youtube.com/watch?v=4qzjnMf1GN4) and [code samples](https://github.com/wjohnson/pyapacheatlas/tree/master/samples)
[PyApacheAtlas SDK](https://pypi.org/project/pyapacheatlas/), [Docs](https://wjohnson.github.io/pyapacheatlas-docs/latest/)
* [CLI wrapper to REST API](https://github.com/tayganr/purviewcli)
Documentation​​​​​​​ and notebook samples

## Note about Libraries with MPL-2.0 and LGPL-2.1 Licenses

The following libraries are not **explicitly included** in this repository, but users who use this Solution Accelerator may need to install them locally and in Azure Synapse to fully utilize this Solution Accelerator. However, the actual binaries and files associated with the libraries **are not included** as part of this repository, but they are available for installation via the PyPI library using the pip installation tool.

## Contributing
This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks
This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
