# This script receives a set of arguments including: run_name, sample_sheet_path, etc.
# and runs the nextflow pipeline by running the bash command: nextflow -C nextflow.config run main.nf --samples_file sample_sheet.csv --outdir "az://nextflow/webapp-runs/$nextflowRunName/pipeline-outputs" -w 'az://work'
# The script also updates the status of the run in the database by calling the update_run_status function in the cosmosdb.
# It also uses the Azure Communication Service to send a notification to the user.

import os
import sys
import subprocess
import json
from azure.identity import DefaultAzureCredential
from azure.cosmos import CosmosClient, exceptions
from azure.communication.email import EmailClient
from azure.mgmt.communication import CommunicationServiceManagementClient
from azure.keyvault.secrets import SecretClient
import logging
import pandas as pd
import uuid
from datetime import datetime
from zoneinfo import ZoneInfo
from azure.storage.blob import BlobServiceClient

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
logger.addHandler(console_handler)

cosmosdb_account_name = os.getenv('COSMOSDB_ACCOUNT_NAME')
database_name = os.getenv('COSMOSDB_DB_NAME')
account_url=f'https://{cosmosdb_account_name}.documents.azure.com:443/'
storage_account_name = os.getenv('STORAGE_ACCOUNT_NAME')

Env = os.getenv('ENVIRONMENT')
kv_name = os.getenv('KEYVAULT_NAME')


pipelineRunsContainerName='PipelineRuns'
samplesContainerName='Samples'
webapp_url = f'sph-genomics-app-{Env}.azurewebsites.net'
# create azure credentials using DefaultAzureCredential
credential = DefaultAzureCredential()
cosmosdb_client = CosmosClient(account_url, credential=credential)
database_client = cosmosdb_client.get_database_client(database_name)
pipelineRunsContainer = database_client.get_container_client(pipelineRunsContainerName)
samplesContainer = database_client.get_container_client(samplesContainerName)

comm_endpoint = f"https://phccc-{Env}-commservice-gen1.canada.communication.azure.com" # os.getenv("COMMUNICATION_SERVICE_ENDPOINT")
comm_client = CommunicationServiceManagementClient(
        credential=credential,
        subscription_id=os.getenv("WEBSITE_OWNER_NAME") if os.getenv("WEBSITE_OWNER_NAME") else "733b7014-09d2-43ed-8c7c-74206482805b",
    )

email_client = EmailClient(comm_endpoint, credential=credential)
emailSenderAddress = "DoNotReply@12be69ab-35c0-4564-bd4a-04a4b15fa99a.azurecomm.net"
emailReceiverAddress = os.getenv("EmailReceiver") if os.getenv("EmailReceiver") else "mahdi.mobini@phsa.ca"
emailSubjectLine = "Nextflow Pipeline Report"

kv_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net", credential=credential)

blob_container_name = 'nextflow'
blob_service_client = BlobServiceClient(account_url=f"https://{storage_account_name}.blob.core.windows.net/", credential=credential)
blob_container_client = blob_service_client.get_container_client(blob_container_name)


