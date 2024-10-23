from google.cloud import aiplatform
from dotenv import load_dotenv, set_key
import os

# Load environment variables from .env file
load_dotenv()

# Print the environment variable to ensure it's set
google_credentials = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
if not google_credentials:
    raise ValueError("GOOGLE_APPLICATION_CREDENTIALS is not set!")
else:
    print(f"GOOGLE_APPLICATION_CREDENTIALS is set to: {google_credentials}")

# Retrieve the environment variables
project_id = os.getenv("GCP_PROJECT_ID")
print(f"Using project ID: {project_id}")
region = os.getenv("GCP_REGION")
VLLM_DOCKER_URI = os.getenv("GCP_VLLM_DOCKER_URI")
model_name = os.getenv("GCP_MODEL_NAME")
model_id = os.getenv("GCP_MODEL_ID")
machine_type = os.getenv("GCP_MACHINE_TYPE")
accelerator_type = os.getenv("GCP_ACCELERATOR_TYPE")
accelerator_count = int(os.getenv("GCP_ACCELERATOR_COUNT"))

# Initialize the AI Platform with your project and region
aiplatform.init(project=project_id, location=region)

# Create an endpoint for deployment
endpoint = aiplatform.Endpoint.create(display_name=f"{model_name}-endpoint")

# VLLM Arguments for model serving
vllm_args = [
    "python",
    "-m",
    "vllm.entrypoints.api_server",
    "--host=0.0.0.0",
    "--port=7080",
    "--swap-space=16",
    "--gpu-memory-utilization=0.90",  # Matching the working setup
    "--max-model-len=131072",  # Matching the working setup
    "--disable-log-stats",
    f"--model={model_id}",  # Using the correct model ID
    "--tensor-parallel-size=4",  # Using 4 GPUs, matching the working setup
]

# Upload the model to Vertex AI
model = aiplatform.Model.upload(
    display_name=model_name,
    serving_container_image_uri=VLLM_DOCKER_URI,
    serving_container_args=vllm_args,
    serving_container_ports=[7080],
    serving_container_predict_route="/generate",
    serving_container_health_route="/ping",
    # Set environment variables as per your configuration
    serving_container_environment_variables={
        "MODEL_ID": model_id,
        "DEPLOY_SOURCE": "UI_NATIVE_MODEL",
    },
)

# Deploy the model to the endpoint
model.deploy(
    endpoint=endpoint,
    machine_type=machine_type,
    accelerator_type=accelerator_type,
    accelerator_count=accelerator_count,
)

# Fetch the endpoint ID (the last part of the endpoint resource name)
endpoint_id = endpoint.resource_name.split('/')[-1]

# Print the model and endpoint information
print(f"Model {model_name} deployed successfully at {endpoint.resource_name}!")
print(f"GCP Project ID: {project_id}")
print(f"GCP Endpoint ID: {endpoint_id}")

# Get the directory path for the .env file (current working directory in this case)
env_path = os.path.join(os.getcwd(), ".env")

# Write the project ID and endpoint ID to the .env file
set_key(env_path, "GCP_PROJECT_ID", project_id)
set_key(env_path, "GCP_ENDPOINT_ID", endpoint_id)

print(f"Project ID and Endpoint ID saved to {env_path}")