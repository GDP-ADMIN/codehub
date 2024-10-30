# Imports
from google.cloud import aiplatform
from dotenv import load_dotenv, set_key
import os

# Load environment variables from .env file
load_dotenv()

# Confirm Google Cloud credentials are set
google_credentials = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
if not google_credentials:
    raise ValueError("GOOGLE_APPLICATION_CREDENTIALS is not set!")
else:
    print(f"GOOGLE_APPLICATION_CREDENTIALS is set to: {google_credentials}")

# Set environment-specific variables
project_id = os.getenv("GCP_PROJECT_ID")
region = os.getenv("GCP_REGION")
VLLM_DOCKER_URI = os.getenv("GCP_VLLM_DOCKER_URI")
model_name = os.getenv("GCP_MODEL_NAME")
endpoint_name = os.getenv("GCP_ENDPOINT_NAME")
# model_id = "meta-llama/Llama-3.1-8B-Instruct"
model_id = os.getenv("GCP_MODEL_ID")
machine_type = os.getenv("GCP_MACHINE_TYPE")
accelerator_type = os.getenv("GCP_ACCELERATOR_TYPE")
accelerator_count = int(os.getenv("GCP_ACCELERATOR_COUNT"))

# Initialize the AI Platform with project and region
aiplatform.init(project=project_id, location=region)

# Create an endpoint for deployment
endpoint = aiplatform.Endpoint.create(display_name=f"{endpoint_name}")

# Set model serving arguments
vllm_args = [
    "python",
    "-m",
    "vllm.entrypoints.api_server",
    "--host=0.0.0.0",
    "--port=7080",
    "--swap-space=32",
    "--gpu-memory-utilization=0.90",
    "--max-model-len=4096",
    "--disable-log-stats",
    f"--model=gs://vertex-model-garden-restricted-us/llama3.1/Meta-Llama-3.1-8B-Instruct",
    "--tensor-parallel-size=0",
    "--max-num-seqs=24",
    "--enable-auto-tool-choice",
    "--tool-call-parser=vertex-llama-3",
    # "--max-total-tokens=4096",
    # "--temperature=0.7",
    # "--top-p=0.9"
]

# Upload the model to Vertex AI, including required environment variables
model = aiplatform.Model.upload(
    display_name=model_name,
    serving_container_image_uri=VLLM_DOCKER_URI,
    serving_container_args=vllm_args,
    serving_container_ports=[7080],
    serving_container_predict_route="/generate",
    serving_container_health_route="/ping",
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

# Your existing code to fetch endpoint_id
endpoint_id = endpoint.resource_name.split('/')[-1]
print(f"Model {model_name} deployed successfully at {endpoint.resource_name}!")
print(f"GCP Project ID: {project_id}")
print(f"GCP Endpoint ID: {endpoint_id}")

# Specify .env file path
env_path = os.path.join(os.getcwd(), ".env")

# Save project ID and endpoint ID with double quotes
set_key(env_path, "GCP_ENDPOINT_ID", f'"{endpoint_id}"')

print(f"Endpoint ID saved to {env_path}")