def main():
    
    pipelineRunStatus = ''
    sample_sheet=read_sample_sheet("sample_sheet.csv")
    run_name=get_run_same_from_sample_sheet(sample_sheet)
        
    try:
        run_output_path = os.environ.get('OUTPUT_PATH')
        assert run_output_path, "OUTPUT_PATH environment variable is not set."
        
        # pipeline_run_record = create_run_record(run_name, sample_sheet, run_output_path)
        pipelineRunId = os.environ.get('PIPELINE_RUN_ID')
        assert pipelineRunId, "PIPELINE_RUN_ID environment variable is not set."
        
        pipeline_run_record = lookup_pipeline_run(pipelineRunId)
        assert pipeline_run_record, "Pipeline run record not found."
        # create_sample_records(sample_sheet, pipeline_run_record)
        
        STORAGE_ACCOUNT_KEY = kv_client.get_secret("storage-account-key").value
        BATCH_ACCOUNT_KEY = kv_client.get_secret("batch-account-key").value
        ACR_PASSWORD = kv_client.get_secret("acr-password-prd").value
        assert STORAGE_ACCOUNT_KEY, "STORAGE_ACCOUNT_KEY environment variable is not set."
        assert BATCH_ACCOUNT_KEY, "BATCH_ACCOUNT_KEY environment variable is not set."
            
        if Env == 'prd':
            ACR_PASSWORD = kv_client.get_secret("acr-password-prd").value
            assert ACR_PASSWORD, "ACR_PASSWORD environment variable is not set."
        
        if Env == 'prd':
            command = f"nextflow secrets set storageAccountKey {STORAGE_ACCOUNT_KEY} && nextflow secrets set batchAccountKey {BATCH_ACCOUNT_KEY} && nextflow secrets set acrPassword {ACR_PASSWORD}"
        else:
            command = f"nextflow secrets set storageAccountKey {STORAGE_ACCOUNT_KEY} && nextflow secrets set batchAccountKey {BATCH_ACCOUNT_KEY}"
        subprocess.run(command, shell=True, check=True)

        update_run_status(pipeline_run_record, status = "Started")

        command = f"nextflow -C nextflow.config run -w az://nextflow/work main.nf -with-timeline --samples_file sample_sheet.csv --outdir {run_output_path}"
        subprocess.run(command, shell=True, check=True)
        
       
        pipelineRunStatus = 'Succeeded'
        update_run_status(pipeline_run_record, status = pipelineRunStatus)
        # update_samples_status(pipeline_run_record, status = pipelineRunStatus)
        
        subjectline = emailSubjectLine + " - " + str(run_name) + " - " + pipelineRunStatus
        msg = f"Nextflow Pipeline Run {run_name} Succeeded.\nPlease refer to the web app at {webapp_url}/{pipelineRunId}/{run_name} for details.\nResult files are available in the Azure Storage Account under the path: pdhoccdevsadigpath1/nextflow/{run_output_path}."
    
    except Exception as e:
        logger.error(f"An error occurred in running Nextflow:\n {e}")
        pipelineRunStatus = 'Failed'
        update_run_status(pipeline_run_record, status = pipelineRunStatus)
        subjectline = emailSubjectLine + " - " + str(run_name) + " - " + pipelineRunStatus
        msg = f"Nextflow Pipeline Run {run_name} Failed with error: \n{e}\n"
    
    finally:
        logger.info(f"Output path: {run_output_path}")
        # upload the .nextflow.log file to azure blob storage
        blob_container_client.upload_blob(f"{run_output_path.replace('az://nextflow/', '')}/.nextflow.log", open(".nextflow.log", "rb"))
        blob_container_client.upload_blob(f"{run_output_path.replace('az://nextflow/', '')}/sample_sheet.csv", open("sample_sheet.csv", "rb"))

    send_notification(subjectline, msg=msg)

# def update_samples_status(pipeline_run_record, status):
#     # update the status of the samples in the cosmosdb database
#     for sample in pipeline_run_record['Samples']:
#         # download the variant list csv file and read the file into a pd dataframe 
#         # Download the variant list csv file from blob storage
#         variant_list_path = f"{run_output_path.replace('az://nextflow/', '')}/{sample['SampleName']}/annotations/{sample['SampleName']}_variants_long_table.csv"
#         try:
#             blob_data = blob_container_client.download_blob(variant_list_path).readall()
#             variant_df = pd.read_csv(io.BytesIO(blob_data))
#             # Update the sample record with the variant data
#             sample['VariantData'] = variant_df.to_dict(orient='records')
#         except Exception as e:
#             logger.error(f"Error downloading/processing variant list for {sample['SampleName']}: {e}")
#             sample['VariantData'] = []




#         samplesContainer.update_item(item=sample['id'], partition_key=sample['SampleName'], body={'Status': status})

        

def read_sample_sheet(sample_sheet_path):
    # read the sample sheet
    sample_sheet = pd.read_csv(sample_sheet_path)
    return sample_sheet

