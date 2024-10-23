import os
from google.cloud import aiplatform
from google.protobuf import json_format
from google.protobuf.struct_pb2 import Value
from typing import Dict, List, Union
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

# Ensure the correct environment variable for Google credentials is set
gcp_credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

# Set GOOGLE_APPLICATION_CREDENTIALS if not set
if gcp_credentials_path:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = gcp_credentials_path

def predict_custom_trained_model_sample(
    project: str,
    endpoint_id: str,
    instances: Union[Dict, List[Dict]],
    location: str,
    api_endpoint: str,
):
    client_options = {"api_endpoint": api_endpoint}
    client = aiplatform.gapic.PredictionServiceClient(client_options=client_options)
    instances = instances if isinstance(instances, list) else [instances]
    instances = [
        json_format.ParseDict(instance_dict, Value()) for instance_dict in instances
    ]
    parameters_dict = {}
    parameters = json_format.ParseDict(parameters_dict, Value())
    endpoint = client.endpoint_path(
        project=project, location=location, endpoint=endpoint_id
    )

    try:
        response = client.predict(endpoint=endpoint, instances=instances, parameters=parameters)
        print("Prediction results:")
        for prediction in response.predictions:
            print(prediction)
    except Exception as e:
        print(f"Error occurred: {e}")

# Retrieve values from .env file
project_id = os.getenv("GCP_PROJECT_ID")
endpoint_id = os.getenv("GCP_ENDPOINT_ID")
location = os.getenv("GCP_REGION")
api_endpoint = f"{location}-aiplatform.googleapis.com"

# Example instances for prediction
instances = {"prompt": "Who is Harry Potter?"}

# Call the function using the values from the .env file
predict_custom_trained_model_sample(
    project=project_id,
    endpoint_id=endpoint_id,
    instances=instances,
    location=location,
    api_endpoint=api_endpoint,
)