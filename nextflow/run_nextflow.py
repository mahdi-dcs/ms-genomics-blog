# This script runs the nextflow pipeline by reading the secrets from kv and then running the bash command: 
#      nextflow -C nextflow.config run main.nf --samples_file sample_sheet.csv --outdir "az://nextflow/webapp-runs/$nextflowRunName/pipeline-outputs" -w 'az://work'

import os
import subprocess
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import logging
import pandas as pd
from datetime import datetime
from zoneinfo import ZoneInfo
from azure.storage.blob import BlobServiceClient

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
logger.addHandler(console_handler)

storage_account_name = os.getenv('STORAGE_ACCOUNT_NAME')

Env = os.getenv('ENVIRONMENT')
kv_name = os.getenv('KEYVAULT_NAME')
run_output_path = os.getenv('OUTPUT_PATH')


# create azure credentials using DefaultAzureCredential
credential = DefaultAzureCredential()

kv_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net", credential=credential)

blob_container_name = 'nextflow'
blob_service_client = BlobServiceClient(account_url=f"https://{storage_account_name}.blob.core.windows.net/", credential=credential)
blob_container_client = blob_service_client.get_container_client(blob_container_name)


def main():
    
    try:
        assert run_output_path, "OUTPUT_PATH environment variable is not set."
        
        STORAGE_ACCOUNT_KEY = kv_client.get_secret("storage-account-key").value
        BATCH_ACCOUNT_KEY = kv_client.get_secret("batch-account-key").value
        assert STORAGE_ACCOUNT_KEY, "STORAGE_ACCOUNT_KEY environment variable is not set."
        assert BATCH_ACCOUNT_KEY, "BATCH_ACCOUNT_KEY environment variable is not set."
            
        ACR_PASSWORD = kv_client.get_secret("acr-password-dev").value
        assert ACR_PASSWORD, "ACR_PASSWORD environment variable is not set."
        
        command = f"nextflow secrets set storageAccountKey {STORAGE_ACCOUNT_KEY} && nextflow secrets set batchAccountKey {BATCH_ACCOUNT_KEY} && nextflow secrets set acrPassword {ACR_PASSWORD}"
        subprocess.run(command, shell=True, check=True)

        command = f"nextflow -C nextflow.config run -w az://nextflow/work main.nf -with-timeline --samples_file sample_sheet.csv --outdir {run_output_path}"
        subprocess.run(command, shell=True, check=True)
       
    except Exception as e:
        logger.error(f"An error occurred in running Nextflow:\n {e}")
    
    # finally:
        # logger.info(f"Output path: {run_output_path}")
        # upload the .nextflow.log file to azure blob storage
        # blob_container_client.upload_blob(f"{run_output_path.replace('az://nextflow/', '')}/.nextflow.log", open(".nextflow.log", "rb"))
        # blob_container_client.upload_blob(f"{run_output_path.replace('az://nextflow/', '')}/sample_sheet.csv", open("sample_sheet.csv", "rb"))

def read_sample_sheet(sample_sheet_path):
    # read the sample sheet
    sample_sheet = pd.read_csv(sample_sheet_path)
    return sample_sheet

def get_run_same_from_sample_sheet(sample_sheet):
    # get the run name from the sample sheet
    run_name = sample_sheet.iloc[0]['Run_name']
    return run_name

def create_time_stamp():
    # create a timestamp in the format: YYYY-MM-DD HH:MM:SS
    return datetime.now(ZoneInfo("America/Los_Angeles")).strftime("%Y-%m-%d %H:%M:%S")

if __name__ == '__main__':
    main()