def get_run_same_from_sample_sheet(sample_sheet):
    # get the run name from the sample sheet
    run_name = sample_sheet.iloc[0]['Run_name']
    return run_name

def create_run_record(run_name, samaple_sheet,run_output_path):
    # create a pipelineRun record in the cosmosdb database
    pipeline_run_record = {
        'id': str(uuid.uuid4()),
        'RunName': str(run_name),
        'SampleSheet': samaple_sheet.to_dict(orient='records'),
        'Status': 'Created',
        'CreateDT': create_time_stamp(),
        'OutputFolderPath': run_output_path,
    }
    pipelineRunsContainer.create_item(pipeline_run_record)
    return pipeline_run_record

def create_time_stamp():
    # create a timestamp in the format: YYYY-MM-DD HH:MM:SS
    return datetime.now(ZoneInfo("America/Los_Angeles")).strftime("%Y-%m-%d %H:%M:%S")


def create_sample_records(sample_sheet, pipeline_run_record):
    # group by sample id and save a comma separated list of input files in the sample sheet
    sample_sheet['input_file'] = sample_sheet.groupby('sample_id')['input_file'].transform(lambda x: ','.join(x))
    sample_sheet = sample_sheet.groupby('sample_id').first().reset_index()
    
    # create sample records in the cosmosdb database Samples container
    for index, row in sample_sheet.iterrows():
        sample_record = {
            'id': str(uuid.uuid4()),
            'SampleId': row['sample_id'],
            'SampleName': row['sample_id'],
            'CID': row['sample_id'].split('_')[1],
            'BARCODE': row['BARCODE'],
            'RunId': pipeline_run_record['id'],
            'RunName': pipeline_run_record['RunName'],
            'Status': 'Created',
            'CreateDT': pipeline_run_record['CreateDT'],
            'InputFiles': row['input_file'],
            'OutputFile': f"{pipeline_run_record['OutputFolderPath']}/{row['sample_id']}/report/{row['sample_id']}.multiqc_report.html",
        }
        samplesContainer.create_item(sample_record)
    

def lookup_sample(sample_id):
    # lookup the sample in the database
    try:
        items = list(samplesContainer.query_items(
            query="SELECT * FROM c WHERE c.SampleId = '%@sample_id%'",
            parameters=[
                {"name": "@sample_id", "value": sample_id}
            ],
            enable_cross_partition_query=True
        ))
        return items
    except exceptions.CosmosResourceNotFoundError:
        return None
    except Exception as e:
        logger.error(e)

def lookup_pipeline_run(run_id):
    # lookup the pipeline run in the database
    try:
        items = list(pipelineRunsContainer.query_items(
            query="SELECT * FROM c WHERE c.id = @run_id",
            parameters=[
                {"name": "@run_id", "value": run_id}
            ],
            enable_cross_partition_query=True
        ))
        # return the first item in the list
        return items[0]
    except exceptions.CosmosResourceNotFoundError:
        return None
    except Exception as e:
        logger.error(e)


def update_run_status(pipeline_run_record, status):
    # update the status of the run in the database
    pipeline_run_record['Status'] = status
    if status == 'Started':
        pipeline_run_record['StartDT'] = create_time_stamp()
    if status in ['Succeeded', 'Failed']:
        pipeline_run_record['EndDT'] = create_time_stamp()
    pipelineRunsContainer.upsert_item(pipeline_run_record)
    
def send_notification(emailSubjectLine, msg):
    try:
        logger.info("Sending email to recipents.")
        message = {
            "senderAddress": emailSenderAddress,
            "recipients":  {
                "to": [{"address": emailReceiverAddress }],
            },
            "content": {
                "subject": emailSubjectLine,
                "plainText": f"{msg}",
            }
        }

        poller = email_client.begin_send(message)
        poller.wait()
        result = poller.result()
        if result['status'] != 'Succeeded':
            raise Exception(f"Failed to send email. Status: {result['status']}")

    except Exception as ex:
        logger.error(f"An error occurred while sending emails:\n {ex}")

if __name__ == '__main__':
    main()
