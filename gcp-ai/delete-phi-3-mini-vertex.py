from google.cloud import aiplatform
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Retrieve the environment variables
project_id = os.getenv("GCP_PROJECT_ID")
region = os.getenv("GCP_REGION")
endpoint_id = os.getenv("GCP_ENDPOINT_ID")
model_name = os.getenv("GCP_MODEL_NAME")  # Model name from the environment file

# Initialize the AI Platform with your project and region
aiplatform.init(project=project_id, location=region)

# Function to list deployed models on the endpoint
def list_deployed_models(endpoint_id):
    try:
        print(f"Listing models deployed on endpoint {endpoint_id}...")
        endpoint = aiplatform.Endpoint(endpoint_id)
        
        # List deployed models on the endpoint
        deployed_models = endpoint.list_models()
        
        if deployed_models:
            for model in deployed_models:
                print(f"Deployed Model Display Name: {model.display_name}, Model ID: {model.id}")
                print(f"Model Full Resource Name: {model.model}")
            return deployed_models  # Return list of deployed models
        else:
            print(f"No models deployed on endpoint {endpoint_id}.")
            return None
    except Exception as e:
        print(f"Error listing deployed models: {str(e)}")
        return None

# Function to undeploy a specific model from the endpoint
def undeploy_model_from_endpoint(endpoint_id, model_id):
    try:
        print(f"Undeploying model {model_id} from endpoint {endpoint_id}...")
        endpoint = aiplatform.Endpoint(endpoint_id)
        # Undeploy the specific model version
        endpoint.undeploy(deployed_model_id=model_id)
        print(f"Model {model_id} undeployed successfully.")
    except Exception as e:
        print(f"Error undeploying model: {str(e)}")

# Function to delete the endpoint
def delete_endpoint(endpoint_id):
    try:
        print(f"Deleting endpoint with ID: {endpoint_id}...")
        endpoint = aiplatform.Endpoint(endpoint_id)
        endpoint.delete()
        print(f"Endpoint {endpoint_id} deleted successfully.")
    except Exception as e:
        print(f"Error deleting endpoint: {str(e)}")

# Function to delete a model from the model registry by display name
def delete_model_by_name(model_name):
    try:
        print(f"Searching for model with name: {model_name}...")
        # List all models in the region
        models = aiplatform.Model.list(filter=f'display_name="{model_name}"')

        if models:
            for model in models:
                if model.display_name == model_name:
                    print(f"Model found: {model.display_name} (ID: {model.resource_name})")
                    # Delete the model
                    model.delete()
                    print(f"Model {model.display_name} deleted successfully.")
                    return
            print(f"No model with name {model_name} found.")
        else:
            print(f"No models found in the project.")
    except Exception as e:
        print(f"Error deleting model: {str(e)}")

# First, list the deployed models and retrieve the model ID
deployed_models = list_deployed_models(endpoint_id)

if deployed_models:
    # Use the model ID from the deployed models list
    model_id = deployed_models[0].id  # Assuming there is only one model deployed
    
    # Call the undeploy function
    undeploy_model_from_endpoint(endpoint_id, model_id)
    
    # After undeploying, delete the endpoint
    delete_endpoint(endpoint_id)
else:
    # If no models are deployed, just delete the endpoint
    delete_endpoint(endpoint_id)

# After handling the endpoint, delete the model from the model registry by name
delete_model_by_name(model_name)
