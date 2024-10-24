import boto3
import json
import pprint
import os
import sys
from dotenv import load_dotenv

def log_to_file(message, log_file_path="setup.log"):
    """Log messages to a specified log file."""
    with open(log_file_path, "a") as log_file:
        log_file.write(f"{message}\n")

def main():
    # Retrieve EXECUTION_DIR from environment variables
    execution_dir = os.getenv('EXECUTION_DIR')
    log_file = os.path.join(execution_dir, "setup.log") if execution_dir else "setup.log"

    if execution_dir:
        dotenv_path = os.path.join(execution_dir, '.env')
        if os.path.isfile(dotenv_path):
            # Load environment variables from the .env file in EXECUTION_DIR
            load_dotenv(dotenv_path)
            # Log the message to file
            log_to_file(f"Loaded .env from {dotenv_path}", log_file)
        else:
            error_message = f"ERROR: .env file not found at {dotenv_path}."
            log_to_file(error_message, log_file)
            sys.exit(1)
    else:
        # Fallback: Attempt to load .env from the current directory
        dotenv_path = '.env'
        if os.path.isfile(dotenv_path):
            load_dotenv(dotenv_path)
            log_to_file(f"Loaded .env from current directory: {dotenv_path}", log_file)
        else:
            error_message = "ERROR: EXECUTION_DIR not set and .env file not found in the current directory."
            log_to_file(error_message, log_file)
            sys.exit(1)

    # Retrieve variables from environment
    region = os.getenv('AWS_REGION')
    model_id = os.getenv('MODEL_ID')

    if not region:
        error_message = "ERROR: AWS_REGION not found in the environment variables."
        log_to_file(error_message, log_file)
        sys.exit(1)
    if not model_id:
        error_message = "ERROR: MODEL_ID not found in the environment variables."
        log_to_file(error_message, log_file)
        sys.exit(1)

    # Define the prompt
    prompt_text = "Which country won the 2022 World Cup?"

    try:
        # Initialize the Bedrock runtime client
        client = boto3.client(service_name='bedrock-runtime', region_name=region)

        # Define the configuration for the Llama model
        llama_config = json.dumps({
            "prompt": prompt_text,
            "max_gen_len": 512,
            "temperature": 0,
            "top_p": 0.9,
        })

        # Invoke the model
        response = client.invoke_model(
            body=llama_config,
            modelId=model_id,
            accept="application/json",
            contentType="application/json"
        )

        # Parse the response body
        response_body = json.loads(response.get('body').read())

        # Extract the generation result
        generation = response_body.get("generation", {})

        if generation:
            # Format and print the prompt and response to the terminal
            formatted_prompt = f"Prompt: {prompt_text}"
            formatted_response = f"Response: {pprint.pformat(generation)}"
            
            # Print to terminal
            print(formatted_prompt)
            print(formatted_response)
            
            # Also log the prompt and response to file
            log_to_file(formatted_prompt, log_file)
            log_to_file(formatted_response, log_file)
        else:
            error_message = "No generation found in the response."
            print(error_message)
            log_to_file(error_message, log_file)

    except boto3.exceptions.Boto3Error as e:
        error_message = f"An error occurred while invoking the model: {e}"
        print(error_message)
        log_to_file(error_message, log_file)
        sys.exit(1)
    except json.JSONDecodeError:
        error_message = "Failed to decode the response body as JSON."
        print(error_message)
        log_to_file(error_message, log_file)
        sys.exit(1)
    except Exception as e:
        error_message = f"An unexpected error occurred: {e}"
        print(error_message)
        log_to_file(error_message, log_file)
        sys.exit(1)

if __name__ == "__main__":
    main()