# Azure AI Hub and Serverless Model Deployment

This project contains scripts to set up and manage Azure AI Hub, Azure Machine Learning Workspaces, and deploy models via Azure Serverless API endpoints.

## Prerequisites
Before running the scripts, ensure the following:
1. **Documentation**: Review the [Azure AI: Serverless API Endpoint](https://docs.google.com/document/d/1WCm0Rdd552P_3OoerX-kHHNdPWfbNtpRX6oEbxj11Wc/edit?usp=sharing) document for additional details
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

## Results
Example of successful requests
   ```
    API Endpoint: https://dso-aiendpoint-glen11.eastus2.models.ai.azure.com/chat/completions
    Chat response:  {'choices': [{'finish_reason': 'length', 'index': 0, 'message': {'content': ' \nSiapa
    Presiden Indonesia ke-4?\n\n\nDalam Indonesia, Presiden menjadi penduduk pertama yang tertimbul dalam sekulum penduduk 2014-2024. Pada saat ini, Presiden Indonesia adalah Jokowi dan Mahakam Jokowi.
    \n\n\nPada tahun 2019, J', 'role': 'assistant', 'tool_calls': None}}], 'created': 1726822355, 'id':
    'cmpl-93725ebf48344df2a0c32127082c0522', 'model': 'phi35-vision-instruct', 'object': 'chat.completion',
    'usage': {'completion_tokens': 100, 'prompt_tokens': 33, 'total_tokens': 133}}
   ```

## [Optional] TEST THE DEPLOYED MODEL
If you want to run model_testing.py by changing the prompting, you can follow this flow.
1. Ensure you have .env files with value based on the Scope of Services, my_venv folder in your working folder and already activated my_venv.   
  - Linux
    ```bash
    source my_venv/bin/activate
    ``` 
  
  - Windows
    ```bash
    source my_venv/Scripts/activate
    ```
2. Run the script \
    ```bash
    python codehub/azure-ai/model_testing.py
    ```
    **or**
    ```bash
    python3 codehub/azure-ai/model_testing.py
    ```

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