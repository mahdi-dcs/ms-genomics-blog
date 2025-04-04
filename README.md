# Secured Nextflow Deployment

## Assumptions on Exsisting Resources

Following resources are assumed to exist as part of an Enterprise Landing Zone:

- Virtual Network and peering with the hub or other means of connection to on-premesis network.
- Private Endpints Subnet.
- DNS Zones and Records (for private endpoints).

## Architecture

- Two storage accounts are deployed and used for:
  - Pipelines' assets and source code
  - Nextflow references and I/O files

- Two Batch Pools are used:
  - Nextflow Runner: small VM for running the nextflow execution commands
  - Pipeline Tteps: larger VMs for running the pipeline tasks

## Steps

- set environment variables

  ```s
  RESOURCE_GROUP_NAME="<resourcegroupname>"
  
  ACR_NAME="<registryname>"
  IMAGE_NAME="nf-batch"
  IMAGE_TAG="1.0"
  IMAGE_TAG="$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"
  ```

- login to Azure
  
  ```s
  az login
  
  ```

- deploy bicep template

  ```s
  az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file infra/main.bicep
  
  ```

- build and push the custom image to ACR

  ```s
  az acr login --name $ACR_NAME
  docker build . -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG
  docker push registryname.azurecr.io/batch-nf:1.0
  ```

- use "submit_job.py" script to upload input fastq files, and then define and submit a batch job to run the nextflow pipeline.
  - Blob Data Contributor/Owner role is required to run this script.
  - 

