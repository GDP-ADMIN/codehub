# Amazon Bedrock Serverless Model Deployment

This project contains scripts to  deploy models via Amazon Bedrock.

## Prerequisites

Before running the scripts, ensure that you have the following:

1. For Windows users, you can use WSL to run the script. Please make sure you have installed WSL first. For Linux and macOS users, you can run the script directly.
2. **AWS Credentials (Access Key and Secret Key)**: To access the AWS Credentials (Access Key and Secret Key) with Amazon Bedrock Full Access permission, please submit a request through our [ticket system](https://docs.google.com/document/d/12TFRlDmOXE0hoB6HZBs_hfdHtXI4ja-oF2bQ71EMUk8/edit?tab=t.0#heading=h.3bryigm0r34y).

**Email Subject**:
AWS Credentials in [Scope of Service at Team](https://docs.google.com/document/d/12TFRlDmOXE0hoB6HZBs_hfdHtXI4ja-oF2bQ71EMUk8/edit?tab=t.0#heading=h.yhcswoyvfkz4) for Amazon Bedrock

**Examples:** 
```
AWS Credentials in gl-exploration for Amazon Bedrock
```

**Email Body**:
```
Dear Infra Team,

I am requesting an AWS credentials setup in the **gl-exploration**(need to be change) account for use with Amazon Bedrock. This AWS credentials will enable us to proceed with the necessary configurations and integrations required for our Amazon Bedrock.

Could you please create and provide the AWS credentials at your earliest convenience? Once we have the AWS credentials details, we can move forward with the setup and testing steps.

Thank you for your support.
```

Notes : We hide the ticket system email address to prevent phishing and spamming.

3. **Setup environment variables**: Copy this [.env.example](/aws-ai/.env.example) file as `.env` file on your working folder and follow the instructions in the `.env` file to fill in the required values.

## Setup and Installation

1. **Run 1-click CLI script**

   - Linux, WSL and MacOS Version (UNIX)

   ```bash
   curl -o setup_aws_ai.sh https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/aws-ai/setup_aws_ai.sh && chmod 755 setup_aws_ai.sh && bash setup_aws_ai.sh
   ```
   **Notes** : Execution time will take about up to 1 minutes depending your internet connection

3. Example of successful requests
   <pre>
    ----------------------------------------
    Choose the model to deploy:
    ----------------------------------------
    1. Amazon - Titan Text G1 - Express (Version: 1.x)
    2. Amazon - Titan Text G1 - Lite (Version: 1.x)
    3. Anthropic - Claude (Version: 2.0)
    4. Anthropic - Claude (Version: 2.1)
    5. Anthropic - Claude Instant (Version: 1.x)
    6. Meta - Llama 3 8B Instruct (Version: 1.x)
    7. Meta - Llama 3 70B Instruct (Version: 1.x)
    8. Meta - Llama 3.1 8B Instruct (Version: 1.x)
    9. Mistral AI - Mistral 7B Instruct (Version: 0.x)
    10. Mistral AI - Mixtral 8X7B Instruct (Version: 0.x)
    11. Mistral AI - Mistral Large (Version: 1.x)
    Enter the number corresponding to the model: 4
    ----------------------------------------------------------------
    Selected Model: Anthropic - Claude (Version: 2.1)
    Model ID: anthropic.claude-v2:1
    Prompt: Siapa presiden ke-4 Indonesia?
    Response: Presiden ke-4 Indonesia adalah Abdurrahman Wahid. Beliau menjabat sebagai Presiden Indonesia dari tahun 1999 hingga 2001.
    
    Abdurrahman Wahid, yang akrab disapa Gus Dur, terpilih menjadi Presiden menggantikan BJ Habibie setelah pemilihan umum tahun 1999. Gus Dur merupakan tokoh penting dari organisasi Islam terbesar di Indonesia, Nahdlatul Ulama.
    
    Namun pada tahun 2001, Gus Dur dituntut untuk mundur dari jabatannya karena beberapa kontroversi dan tuduhan korupsi serta ketidakmampuannya mengendalikan krisis politik dan ekonomi yang terjadi saat itu. Jabatan pres
    
    AWS environment setup and bedrock.py script execution complete.
    Check 'setup.log' in '/home/ignatiussw/Documents/amzn-bedrock-tes/igncodehub' for detailed logs.
   </pre>
       
## Amazon Bedrock Model ID

Below is a list of Amazon Bedrock model IDs that can be used in this one-line script.

| Provider        | Model Name                    | Version | Model ID                                  |
|-----------------|-------------------------------|---------|-------------------------------------------|
| **Amazon**      | Titan Text G1 - Express       | 1.x     | amazon.titan-text-express-v1              |
| **Amazon**      | Titan Text G1 - Lite          | 1.x     | amazon.titan-text-lite-v1                 |
| **Anthropic**   | Claude                        | 2.0     | anthropic.claude-v2                       |
| **Anthropic**   | Claude                        | 2.1     | anthropic.claude-v2:1                     |
| **Anthropic**   | Claude Instant                | 1.x     | anthropic.claude-instant-v1               |
| **Meta**        | Llama 3 8B Instruct           | 1.x     | meta.llama3-8b-instruct-v1:0              |
| **Meta**        | Llama 3 70B Instruct          | 1.x     | meta.llama3-70b-instruct-v1:0             |
| **Meta**        | Llama 3.1 8B Instruct         | 1.x     | meta.llama3-1-8b-instruct-v1:0            |
| **Mistral AI**  | Mistral 7B Instruct           | 0.x     | mistral.mistral-7b-instruct-v0:2          |
| **Mistral AI**  | Mixtral 8X7B Instruct         | 0.x     | mistral.mixtral-8x7b-instruct-v0:1        |
| **Mistral AI**  | Mistral Large                 | 1.x     | mistral.mistral-large-2402-v1:0           |

## (Optional) Test the Deployed Model

If you want to run bedrock.py by changing the prompting, you can follow this flow.

1. Ensure you have .env files, my_venv folder in your working directory and already activated my_venv.

   - Linux, WSL and MacOS Version (UNIX)

     ```bash
     source my_venv/bin/activate
     ```
2. Update the `bedrock.py` file at line 209 in the `default="Hello World"` section.
   - Linux, WSL
     ```bash
     sed -i 's/Siapa presiden ke-4 Indonesia?/Show Hello World!/' bedrock.py
     ```
   - MacOS
     ```bash
     sed -i '' 's/Siapa presiden ke-4 Indonesia?/Show Hello World!/' bedrock.py
     ```
2. Run the script

   - Linux, WSL and MacOS Version (UNIX)
     ```bash
     python3 bedrock.py
     ```

3. Example of successful requests
    <pre>
    ----------------------------------------
    Choose the model to deploy:
    ----------------------------------------
    1. Amazon - Titan Text G1 - Express (Version: 1.x)
    2. Amazon - Titan Text G1 - Lite (Version: 1.x)
    3. Anthropic - Claude (Version: 2.0)
    4. Anthropic - Claude (Version: 2.1)
    5. Anthropic - Claude Instant (Version: 1.x)
    6. Meta - Llama 3 8B Instruct (Version: 1.x)
    7. Meta - Llama 3 70B Instruct (Version: 1.x)
    8. Meta - Llama 3.1 8B Instruct (Version: 1.x)
    9. Mistral AI - Mistral 7B Instruct (Version: 0.x)
    10. Mistral AI - Mixtral 8X7B Instruct (Version: 0.x)
    11. Mistral AI - Mistral Large (Version: 1.x)
    Enter the number corresponding to the model:4
    ----------------------------------------------------------------
    Selected Model: Anthropic - Claude (Version: 2.1)
    Model ID: anthropic.claude-v2:1
    Prompt: Show Hello World!
    Response: Hello World!
    </pre>


## Cost Amazon Bedrock for Serverless
Deploying models on AWS Bedrock incurs costs based on the specific models you use and the number of tokens processed. 
[Amazon Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)

## Included Scripts:

- [bedrock.py](bedrock.py) : Script to deploy and manage Bedrock models on AWS AI services. 

- [setup_aws_ai](setup_aws_ai.sh) : Shell script to set up the AWS AI environment and install necessary dependencies. 

## References

1. Documentation : [Amazon Bedrock AI Serverless](https://docs.google.com/document/d/12TFRlDmOXE0hoB6HZBs_hfdHtXI4ja-oF2bQ71EMUk8/edit?usp=sharing)

## Notes

If you experience any problems, please do not hesitate to contact us at [Ticket GDPLabs](https://docs.google.com/document/d/12TFRlDmOXE0hoB6HZBs_hfdHtXI4ja-oF2bQ71EMUk8/edit?tab=t.0#heading=h.3bryigm0r34y).
