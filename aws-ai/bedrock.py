import boto3
import json
import os
import sys
import logging
from dotenv import load_dotenv
import argparse
import re
from botocore.exceptions import BotoCoreError, ClientError

# Define supported model prefixes and their configurations
MODEL_PREFIX_CONFIGURATIONS = [
    {
        "provider": "mistral",
        "prefixes": [r"^mistral.*"],
        "config_builder": lambda prompt, stop_sequences=None: {
            "prompt": prompt,
            "max_tokens": 256,          
            "stop": stop_sequences if stop_sequences else [],
            "temperature": 0.7,         
            "top_p": 0.95,              
            "top_k": 40,                
        },
        "response_parser": lambda response_body: response_body.get("outputs", ""),
        "api_type": "invoke_model",
    },
    {
        "provider": "amazon",
        "prefixes": [r"^amazon.*"],
        "config_builder": lambda prompt, stop_sequences=None: {
            "inputText": prompt,
            "textGenerationConfig": {
                "temperature": 0.6,
                "topP": 0.95,
                "maxTokenCount": 150,
                "stopSequences": stop_sequences if stop_sequences else []
            }
        },
        "response_parser": lambda response_body: response_body.get("results", [{}])[0].get("outputText", ""),
        "api_type": "invoke_model",
    },
    {
        "provider": "meta",
        "prefixes": [r"^meta.*"],
        "config_builder": lambda prompt, stop_sequences=None: {
            "prompt": prompt,
            "max_gen_len": 512,
            "temperature": 0.4,
            "top_p": 0.9,
        },
        "response_parser": lambda response_body: response_body.get("generation", ""),
        "api_type": "invoke_model",
    },
    {
        "provider": "anthropic",
        "prefixes": [r"^anthropic.*"],
        "config_builder": lambda prompt, stop_sequences=None: {
            "prompt": f"\n\nHuman:{prompt}\n\nAssistant:",
            "temperature": 0.7,            
            "top_p": 0.9,                  
            "top_k": 50,                   
            "max_tokens_to_sample": 200,   
            "stop_sequences": stop_sequences if stop_sequences else []
        },
        "response_parser": lambda response_body: response_body.get("completion", "").strip(),
        "api_type": "invoke_model",
    },
    # Add more model configurations here as needed
]

