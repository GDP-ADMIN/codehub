import os
from azure.ai.ml import MLClient
from azure.identity import ClientSecretCredential
from azure.ai.ml.entities import Hub
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Load necessary environment variables
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
resource_group_name = os.getenv("AZURE_RESOURCE_GROUP_NAME")
location_name = os.getenv("AZURE_LOCATION")
hub_name = os.getenv("AZURE_WORKSPACE_HUB")

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

# get a handle to the subscription using Service Principal authentication
ml_client = MLClient(credential, subscription_id, resource_group_name)

# Create Azure AI HUB
my_hub_name = hub_name
my_location = location_name
my_display_name = hub_name

# Construct a basic hub
my_hub = Hub(
    name=my_hub_name,
    location=my_location,
    display_name=my_display_name
)

# Create the hub
created_hub = ml_client.workspaces.begin_create(my_hub).result()

print(f"Hub '{my_hub_name}' created successfully.")