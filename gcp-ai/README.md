# GCP Vertex AI Serverless Model Deployment

This project contains scripts to  run models via GCP Vertex AI Serverless API endpoints.

## Prerequisites

Before running the scripts, ensure that you have the following:

1. For Windows users, you can use WSL to run the script. Please make sure you have installed WSL first. For Linux and macOS users, you can run the script directly.
2. **GCP Service Account**: To access the GCP Account (Service Account) with Vertex AI Administrator roles, contact our [ticket system](https://docs.google.com/document/d/1cXRjv34uXjluQzyRu027r5ax8GT-HOw3naMSPi8aeVs/edit#heading=h.3bryigm0r34y)  with the subject email as “GCP Service Account in [Scope of Service at Team](https://docs.google.com/document/d/1cXRjv34uXjluQzyRu027r5ax8GT-HOw3naMSPi8aeVs/edit?tab=t.0#heading=h.lfdykfqkf1d5) for Vertex AI”. For the example :
  <pre>Subject</pre>
  ```
  GCP Service Account in abc-exploration for Vertex AI
  ```

  <pre>Body Email</pre>
  ```
    Dear Infra Team,
    I am requesting a GCP service account setup in the glx-exploration project for use with Vertex AI. This service account will enable us to proceed with the necessary configurations and integrations required for our Vertex AI workflows.
    Could you please create and provide the service account credentials at your earliest convenience? Once we have the service account details, we can move forward with the setup and testing steps.
    Thank you for your support.
  ```
  Note: The ticket system email address is hidden to prevent phishing and spam. For the Llama 3.1 API Service model, ensure this API is also enabled.
3. **Setup environment variables**: Copy the  [.env.example](/gcp-ai/.env.example) file to your working folder  and rename it to `.env`  in your local working directory
Follow the instructions in the .env file to fill in the required values based on Scope of Services.
4. **Active Directory**: Ensure that the `.env` file and Service Account file `(*.json)` provided by the Infra Team are placed in your active directory. Below is an example of the directory structure:
  <pre>
    [MyExampleDirectory]
    ├── codehub // This directory will appear after you run the 1-click CLI Script.
    │   ├── gcp-ai
    │       ├── .env.example
    │       ├── README.md
    │       ├── serverless-gemini1-0.py
    │       ├── serverless-llama-3-1.py
    │       └── setup_gcp_ai.sh
    ├── .env
    ├── service-account.json
    └── setup_gcp_ai.sh </pre>
    

## Setup and Installation

1. **Run 1-click CLI script**

   - Linux, WSL and MacOS Version (UNIX)

   ```bash
   curl -o setup_gcp_ai.sh https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/gcp-ai/setup_gcp_ai.sh && chmod 755 setup_gcp_ai.sh && bash setup_gcp_ai.sh
   ```
   **Notes** : Execution time will take about less to 2 minutes depending your internet connection

3. Example of successful requests
    <pre>
    Status Code: 200
    Non-JSON response: data: [DONE]
    Buitenzorg is the former name of Bogor, a city in West Java, Indonesia. The name "Buitenzorg" is Dutch and translates to "without a care" or "carefree" in English. It was given to the city by the Dutch East India Company in the 18th century, when the city was a popular retreat for Dutch colonizers due to its cool climate and scenic beauty.

    During the Dutch colonial period, Buitenzorg was the summer residence of the Governor-General of the Dutch East Indies, and it was a major center for botanical research and agriculture. The city was home to the famous Buitenzorg Botanical Gardens, which were established in 1817 and are now known as the Bogor Botanical Gardens.

    After Indonesia gained independence in 1945, the city was renamed Bogor, which is derived from the Sundanese word "bogor," meaning "tree" or "forest." Today, Bogor is a thriving city with a rich cultural heritage and a strong focus on education, research, and tourism.</pre>

## GCP Vertex AI Model ID

Below is a list of GCP Vertex AI model IDs that can be used in this one-line script.

| Provider        | Model Name                    | Release Date | Model ID                                  |
|-----------------|-------------------------------|--------------|-------------------------------------------|
| **Meta**        | Llama 3.1-405b-instruct-maas  | 2024-10-18   | meta/llama-3.1-405b-instruct-maas         |
| **Google**      | Gemini 1.0                    | 2024-02-15   | gemini-1.0-pro                            |

## (Optional) Test the Deployed Model

If you want to run serverless-llama-3-1.py by changing the prompting, you can follow this flow.

1. Ensure you have .env files, my_venv, and codehub folder in your working directory and already activated my_venv.

   - Linux, WSL and MacOS Version (UNIX)

     ```bash
     source my_venv/bin/activate
     ```

   - Windows Version
     ```bash
     source my_venv/Scripts/activate
     ```
2. Update the `serverless-llama-3-1.py` file at line 34 in the `{"role": "user", "content": "What is Buitenzorg?"}` section.
   - Linux, WSL
     ```bash
     sed -i 's/What is Buitenzorg/Show Hello World!/' codehub/gcp-ai/serverless-llama-3-1.py
     ```
   - MacOS
     ```bash
     sed -i '' 's/What is Buitenzorg/Show Hello World!/' codehub/gcp-ai/serverless-llama-3-1.py

   - Windows PowerShell
     ```bash
     (Get-Content "serverless-llama-3-1.py") -replace 'What is Buitenzorg', 'Show Hello World!' | Set-Content "serverless-llama-3-1.py"
     ```
2. Run the script

   - Linux, WSL and MacOS Version (UNIX)
     ```bash
     python3 codehub/gcp-ai/serverless-llama-3-1.py
     ```
   - Windows Version
     ```bash
     python codehub/gcp-ai/serverless-llama-3-1.py
     ```

3. Example of successful requests
    <pre>
    Status Code: 200
    Non-JSON response: data: [DONE]
    Hello World!</pre>

## Cost GCP Vertex AI for Serverless
Deploying models on GCP Vertex AI incurs costs based on the specific models you use and the number of tokens processed. 
[GCP Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing/)

## Included Scripts:

- [serverless-gemini1-0.py](serverless-gemini1-0.py) : Script to deploy using model Gemini 1.0

- [serverless-llama-3-1.py](serverless-llama-3-1.py) : Script to deploy using model Llama 3.1


## References

1. Documentation : [GCP AI: Serverless API Endpoint](https://docs.google.com/document/d/1cXRjv34uXjluQzyRu027r5ax8GT-HOw3naMSPi8aeVs/edit?usp=sharing)

## Notes

If you experience any problems, please do not hesitate to contact us at [Ticket GDPLabs](https://docs.google.com/document/d/1cXRjv34uXjluQzyRu027r5ax8GT-HOw3naMSPi8aeVs/edit#heading=h.3bryigm0r34y).