def setup_logger(log_file_path="setup.log"):
    """
    Sets up the logger to log messages to a specified file with timestamps and log levels.
    """
    logging.basicConfig(
        filename=log_file_path,
        level=logging.INFO,  # Changed from DEBUG to INFO
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    return logging.getLogger()

def load_environment(execution_dir, logger):
    """
    Loads environment variables from a .env file located in the execution directory or current directory.
    """
    if execution_dir:
        dotenv_path = os.path.join(execution_dir, '.env')
        if os.path.isfile(dotenv_path):
            load_dotenv(dotenv_path)
            logger.info(f"Loaded .env from {dotenv_path}")
        else:
            logger.error(f".env file not found at {dotenv_path}.")
            sys.exit(1)
    else:
        dotenv_path = '.env'
        if os.path.isfile(dotenv_path):
            load_dotenv(dotenv_path)
            logger.info(f"Loaded .env from current directory: {dotenv_path}")
        else:
            logger.error("EXECUTION_DIR not set and .env file not found in the current directory.")
            sys.exit(1)

def get_env_variables(logger):
    """
    Retrieves AWS_REGION, MODEL_ID, and STOP_SEQUENCES from environment variables.
    """
    region = os.getenv('AWS_REGION')
    model_id = os.getenv('MODEL_ID')
    stop_sequences = os.getenv('STOP_SEQUENCES', '[]')  # Default to empty list

    if not region:
        logger.error("AWS_REGION not found in the environment variables.")
        sys.exit(1)
    if not model_id:
        logger.error("MODEL_ID not found in the environment variables.")
        sys.exit(1)
    try:
        stop_sequences = json.loads(stop_sequences)
        if not isinstance(stop_sequences, list):
            raise ValueError
    except ValueError:
        logger.error("STOP_SEQUENCES must be a valid JSON list.")
        sys.exit(1)
    return region, model_id, stop_sequences

def find_model_configuration(model_id):
    """
    Finds and returns the model configuration based on the provided model_id.
    """
    for model_config in MODEL_PREFIX_CONFIGURATIONS:
        for prefix in model_config["prefixes"]:
            if re.match(prefix, model_id):
                return model_config
    return None

def invoke_model(client, model_config, model_id, prompt_text, logger, stop_sequences=None):
    """
    Invokes the Bedrock model using the appropriate API and parses the response.
    """
    api_type = model_config.get("api_type", "invoke_model")

    if api_type == "invoke_model":
        # Build the configuration based on the model
        config = model_config["config_builder"](prompt_text, stop_sequences)
    elif api_type == "messages":
        # For Messages API, include system and user messages
        config = model_config["config_builder"](prompt_text)
    else:
        logger.error(f"Unsupported API type: {api_type}")
        sys.exit(1)

    config_json = json.dumps(config)

    # Log the configuration payload at INFO level
    logger.info(f"Configuration Payload: {config_json}")

    # Additionally, log the actual prompt or messages being sent
    if api_type == "invoke_model":
        if model_config['provider'] == 'mistral':
            pass  # Removed debug log
        elif model_config['provider'] == 'amazon':
            pass  # Removed debug log
        elif model_config['provider'] == 'claude':
            pass  # Removed debug log
        elif model_config['provider'] == 'anthropic':
            pass  # Removed debug log
        else:
            pass  # Removed debug log
    elif api_type == "messages":
        pass  # Removed debug log

    try:
        if api_type in ["invoke_model", "messages"]:
            response = client.invoke_model(
                body=config_json,
                modelId=model_id,
                accept="application/json",
                contentType="application/json"
            )
        else:
            logger.error(f"Unsupported API type: {api_type}")
            sys.exit(1)

        response_body = json.loads(response.get('body').read())
        generation = model_config["response_parser"](response_body)

        if generation:
            return generation
        else:
            logger.error("No generation found in the response.")
            # logger.debug(f"Full Response Body: {json.dumps(response_body, indent=2)}")  # Removed debug log
            return None
    except (BotoCoreError, ClientError) as e:
        logger.error(f"An error occurred while invoking the model: {e}")
        sys.exit(1)
    except json.JSONDecodeError:
        logger.error("Failed to decode the response body as JSON.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
        sys.exit(1)

def parse_arguments():
    """
    Parses command-line arguments for prompt, log file path, and execution directory.
    """
    parser = argparse.ArgumentParser(description="Invoke Bedrock model with a prompt.")
    parser.add_argument('--prompt', type=str, default="Siapa presiden ke-4 Indonesia?",
                        help='Prompt text to send to the model.')
    parser.add_argument('--log', type=str, default="setup.log",
                        help='Path to the log file.')
    parser.add_argument('--execution_dir', type=str, default=None,
                        help='Directory containing the .env file.')
    return parser.parse_args()

def main():
    args = parse_arguments()
    logger = setup_logger(args.log)

    load_environment(args.execution_dir, logger)
    region, model_id, stop_sequences = get_env_variables(logger)

    prompt_text = args.prompt.strip()  # Remove leading/trailing whitespace

    # Validate prompt is not empty
    if not prompt_text:
        logger.error("Prompt is empty. Please provide a valid prompt.")
        sys.exit(1)

    # Find the model configuration based on model_id
    model_config = find_model_configuration(model_id)
    if not model_config:
        logger.error(f"Unsupported model_id: {model_id}. Please update the MODEL_PREFIX_CONFIGURATIONS.")
        sys.exit(1)

    # Log which provider is being used
    logger.info(f"Using provider: {model_config['provider']}")

    try:
        client = boto3.client(service_name='bedrock-runtime', region_name=region)
        logger.info(f"Initialized Bedrock client for region: {region}")
    except (BotoCoreError, ClientError) as e:
        logger.error(f"Failed to initialize Bedrock client: {e}")
        sys.exit(1)

    generation = invoke_model(client, model_config, model_id, prompt_text, logger, stop_sequences)

    if generation:
        formatted_model_id = f"Model ID: {model_id}"
        formatted_prompt = f"Prompt: {prompt_text}"
        formatted_response = f"Response: {generation}"  # Already a string

        # Print to terminal
        print(formatted_model_id)
        print(formatted_prompt)
        print(formatted_response)

        # Log the information
        logger.info(formatted_model_id)
        logger.info(formatted_prompt)
        logger.info(formatted_response)
    else:
        logger.error("No generation received from the model.")

if __name__ == "__main__":
    main()
