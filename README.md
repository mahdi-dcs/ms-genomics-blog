# Secured Nextflow Deployment

## Architecture

![architecture](docs/Genomics-NF-Arch-ms-blog.drawio.png)

- Two storage accounts are deployed and used for:
  - Pipelines' assets and source code: hierarchial namespace (HNS) is disabled for this storage account to be able to enable versioning on the pipeline assets.
  - Nextflow references and I/O files: ADLS Gen2 is used to allow for enabling file-level access controls.

- Two Batch Pools are used:
  - Nextflow Runners: small VM for running the nextflow execution commands
  - Pipeline Runners: larger VMs for running the pipeline tasks

## Assumptions on Exsisting Resources

Following resources are assumed to exist as part of an Enterprise Landing Zone and not included in the bicep templates:

- Virtual Network and peering with the hub or other means of connection to on-premesis network.
- Private Endpints Subnet.
- DNS Zones and Records for private endpoints.

For a complete deployment of Secured Batch see for example: [Batch Accelerator](https://github.com/Azure/bacc).

## Deployment Steps

- login to Azure
  
  ```s
  az login
  
  ```

- create a resource group
  
  ```s
  export RESOURCE_GROUP_NAME="genomics-nf-blog"
  export LOCATION="canadacentral"
  az group create --name $RESOURCE_GROUP_NAME --location $LCOATION
  ```

- modify the default values of the parameters and deploy the [bicep template](infra/main.bicep) template:

  ```s
  az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file infra/main.bicep
  
  ```

- build and push the custom image to ACR
  
  The [Dockerfile](Dockerfile) is used to build a custom image built from the official nextflow image plus the required python libraries. This image will be used by the Nextflow headnodes to run the pipelines.

  ```s
  export ACR_NAME="genomicsacrdev01"
  export IMAGE_NAME="nf-batch"
  export IMAGE_TAG="1.0"
  export IMAGE_TAG="$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"

  az acr login --name $ACR_NAME
  docker build . -t $IMAGE_TAG
  docker push $IMAGE_TAG
  ```

- use [submit_job.py](submit_job.py) script to upload nextflow pipeline codes, and define and submit a batch job to run the pipeline.
  - Blob Data Contributor/Owner role is required to run this script.

## Git Action

A git action is setup using the [deploy-infrastructure.yaml](.github/workflows/deploy-infrastructure.yaml).

- To use this Git Action, a self-hosted runner within the network (on Azure or on-premesis) is required.
- Set up the credentials in Github secrets following the [documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI%2Copenid#generate-deployment-credentials).
- The deployment pipeline can be triggered by a push commit or manually from the Github website.

## Improvement Opportunities

- Use managed identity in Nextflow Config instead of secrets.
