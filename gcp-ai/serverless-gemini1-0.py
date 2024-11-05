import os
from dotenv import load_dotenv
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# Load environment variables from .env file
load_dotenv()

# Retrieve variables from environment
project_id = os.getenv("GCP_PROJECT_ID")
location = os.getenv("GCP_REGION_NAME")
service_account_file = os.getenv("GCP_SERVICE_ACCOUNT_FILE")
endpoint = os.getenv("GCP_ENDPOINT_NAME")

# Load service account credentials and get an access token
credentials = service_account.Credentials.from_service_account_file(
    service_account_file,
    scopes=["https://www.googleapis.com/auth/cloud-platform"]
)
auth_request = Request()
credentials.refresh(auth_request)
access_token = credentials.token

# Define the API request payload with controlled output
def create_payload(prompt: str):
    return {
        "contents": {
            "role": "user",
            "parts": {
                "text": prompt
            }
        },
        "safety_settings": [
            {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_LOW_AND_ABOVE"
            }
        ],
        "generation_config": {
            "temperature": 0.7,
            "topP": 0.9,
            "maxOutputTokens": 250  # Increased to allow more output tokens
        }
    }

# Function to send a POST request to the endpoint and parse only the text content
def send_request(prompt: str):
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json; charset=utf-8"
    }
    data = create_payload(prompt)

    # Send POST request
    response = requests.post(
        endpoint,
        headers=headers,
        json=data,
        stream=True
    )

    # Collect response lines and combine them into a single JSON response
    if response.status_code == 200:
        print("Response Status Code:", response.status_code)
        response_text = ''.join([line.decode("utf-8") for line in response.iter_lines() if line])
        
        try:
            # Parse the combined response
            json_response = requests.models.complexjson.loads(response_text)
            full_text = []
            total_token_count = 0
            truncated = False

            # Extract and print only the "text" content in a readable format
            for item in json_response:
                # Track token usage if available
                if "usageMetadata" in item:
                    total_token_count = item["usageMetadata"].get("totalTokenCount", 0)

                for candidate in item.get("candidates", []):
                    parts = candidate.get("content", {}).get("parts", [])
                    for part in parts:
                        full_text.append(part.get("text", "").strip())
                    
                    # Check for truncation
                    if candidate.get("finishReason") == "MAX_TOKENS":
                        truncated = True

            # Join all parts and print the output
            print("\n".join(full_text))
            print("\nTotal Token Usage:", total_token_count)

            if truncated:
                print("\nNote: The response was truncated. Consider increasing maxOutputTokens for more content.")

        except ValueError:
            print("Failed to parse JSON response.")
    else:
        print(f"Error: {response.status_code} - {response.text}")

# Test prompt
send_request("Give me a full banana bread recipe with instructions.")
