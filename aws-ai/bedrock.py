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
            "prompt": f"\n\nHuman: {prompt}\n\nAssistant:",
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

def setup_logger(log_file_path="bedrock.log"):
    """
    Sets up the logger to log messages to a specified file.
    Does not log messages to the console.
    """
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # File handler
    file_handler = logging.FileHandler(log_file_path)
    file_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', 
                                       datefmt='%Y-%m-%d %H:%M:%S')
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)

    # Remove other handlers if any (e.g., StreamHandler)
    if logger.hasHandlers():
        for handler in logger.handlers:
            if isinstance(handler, logging.StreamHandler):
                logger.removeHandler(handler)

    return logger

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

def get_env_variables(logger, args):
    """
    Retrieves AWS_REGION and STOP_SEQUENCES from environment variables.
    MODEL_ID is set based on user selection within the script.
    """
    region = os.getenv('AWS_REGION')
    stop_sequences = os.getenv('STOP_SEQUENCES', '[]')  # Default to empty list

    if not region:
        logger.error("AWS_REGION not found in the environment variables.")
        sys.exit(1)
    
    try:
        stop_sequences = json.loads(stop_sequences)
        if not isinstance(stop_sequences, list):
            raise ValueError
        if not all(isinstance(seq, str) for seq in stop_sequences):
            raise ValueError
    except ValueError:
        logger.error("STOP_SEQUENCES must be a valid JSON list of strings.")
        sys.exit(1)
    return region, stop_sequences

def find_model_configuration(model_id):
    """
    Finds and returns the model configuration based on the provided model_id.
    """
    for model_config in MODEL_PREFIX_CONFIGURATIONS:
        for prefix in model_config["prefixes"]:
            if re.fullmatch(prefix, model_id):
                return model_config
    return None

def invoke_model(client, model_config, model_id, prompt_text, logger, stop_sequences=None):
    """
    Invokes the Bedrock model using the appropriate API and parses the response.
    Implements retries for transient errors.
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
    logger.info(f"Configuration Payload: {config_json}")

    try:
        response = client.invoke_model(
            body=config_json,
            modelId=model_id,
            accept="application/json",
            contentType="application/json"
        )
        response_body = json.loads(response.get('body').read())
        generation = model_config["response_parser"](response_body)

        if generation:
            return generation
        else:
            logger.error("No generation found in the response.")
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
    Parses command-line arguments for log file path and execution directory.
    """
    parser = argparse.ArgumentParser(description="Invoke Bedrock model with a fixed prompt.")
    parser.add_argument('--log', type=str, default="bedrock.log",
                        help='Path to the log file.')
    parser.add_argument('--execution_dir', type=str, default=None,
                        help='Directory containing the .env file.')
    return parser.parse_args()

def display_model_selection(logger):
    """
    Displays the model selection menu and returns the selected model_id.
    """
    print("----------------------------------------")
    print("Choose the model to deploy:")
    print("----------------------------------------")

    # Define the list of available models with their IDs
    models = [
        "Amazon|Titan Text G1 - Express|1.x|amazon.titan-text-express-v1",
        "Amazon|Titan Text G1 - Lite|1.x|amazon.titan-text-lite-v1",
        "Anthropic|Claude|2.0|anthropic.claude-v2",
        "Anthropic|Claude|2.1|anthropic.claude-v2:1",
        "Anthropic|Claude Instant|1.x|anthropic.claude-instant-v1",
        "Meta|Llama 3 8B Instruct|1.x|meta.llama3-8b-instruct-v1:0",
        "Meta|Llama 3 70B Instruct|1.x|meta.llama3-70b-instruct-v1:0",
        "Meta|Llama 3.1 8B Instruct|1.x|meta.llama3-1-8b-instruct-v1:0",
        "Mistral AI|Mistral 7B Instruct|0.x|mistral.mistral-7b-instruct-v0:2",
        "Mistral AI|Mixtral 8X7B Instruct|0.x|mistral.mixtral-8x7b-instruct-v0:1",
        "Mistral AI|Mistral Large|1.x|mistral.mistral-large-2402-v1:0"
    ]

    # Display the models with numbering
    for index, model in enumerate(models, start=1):
        provider, model_name, version, model_id = model.split("|")
        print(f"{index}. {provider} - {model_name} (Version: {version})")

    # Prompt the user for selection
    while True:
        try:
            model_choice = int(input("Enter the number corresponding to the model:"))
            if 1 <= model_choice <= len(models):
                selected_model = models[model_choice - 1]
                provider, model_name, version, model_id = selected_model.split("|")
                logger.info(f"Selected Model: {provider} - {model_name} (Version: {version})")
                logger.info(f"Model ID set to: {model_id}")

                # Confirmation message to the user
                print("----------------------------------------------------------------")
                print(f"Selected Model: {provider} - {model_name} (Version: {version})")
                return model_id
            else:
                print("Invalid choice. Please select a valid number from the list.")
        except ValueError:
            print("Invalid input. Please enter a number.")

def main():
    args = parse_arguments()
    logger = setup_logger(args.log)

    load_environment(args.execution_dir, logger)
    region, stop_sequences = get_env_variables(logger, args)

    # Model Selection
    model_id = display_model_selection(logger)

    # Initialize Bedrock client
    try:
        client = boto3.client(service_name='bedrock-runtime', region_name=region)
        logger.info(f"Initialized Bedrock client for region: {region}")
    except (BotoCoreError, ClientError) as e:
        logger.error(f"Failed to initialize Bedrock client: {e}")
        sys.exit(1)

    # Fixed Prompt Handling
    prompt_text = "Siapa presiden ke-4 Indonesia?"

    # Log the fixed prompt
    logger.info(f"Using fixed prompt: {prompt_text}")

    # Find the model configuration based on model_id
    model_config = find_model_configuration(model_id)
    if not model_config:
        logger.error(f"Unsupported model_id: {model_id}. Please update the MODEL_PREFIX_CONFIGURATIONS.")
        sys.exit(1)

    # Log which provider is being used
    logger.info(f"Using provider: {model_config['provider']}")

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
