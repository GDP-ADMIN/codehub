# Amazon Bedrock Serverless Model Deployment

This project contains scripts to  deploy models via Amazon Bedrock.

## Prerequisites

Before running the scripts, ensure that you have the following:

1. **AWS Credentials (Access Key and Secret Key)**: Contact our `Ticket System` to get AWS Credentials with Amazon Bedrock Administrator permission \
   Notes : We hide the ticket system email address to prevent phishing and spamming.
2. **Setup environment variables**: Copy this [.env.example](/aws-ai/.env.example) file as `.env` file on your working folder and follow the instructions in the `.env` file to fill in the required values.

## Setup and Installation

1. **Run 1-click CLI script**

   - Linux, WSL and MacOS Version (UNIX)

   ```bash
   curl -o setup_aws_ai.sh https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/aws-ai/setup_aws_ai.sh && chmod 755 setup_aws_ai.sh && bash setup_aws_ai.sh
   ```

   - Windows Version

   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/aws-ai/setup_aws_ai.sh" -OutFile "setup_aws_ai.sh" 
   wsl ./setup_aws_ai.sh
   ```
   **Notes** : Execution time will take about up to 15 minutes depending your internet connection

3. Example of successful requests
   <pre>
    Model ID: meta.llama2-13b-chat-v1
    Prompt: Hello, Siapa Presiden Indonesia ke-4 ?
    Response: 
    
    Siapa Presiden Indonesia ke-4 ?
    
    Jawaban: Abdurrahman Wahid.
    
    Kenali lebih lanjut tentang Abdurrahman Wahid, Presiden Indonesia ke-4, di bawah ini :
    
    Nama Lengkap : Abdurrahman Wahid
    
    Lahir : 4 September 1940 di Jombang, Jawa Timur
    
    Meninggal : 30 December 2009 di Jakarta
    
    Pendidikan : Universitas Islam Indonesia (UI)
    
    Pengalaman Politik :
    
    * Anggota Dewan Perwakilan Rakyat (DPR) dari Partai Kebangkitan Bangsa (PKB)
    * Ketua Umum PKB
    * Menteri Agama dan Pendidikan Tinggi dalam kabinet Presiden Bacharuddin Jusuf Habibie
    * Presiden Republik Indonesia periode 1999-2001
    
    Kepribadian :
    
    * Abdurrahman Wahid dikenal sebagai tokoh yang memiliki visi dan mision untuk membangun Indonesia yang lebih demokratis dan berkembang.
    * Ia juga dikenal sebagai tokoh yang memiliki kepribadian yang santai dan mudah dipahami.
    
    Peranan :
    
    * Abdurrahman Wahid memiliki peranan yang signifikan dalam sejarah Indonesia, terutama dalam meningkatkan demokrasi dan meningkatkan kesadaran bangsa.
    * Ia juga memiliki peranan dalam mengembangkan pendidikan dan agama di Indonesia.
    
    Siapa Presiden Indonesia ke-4 ?
    
    Jawaban : Abdurrahman Wahid.
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
| **Meta**        | Llama 2 Chat 13B              | 1.x     | meta.llama2-13b-chat-v1                   |
| **Meta**        | Llama 2 Chat 70B              | 1.x     | meta.llama2-70b-chat-v1                   |
| **Meta**        | Llama 3 8B Instruct           | 1.x     | meta.llama3-8b-instruct-v1:0              |
| **Meta**        | Llama 3 70B Instruct          | 1.x     | meta.llama3-70b-instruct-v1:0             |
| **Meta**        | Llama 3.1 8B Instruct         | 1.x     | meta.llama3-1-8b-instruct-v1:0            |
| **Mistral AI**  | Mistral 7B Instruct           | 0.x     | mistral.mistral-7b-instruct-v0:2          |
| **Mistral AI**  | Mixtral 8X7B Instruct         | 0.x     | mistral.mixtral-8x7b-instruct-v0:1        |
| **Mistral AI**  | Mistral Large                 | 1.x     | mistral.mistral-large-2402-v1:0           |

## (Optional) Test the Deployed Model

If you want to run bedrock.py by changing the prompting, you can follow this flow.

1. Update the `bedrock.py` file at line 209 in the `default="Hello World"` section.
   - Linux, WSL
     ```bash
     sed -i 's/Hello, Siapa Presiden Indonesia ke-4 ?/Show Hello World!/' bedrock.py
     ```
   - MacOS
     ```bash
     sed -i '' 's/Hello, Siapa Presiden Indonesia ke-4 ?/Show Hello World!/' bedrock.py
     ```
   - Windows PowerShell
     ```bash
     (Get-Content "bedrock.py") -replace 'Hello, Siapa Presiden Indonesia ke-4 ?', 'Show Hello World!' | Set-Content "bedrock.py"
     ```
2. Run the script

   - Linux, WSL and MacOS Version (UNIX)
     ```bash
     python3 bedrock.py
     ```
   - Windows Version
     ```bash
     python bedrock.py
     ```

3. Example of successful requests
    <pre>
    Model ID: meta.llama2-13b-chat-v1
    Prompt: Show Hello World!
    Response: 
    
    Hello World!
    
    This is a simple "Hello World!" program that demonstrates the basic syntax of a Python program.
    
    Here's the code:
    ```
    print("Hello World!")
    ```
    Explanation:
    
    * `print()` is a function that prints a message to the screen.
    * `"Hello World!"` is the message we want to print.
    
    When we run this program, we should see the message "Hello World!" in the output window.
    
    That's it! This is the most basic Python program you can write.
    </pre>


## Cost Amazon Bedrock for Serverless
Deploying models on AWS Bedrock incurs costs based on the specific models you use and the number of tokens processed. 
[Amazon Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)

## Included Scripts:

- [bedrock.py](bedrock.py) : Script to deploy and manage Bedrock models on AWS AI services. 

- [setup_aws_ai](setup_aws_ai.py) : Shell script to set up the AWS AI environment and install necessary dependencies. 

## References

1. Documentation : [Amazon Bedrock](https://docs.google.com/document/d/12TFRlDmOXE0hoB6HZBs_hfdHtXI4ja-oF2bQ71EMUk8/edit?usp=sharing)

## Notes

If you experience any problems, please do not hesitate to contact us at `Ticket GDPLabs`.