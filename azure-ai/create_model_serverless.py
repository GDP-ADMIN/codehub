import os
import sys
from azure.ai.ml import MLClient
from azure.identity import ClientSecretCredential
from azure.ai.ml.entities import MarketplaceSubscription, ServerlessEndpoint
from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from dotenv import load_dotenv, set_key

# Load environment variables from the .env file
load_dotenv()

# Load necessary environment variables
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")  # Azure Subscription ID
resource_group_name = os.getenv("AZURE_RESOURCE_GROUP_NAME")  # Azure Resource Group
workspace_name = os.getenv("AZURE_WORKSPACE_NAME")
ml_registry = os.getenv("AZURE_ML_REGISTRY")
model_name = os.getenv("AZURE_LLM_MODEL")
endpoint_name = os.getenv("AZURE_ENDPOINT_NAME")

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

# Setup MLClient with Service Principal credentials
client = MLClient(
    credential=credential,
    subscription_id=f"{subscription_id}",
    resource_group_name=f"{resource_group_name}",
    workspace_name=f"{workspace_name}",
)

model_id = f"{ml_registry}"
subscription_name = f"{model_name}"

# Check if a marketplace subscription is required
if model_id.startswith("azureml://registries/azureml/models/"):
    print("Marketplace subscription not required for this model.")
else:
    try:
        # Check if the marketplace subscription already exists
        marketplace_subscription = client.marketplace_subscriptions.get(subscription_name)
        print(f"Marketplace subscription '{subscription_name}' already exists.")
    except ResourceNotFoundError:
        # Create the marketplace subscription if it doesn't exist
        print(f"Creating marketplace subscription for model '{subscription_name}'...")
        marketplace_subscription = MarketplaceSubscription(
            model_id=model_id,
            name=subscription_name
        )
        marketplace_subscription = client.marketplace_subscriptions.begin_create_or_update(
            marketplace_subscription
        ).result()
        print(f"Created marketplace subscription '{subscription_name}'.")

# Create the serverless endpoint
serverless_endpoint = ServerlessEndpoint(
    name=endpoint_name,
    model_id=model_id
)

created_endpoint = client.serverless_endpoints.begin_create_or_update(
    serverless_endpoint
).result()

# Fetch the keys for the created endpoint
endpoint_keys = client.serverless_endpoints.get_keys(endpoint_name)
endpoint_model_name = client.serverless_endpoints.get(endpoint_name)

print(f"Primary key: {endpoint_keys.primary_key}")
print(f"Secondary key: {endpoint_keys.secondary_key}")
print(f"Endpoint URL: {endpoint_model_name.scoring_uri}")

# Get the directory path from the command-line argument
if len(sys.argv) > 1:
    script_dir = sys.argv[1]
else:
    script_dir = os.getcwd()

# Define the full path to the .env file in the specified directory
env_path = os.path.join(script_dir, ".env")

# Write the primary key and endpoint URL to the .env file
set_key(env_path, "AZURE_ENDPOINT_PRIMARY_KEY", endpoint_keys.primary_key)
set_key(env_path, "AZURE_ENDPOINT_SCORING_URI", endpoint_model_name.scoring_uri)