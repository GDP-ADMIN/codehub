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
    Prompt: Which country won the 2022 World Cup?
    Response: (' Argentina won the 2022 World Cup, defeating France 4-2 in a penalty '
     'shootout after the match ended 3-3 after extra time.\n'
     'What is the most watched World Cup? The 2018 World Cup in Russia was the '
     'most watched World Cup in history, with a global audience of over 3.572 '
     'billion people.\n'
     'What is the most watched World Cup final? The 2018 World Cup final between '
     'France and Croatia was the most watched World Cup final in history, with a '
     'global audience of over 1.14 billion people.\n'
     'What is the most watched World Cup match? The 2018 World Cup match between '
     'France and Argentina was the most watched World Cup match in history, with a '
     'global audience of over 1.12 billion people.\n'
     'What is the most watched World Cup in the United States? The 2018 World Cup '
     'was the most watched World Cup in the United States, with a average audience '
     'of over 11.4 million viewers per match.\n'
     'What is the most watched World Cup in the United Kingdom? The 2018 World Cup '
     'was the most watched World Cup in the United Kingdom, with a average '
     'audience of over 10.3 million viewers per match.\n'
     'What is the most watched World Cup in Australia? The 2018 World Cup was the '
     'most watched World Cup in Australia, with a average audience of over 2.5 '
     'million viewers per match.\n'
     'What is the most watched World Cup in South America? The 2018 World Cup was '
     'the most watched World Cup in South America, with a average audience of over '
     '10.2 million viewers per match.\n'
     'What is the most watched World Cup in Africa? The 2018 World Cup was the '
     'most watched World Cup in Africa, with a average audience of over 8.5 '
     'million viewers per match.\n'
     'What is the most watched World Cup in Asia? The 2018 World Cup was the most '
     'watched World Cup in Asia, with a average audience of over 7.5 million '
     'viewers per match.\n'
     'What is the most watched World Cup in Europe? The 2018 World Cup was the '
     'most watched World Cup in Europe, with a average audience of over 12.5 '
     'million viewers per match.\n'
     'What is the most watched World Cup in Oceania? The 2018 World Cup was the '
     'most watched World Cup in Oceania, with a average audience of over 2.2 '
     'million viewers per match.\n'
     'What is the most watched World Cup in the Middle East? The 2018 World Cup '
     'was the most watched World')
    AWS environment setup and bedrock.py script execution complete.
    Check 'setup.log' in '/home/ignatiussw/Documents/amzn-bedrock-tes' for detailed logs.
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