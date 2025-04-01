# Secured Nextflow Deployment

## Assumptions on Exsisting Resources

Following resources are assumed to exist as part of an Enterprise Landing Zone:

- Virtual Network and peering with the hub or other means of connection to on-premesis network.
- Private Endpints Subnet.
- DNS Zones and Records (for private endpoints).

## Architecture

- Two storage accounts are used:
  - Batch Account Assets
  - Nextflow pipelines' assets and I/O files

- Two Batch Pools are used:
  - Nextflow Runner: small VM for running the nextflow execution commands
  - Pipeline Tteps: larger VMs for running the pipeline tasks

## Steps

- deploy bicep template
- build and push the custom image to ACR
- use "submit_job.py" script to define and submit a batch job to run the nextflow pipeline.

