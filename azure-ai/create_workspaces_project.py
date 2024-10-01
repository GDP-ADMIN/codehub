import os
from azure.identity import ClientSecretCredential
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Project
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

# Load necessary environment variables or replace with actual values
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")  # Azure Subscription ID
resource_group_name = os.getenv("AZURE_RESOURCE_GROUP_NAME")  # Azure Resource Group
workspace_name = os.getenv("AZURE_WORKSPACE_NAME")  # Azure Workspaces Name
workspace_hub = os.getenv("AZURE_WORKSPACE_HUB")  # Azure Workspaces Hub
location_name = os.getenv("AZURE_LOCATION")  # Azure Region Location

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

# Create the project details
project_name = workspace_name
location_name = location_name
display_name = workspace_name
hub_id = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_hub}"

# Create the Project entity
my_project = Project(
    name=workspace_name,
    location=location_name,
    display_name=display_name,
    hub_id=hub_id
)

# Create the workspace project
created_project = ml_client.workspaces.begin_create(workspace=my_project).result()

print(f"Workspace {workspace_name} created successfully.")