import os
from azure.identity import ClientSecretCredential
from azure.ai.ml import MLClient
from azure.core.exceptions import ResourceNotFoundError
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

# Load necessary environment variables
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")  # Azure Subscription ID
resource_group_name = os.getenv("AZURE_RESOURCE_GROUP_NAME")  # Azure Resource Group
workspace_name = os.getenv("AZURE_WORKSPACE_NAME")  # Azure Workspaces Name
endpoint_name = os.getenv("AZURE_ENDPOINT_NAME")  # Serverless API Endpoint Name
subscription_name = os.getenv("AZURE_LLM_MODEL")  # Model subscription name

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
ml_client = MLClient(credential, subscription_id, resource_group_name, workspace_name)

# Delete the serverless API endpoint
# Delete the associated model subscription
try:
    print(f"Attempting to delete the model subscription '{subscription_name}'...")
    delete_operation = ml_client.marketplace_subscriptions.begin_delete(subscription_name)
    delete_operation.wait()
    print(f"Model subscription '{subscription_name}' deleted successfully.")
except ResourceNotFoundError:
    print(f"Model subscription '{subscription_name}' not found. Skipping deletion.")
except HttpResponseError as e:
    # Handle HTTP response errors explicitly
    if e.status_code == 500:
        print(f"Received status 500 for the operation. The model subscription might have been successfully deleted despite the error.")
    else:
        print(f"An HTTP error occurred: {e}")
        raise