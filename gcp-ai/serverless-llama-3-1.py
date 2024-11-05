import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Define your variables from .env
service_account_file = os.getenv("GCP_SERVICE_ACCOUNT_FILE")
project_id = os.getenv("GCP_PROJECT_ID")
region = os.getenv("GCP_REGION_NAME")
endpoint = os.getenv("GCP_ENDPOINT_NAME")
model = os.getenv("GCP_MODEL_NAME")

# Load service account credentials
credentials = service_account.Credentials.from_service_account_file(
    service_account_file,
    scopes=["https://www.googleapis.com/auth/cloud-platform"]
)

# Get an access token
auth_req = Request()
credentials.refresh(auth_req)
access_token = credentials.token

# Define the API request data
data = {
    "model": model,
    "stream": True,
    # Test Prompt
    "messages": [
        {"role": "user", "content": "What is Buitenzorg?"}
    ]
}

# Set up the headers with the access token
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

# Send the POST request with stream enabled
response = requests.post(
    f"https://{endpoint}/v1/projects/{project_id}/locations/{region}/endpoints/openapi/chat/completions",
    headers=headers,
    json=data,
    stream=True  # Enable streaming response
)

# Check if the request was successful
print("Status Code:", response.status_code)

# Process each line in the streamed response
for line in response.iter_lines():
    if line:  # Skip empty lines
        # Remove 'data: ' prefix and parse JSON content
        line = line.decode("utf-8").strip()
        if line.startswith("data:"):
            try:
                json_data = line[5:].strip()  # Remove 'data:' prefix
                chunk = requests.models.complexjson.loads(json_data)  # Parse JSON data
                
                # Extract and print only the "content" field if it exists
                if "choices" in chunk:
                    for choice in chunk["choices"]:
                        if "delta" in choice and "content" in choice["delta"]:
                            print(choice["delta"]["content"])
            except ValueError:
                print("Non-JSON response:", line)