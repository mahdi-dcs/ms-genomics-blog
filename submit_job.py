import os
import time
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.batch import BatchServiceClient
from azure.batch.models import (
    PoolInformation, 
    TaskAddParameter, 
    JobAddParameter,
    ResourceFile,
    TaskContainerSettings,
    UserIdentity,
    AutoUserSpecification,
    EnvironmentSetting,
    OnAllTasksComplete
)
import uuid
from azure.core.credentials import TokenCredential
import requests

class BatchTokenCredential(TokenCredential):
    def __init__(self, account_url, token):
        self.account_url = account_url
        self.token = token

    def get_token(self, *scopes, **kwargs):
        return self.token

    def signed_session(self, session=None):
        if session is None:
            session = requests.Session()
        session.headers.update({
            'Authorization': f'Bearer {self.token}'
        })
        return session

# Variables (update these as needed)
RESOURCE_GROUP = os.environ.get('RESOURCE_GROUP')
BATCH_ACCOUNT_URL = os.environ.get('BATCH_ACCOUNT_URL')
BATCH_ACCOUNT_NAME = os.environ.get('BATCH_ACCOUNT_NAME')
POOL_ID = os.environ.get('POOL_ID')
STORAGE_ACCOUNT_NAME = os.environ.get('STORAGE_ACCOUNT_NAME')
AUTOSTORAGE_ACCOUNT_NAME = os.environ.get('AUTOSTORAGE_ACCOUNT_NAME')
KEYVAULT_NAME = os.environ.get('KEYVAULT_NAME')
CONTAINER_NAME = "nextflow"
LOCAL_FOLDER_PATH = os.environ.get('LOCAL_FOLDER_PATH')
MANAGED_IDENTITY_RESOURCE_ID = os.environ.get('MANAGED_IDENTITY_RESOURCE_ID')
OUTPUT_PATH= os.environ.get('OUTPUT_PATH')

def submit_job_to_batch(run_name, output_path, pipeline_run_id):
    print(f"Submitting job to Batch for run {run_name}")
    
    # Create a unique job ID
    job_id = f"{run_name}-{str(uuid.uuid4())}"
    job_id = job_id[:60] if len(job_id) > 60 else job_id
    
    # Create the job
    job = JobAddParameter(
        id=job_id,
        display_name=run_name,
        pool_info=PoolInformation(pool_id=POOL_ID),
        on_all_tasks_complete=OnAllTasksComplete.terminate_job
    )
    
    # Add the job to Batch
    batch_client.job.add(job)
    print(f"Created job {job_id}")
    
    print(f"Loading files from autostorage to Batch for run {run_name}")
    
    # Create resource file for nextflow config
    nf_config_file = ResourceFile(
        auto_storage_container_name="nextflow"
        # blob_prefix="nextflow-pipeline-source"
    )
    
    # Create the task
    nextflow_command = "/bin/bash -c 'python3 run_nextflow.py'"
    
    # Set up container settings
    container_settings = TaskContainerSettings(
        container_run_options="",
        image_name="genomicsacrdev01.azurecr.io/batch-nf:2.0",
        registry={
            "registry_server": "genomicsacrdev01.azurecr.io",
            "identity_reference": {
                "resource_id": MANAGED_IDENTITY_RESOURCE_ID
            }
        }
    )
    
    # Set up user identity
    user_identity = UserIdentity(
        auto_user=AutoUserSpecification(
            elevation_level="admin",
            scope="pool"
        )
    )
    
    # Set up environment settings
    environment_settings = [
        EnvironmentSetting(name="OUTPUT_PATH", value=output_path),
        EnvironmentSetting(name="RUN_NAME", value=run_name),
        EnvironmentSetting(name="PIPELINE_RUN_ID", value=pipeline_run_id),
        EnvironmentSetting(name="STORAGE_ACCOUNT_NAME", value=STORAGE_ACCOUNT_NAME),
        EnvironmentSetting(name="AUTOSTORAGE_ACCOUNT_NAME", value=AUTOSTORAGE_ACCOUNT_NAME),
        EnvironmentSetting(name="KEYVAULT_NAME", value=KEYVAULT_NAME),
        EnvironmentSetting(name="BATCH_ACCOUNT_NAME", value=BATCH_ACCOUNT_NAME),
    ]
    
    # Create the task
    task = TaskAddParameter(
        id=run_name,
        command_line=nextflow_command,
        container_settings=container_settings,
        user_identity=user_identity,
        environment_settings=environment_settings,
        resource_files=[nf_config_file]
    )
    
    print(f"Adding task to job {job_id}")
    batch_client.task.add(job_id=job_id, task=task)
    
    return job_id, task.id

# Authenticate using DefaultAzureCredential
print("Authenticating...")
credential = DefaultAzureCredential()

# Get token for Azure Batch
print("Getting token for Azure Batch...")
batch_token = credential.get_token("https://batch.core.windows.net/")
batch_credential = BatchTokenCredential(BATCH_ACCOUNT_URL, batch_token.token)

# Upload folder to Azure Blob Storage
print("Uploading folder to Azure Blob Storage...")
blob_service_client = BlobServiceClient(
    account_url=f"https://{AUTOSTORAGE_ACCOUNT_NAME}.blob.core.windows.net",
    credential=credential
)

# Ensure the container exists
container_client = blob_service_client.get_container_client(CONTAINER_NAME)
if not container_client.exists():
    container_client.create_container()

# Upload files in the folder
for root, _, files in os.walk(LOCAL_FOLDER_PATH):
    for file in files:
        file_path = os.path.join(root, file)
        blob_name = os.path.relpath(file_path, LOCAL_FOLDER_PATH)
        print(f"Uploading {file_path} as {blob_name}...")
        with open(file_path, "rb") as data:
            container_client.upload_blob(name=blob_name, data=data, overwrite=True)

print(f"Folder uploaded successfully to container '{CONTAINER_NAME}'.")

# Create a Batch job if it doesn't exist
print("Connecting to Azure Batch...")
batch_client = BatchServiceClient(batch_credential, batch_url=BATCH_ACCOUNT_URL)

# Example usage of submit_job_to_batch
job_id, task_id = submit_job_to_batch(
    run_name="test-run",
    output_path=OUTPUT_PATH,
    pipeline_run_id=str(uuid.uuid4())
)

print(f"Job submitted successfully. Job ID: {job_id}, Task ID: {task_id}")