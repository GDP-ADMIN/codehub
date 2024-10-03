# Azure AI Hub and Serverless Model Deployment

This project contains scripts to set up and manage Azure AI Hub, Azure Machine Learning Workspaces, and deploy models via Azure Serverless API endpoints.

## Prerequisites
Before running the scripts, ensure the following:
1. **(Optional) Documentation**: Review the [Azure AI: Serverless API Endpoint](https://docs.google.com/document/d/1WCm0Rdd552P_3OoerX-kHHNdPWfbNtpRX6oEbxj11Wc/edit?usp=sharing) document for additional details
2. **Azure Client ID & Client Secret**: Contact ticket@gdplabs.id to get access Azure Account (Client ID and Client Secret) with Azure AI Developer and gl-workspaces roles access
3. **Setup environment variables**: Copy [.env.example](.env.example) and insert the value based on [Scope of Services](https://docs.google.com/document/d/1WCm0Rdd552P_3OoerX-kHHNdPWfbNtpRX6oEbxj11Wc/edit#heading=h.lfdykfqkf1d5), and save the file as `.env` on your working folder

## Setup and Installation
1. **Run 1-click CLI script**
    - Linux, WSL and MacOS Version (UNIX)
    ```bash
    curl -o setup_azure_ai.sh https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/azure-ai/setup_azure_ai.sh && chmod 755 setup_azure_ai.sh && bash setup_azure_ai.sh
    ```

    - Windows Version
    ```powershell
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/azure-ai/setup_azure_ai.sh" -OutFile "setup_azure_ai.sh"
    wsl ./setup_azure_ai.sh
    ```

2. Select the model to be deployed: \
   Choose **1** For *Meta-Llama-3-8B-Instruct* model \
   Choose **2** For *Phi-3.5-vision-instruct* model

3. Example of successful requests
    > Endpoint URL: https://dso-ai-endpoint-<user-name-email-gdp labs>-meta-llama-3-8b-in.eastus2.models.ai.azure.com
API Endpoint: https://dso-ai-endpoint-bukhori-m-baihaqi-meta-llama-3-8b-in.eastus2.models.ai.azure.com/chat/completions
Chat response:  {'choices': [{'finish_reason': 'stop', 'index': 0, 'message': {'content': 'Hello!\n\nThe 4th President of Indonesia is Abdul Haris Nasution.', 'role': 'assistant', 'tool_calls': []}}], 'created': 1727937672, 'id': 'cmpl-05a37956aea3401799cecf8180e90235', 'model': 'Meta-Llama-3-8B-Instruct', 'object': 'chat.completion', 'usage': {'completion_tokens': 17, 'prompt_tokens': 32, 'total_tokens': 49}}

**Notes** : Execution time < 3 minutes

## (Optional) TEST THE DEPLOYED MODEL
If you want to run model_testing.py by changing the prompting, you can follow this flow.
1. Ensure you have .env files with value based on the Scope of Services, my_venv folder in your working directory and already activated my_venv.   
    - Linux, WSL and MacOS Version (UNIX)
      ```bash
      source my_venv/bin/activate
      ``` 
    
    - Windows Version
      ```bash
      source my_venv/Scripts/activate
      ```
2. Update the codehub/azure-ai/model_testing.py file at line 28 in the " {"role": "user", "content": "Hello, Who is the 4th President of Indonesia?"} " section.
    - Linux specific sed command 
      ```bash
      sed -i 's/Hello, Siapa Presiden Indonesia ke-4 ?/**Create Hello World** ?/' codehub/azure-ai/model_testing.py
      ```
    - macOS specific sed command
      ```bash
      sed -i '' 's/Hello, Siapa Presiden Indonesia ke-4 ?/**Create Hello World** ?/' codehub/azure-ai/model_testing.py
      ```
    - Windows PowerShell command
      ```bash
      (Get-Content "codehub/azure-ai/model_testing.py") -replace 'Hello, Siapa Presiden Indonesia ke-4 ?', '**Create Hello World** ?' | Set-Content "codehub/azure-ai/model_testing.py"
      ```
3. Run the script 
    - Linux, WSL and MacOS Version (UNIX)
      ```bash
      python3 codehub/azure-ai/model_testing.py
      ```
    - Windows Version
      ```bash
      python codehub/azure-ai/model_testing.py
      ```
4. Example of prompt requests
    > data = {
  "model": os.getenv("AZURE_LLM_MODEL"),  # Model name from .env file
  "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "**Create Hello World** ?"}
  ],
  "max_tokens": 100,  # Example for setting a token limit
  "temperature": 0.7  # Control randomness; optional
}

5. Example of successful requests
    > API Endpoint: https://dso-ai-endpoint-<user-name-email-gdp labs>-meta-llama-3-8b-in.eastus2.models.ai.azure.com/chat/completions
Chat response:  {'choices': [{'finish_reason': 'length', 'index': 0, 'message': {'content': 'A classic request!\n\nHere is a simple "Hello World" program in a few popular programming languages:\n\n**C**\n```c\n#include <stdio.h>\n\nint main() {\n    printf("Hello, World!\\n");\n    return 0;\n}\n```\n\n**Java**\n```java\npublic class HelloWorld {\n    public static void main(String[] args) {\n        System.out.println("Hello, World!");\n    }\n}\n```\n\n**Python**\n```python\nprint("Hello, World!")\n```\n\n', 'role': 'assistant', 'tool_calls': []}}], 'created': 1727938380, 'id': 'cmpl-b6d6a0a551a44b8b99a4049979c73403', 'model': 'Meta-Llama-3-8B-Instruct', 'object': 'chat.completion', 'usage': {'completion_tokens': 100, 'prompt_tokens': 25, 'total_tokens': 125}}


## Included Scripts:
- ![Red Text](https://img.shields.io/badge/Administrator%20Only-FF0000) - [create_hub.py](create_hub.py) : Creates an Azure AI Hub \
 Creates an Azure AI Hub in a specified subscription, resource group, and region.

- [create_workspaces_project.py](create_workspaces_project.py) : Creates workspaces in an Azure AI Hub \
Creates workspaces within an existing Azure AI Hub.

- [create_model_serverless.py](create_model_serverless.py) : Deploys a machine learning model to an Azure Serverless API \
Deploys a machine learning model to an Azure Serverless API and sets up an endpoint.

- [model_testing.py](model_testing.py) : Tests the deployed model via an HTTP request to the Azure Serverless API \
Sends a test HTTP request to the serverless endpoint to validate the model deployment.

## Notes
If you experience any problems, please do not hesitate to contact us at ticket@gdplabs.id