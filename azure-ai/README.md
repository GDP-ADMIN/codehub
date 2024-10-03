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
    <pre>
    Endpoint URL: https://dso-ai-workspaces-<user-name-email-gdplabs>-meta-llama-3-8b-instruct.eastus2.models.ai.azure.com
    API Endpoint: https://dso-ai-workspaces-<user-name-email-gdplabs>-meta-llama-3-8b-instruct.eastus2.models.ai.azure.com/chat/completions
    Chat response:  {'choices': [{'finish_reason': 'stop', 'index': 0, 'message': {'content': "Halo!\n\nThe 4th President of Indonesia is Abdul Halim Muafiah. However, he only served as acting President for a short period of time, from March 16, 1963, to July 21, 1963.\n\nIf you're looking for the 4th President who served a full term, it would be Sukarno. He was the 1st President of Indonesia from 1945 to 1967.", 'role': 'assistant', 'tool_calls': []}}], 'created': 1727958018, 'id': 'cmpl-751b79fc8a334e99b99c675c193c60aa','model': 'Meta-Llama-3-8B-Instruct', 'object': 'chat.completion', 'usage': {'completion_tokens': 93, 'prompt_tokens': 32, 'total_tokens': 125}}
    </pre>

**Notes** : Execution time will take about 2 to 5 minutes depending your internet connection

## (Optional) Test the Deployed Model
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
2. Update the `codehub/azure-ai/model_testing.py` file at line 28 in the `" {"role": "user", "content": "Hello, Who is the 4th President of Indonesia?"} " section.`
    - Linux, WSL
      ```bash
      sed -i 's/Hello, Siapa Presiden Indonesia ke-4 ?/Show Hello World ?/' codehub/azure-ai/model_testing.py
      ```
    - MacOS
      ```bash
      sed -i '' 's/Hello, Siapa Presiden Indonesia ke-4 ?/Show Hello World ?/' codehub/azure-ai/model_testing.py
      ```
    - Windows PowerShell
      ```bash
      (Get-Content "codehub/azure-ai/model_testing.py") -replace 'Hello, Siapa Presiden Indonesia ke-4 ?', 'Show Hello World ?' | Set-Content "codehub/azure-ai/model_testing.py"
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

4. Example of successful requests
    <pre>
    API Endpoint: https://dso-ai-workspaces-<user-name-email-gdplabs>-meta-llama-3-8b-instruct.eastus2.models.ai.azure.com/chat/completions
    Chat response:  {'choices': [{'finish_reason': 'stop', 'index': 0, 'message': {'content': 'Here is the classic "Hello World" output:\n\n**Hello World!**\n\nI hope you\'re having a great day! Is there anything else I can help you with?', 'role': 'assistant', 'tool_calls': []}}], 'created': 1727958396, 'id': 'cmpl-0ccc32e9a87c432f925514ecd44066c9', 'model': 'Meta-Llama-3-8B-Instruct', 'object': 'chat.completion', 'usage': {'completion_tokens': 35, 'prompt_tokens': 25, 'total_tokens': 60}}
    </pre>


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