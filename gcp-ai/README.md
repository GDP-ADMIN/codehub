# GCP Vertex AI Serverless Model Deployment

This project contains scripts to  run models via GCP Vertex AI Serverless API endpoints.

## Prerequisites

Before running the scripts, ensure that you have the following:

1. For Windows users, you can use WSL to run the script. Please make sure you have installed WSL first. For Linux and macOS users, you can run the script directly.
2. **Service Account (*.json)**, **Enable Vertex AI API**: To access the GCP Account (Service Account) with Vertex AI Administrator roles, contact our [ticket system](https://docs.google.com/document/d/1cXRjv34uXjluQzyRu027r5ax8GT-HOw3naMSPi8aeVs/edit#heading=h.3bryigm0r34y) The administrator must enable the Vertex AI API in the target GCP Project (this is a one-time setup).
Note: The ticket system email address is hidden to prevent phishing and spam. For the Llama 3.1 API Service model, ensure this API is also enabled.
3. **Setup environment variables**: Copy the [.env.example](/gcp-ai/.env.example) file to your working folder and rename it to `.env` Follow the instructions in the `.env` file to fill in the required values.
4. **Active Directory**: Ensure that the `.env` file and Service Account file `(*.json)` provided by the Infra Team are placed in your active directory. Below is an example of the directory structure: \
  Notes : You do not need to change the name of the Service Account file `(*.json)` provided by the Infra Team
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
    ├── dso-bukhori.json
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
    Buitenzorg is the Dutch name for the city of Bogor, Indonesia.
    The name 'Buitenzorg' is derived from the Dutch words 'buiten' meaning 'outside' and 'zorg' meaning 'care' or 'worry'. It was named so because it was a place of relaxation and
    retreat for the Dutch colonial rulers, away from the worries and cares of their administrative duties in the capital city of Batavia (now Jakarta).

    During the Dutch colonial
    period, Buitenzorg was a popular hill station and resort town, known for its cool climate, beautiful gardens, and scenic views. The city was also home to the famous Buitenzorg Botanical Gardens, which were established in
    1817 and are still one of the largest and most important botanical gardens in Southeast Asia.

    After Indonesia gained independence in 1945, the city was renamed Bogor, which is the Sundanese word for 'fog' or
    'mist', reflecting the city's cool and misty climate. Today, Bogor is a thriving city and a popular tourist destination, known for its natural beauty, cultural attractions, and historical landmarks.

    Non-JSON response: data: [DONE]
    Python script executed successfully.</pre>

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
    Here
    's a "Hello, World!" example in several programming languages:


    ### Python

    ```python
    # This is a Hello World program in Python

    def main():

        print("Hello, World!")

    if __name__ == "__main__":
        main()
    ```

    ### Java
    ```java
    // This is a Hello World
    program in Java

    public class HelloWorld {
        public static void main(String[] args) {
            System.out.println("Hello, World!");
        }
    }
    ```


    ### JavaScript
    ```javascript
    // This is a Hello World program in JavaScript

    console.log("Hello, World!");
    ```

    ### C++
    ```cpp
    // This is a Hello World program in C++

    #include <iostream>

    int main()
    {
        std::cout << "Hello, World!" << std::endl;
        return 0;
    }
    ```

    ### C#
    ```csharp
    // This is a Hello World program in C#

    using System;

    class HelloWorld 
    {

        static void Main(string[] args) 
        {
            Console.WriteLine("Hello, World!");    
        }
    }
    ```

    To run any of these examples, you would need to have the respective language installed on your system. You can then copy the code into a file with the correct file extension (e.g., .
    py for Python, .java for Java, etc.) and run it using the language's command-line interface or an Integrated Development Environment (IDE).

    Non-JSON response: data: [DONE]
    </pre>

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
