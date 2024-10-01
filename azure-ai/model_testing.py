import requests
import json
import os
from dotenv import load_dotenv

load_dotenv()

# Load necessary environment variables from .env
api_key = os.getenv("AZURE_ENDPOINT_PRIMARY_KEY")
scoring_uri = os.getenv("AZURE_ENDPOINT_SCORING_URI")

# Append the correct path `/chat/completions` to the scoring URI
api_endpoint = f"{scoring_uri}/chat/completions"

print(f"API Endpoint: {api_endpoint}")

# Use the primary key from create_model_serverless.py in the Authorization header
headers = {
  "Content-Type": "application/json",
  "Authorization": f"Bearer {api_key}"
}

# Example payload for a chat completions API
data = {
  "model": os.getenv("AZURE_LLM_MODEL"),  # Model name from .env file
  "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello, Siapa Presiden Indonesia ke-4 ?"}
  ],
  "max_tokens": 100,  # Example for setting a token limit
  "temperature": 0.7  # Control randomness; optional
}

try:
  # Send a POST request to the Azure Serverless API
  response = requests.post(api_endpoint, headers=headers, data=json.dumps(data))

  # Check if the request was successful
  if response.status_code == 200:
      print("Chat response: ", response.json())
  else:
      print(f"Failed to connect. Status code: {response.status_code}")
      print("Response: ", response.text)
except Exception as e:
  print(f"Error occurred: {e}")