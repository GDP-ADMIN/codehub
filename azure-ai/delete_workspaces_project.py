import os
from azure.identity import ClientSecretCredential
from azure.ai.ml import MLClient
from azure.core.exceptions import ResourceNotFoundError, HttpResponseError
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

# Load necessary environment variables
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")  # Azure Subscription ID
resource_group_name = os.getenv("AZURE_RESOURCE_GROUP_NAME")  # Azure Resource Group
workspace_name = os.getenv("AZURE_WORKSPACE_NAME")  # Azure Workspace Name

# Load Service Principal credentials from environment variables
client_id = os.getenv("AZURE_CLIENT_ID")
client_secret = os.getenv("AZURE_CLIENT_SECRET")
tenant_id = os.getenv("AZURE_TENANT_ID")

# Authenticate using the Service Principal credentials
credential = ClientSecretCredential(
    client_id=client_id,
    client_secret=client_secret,
    tenant_id=tenant_id
)

# Create the MLClient using Service Principal authentication
ml_client = MLClient(credential, subscription_id, resource_group_name)

# Delete the workspace
try:
    print(f"Attempting to delete the workspace '{workspace_name}' and its dependent resources...")
    delete_operation = ml_client.workspaces.begin_delete(
        name=workspace_name,
        delete_dependent_resources=True  # Ensure dependent resources are also deleted
    )
    delete_operation.result()  # Wait for the operation to complete
    print(f"Workspace '{workspace_name}' and its dependent resources deleted successfully.")
except ResourceNotFoundError:
    print(f"Workspace '{workspace_name}' not found. Skipping deletion.")
except HttpResponseError as e:
    print(f"An HTTP error occurred: {e.message}")
    if e.status_code == 500:
        print("This could be a transient error. Check Azure logs or retry later.")
    else:
        raise
