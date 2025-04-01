import os
import time
from azure.identity import ManagedIdentityCredential
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.batch import BatchServiceClient
from azure.batch.models import PoolInformation, TaskAddParameter, JobAddParameter
import uuid

# Variables (update these as needed)
RESOURCE_GROUP = os.environ.get('RESOURCE_GROUP')
BATCH_ACCOUNT_URL = os.environ.get('BATCH_ACCOUNT_URL')
POOL_ID = os.environ.get('POOL_ID')
BATCH_JOB_ID = str(uuid.uuid4())

STORAGE_ACCOUNT = os.environ.get('STORAGE_ACCOUNT')
CONTAINER_NAME = "nextflow"

LOCAL_FOLDER_PATH = os.environ.get('LOCAL_FOLDER_PATH')

# Authenticate using the managed identity
print("Authenticating using the managed identity...")
# credential = ManagedIdentityCredential()
credential = DefaultAzureCredential()
# Upload folder to Azure Blob Storage
print("Uploading folder to Azure Blob Storage...")
blob_service_client = BlobServiceClient(
    account_url=f"https://{STORAGE_ACCOUNT}.blob.core.windows.net",
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
batch_client = BatchServiceClient(credential, batch_url=BATCH_ACCOUNT_URL)

print(f"Checking if Batch job '{BATCH_JOB_ID}' exists...")
try:
    batch_client.job.get(BATCH_JOB_ID)
    print(f"Batch job '{BATCH_JOB_ID}' already exists.")
except:
    print(f"Creating Batch job '{BATCH_JOB_ID}'...")
    job = JobAddParameter(
        id=BATCH_JOB_ID,
        pool_info=PoolInformation(pool_id=POOL_ID)
    )
    batch_client.job.add(job)
    print(f"Batch job '{BATCH_JOB_ID}' created successfully.")

# Submit a task to the Batch job
print(f"Submitting task to Batch job '{BATCH_JOB_ID}'...")
task_id = f"task-{int(time.time())}"  # Unique task ID based on timestamp
task = TaskAddParameter(
    id=task_id,
    command_line="/bin/bash -c 'echo Hello, Azure Batch! && ls'",
    # application_package_references=[
    #     {"application_id": AZURE_BATCH_APP_PACKAGE.split("#")[0], "version": AZURE_BATCH_APP_PACKAGE.split("#")[1]}
    # ]
)
batch_client.task.add(job_id=BATCH_JOB_ID, task=task)
print(f"Task '{task_id}' submitted successfully to job '{BATCH_JOB_ID}'.")

print("Script execution completed successfully.")