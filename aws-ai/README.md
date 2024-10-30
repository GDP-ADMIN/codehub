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
    Model ID: meta.llama3-1-8b-instruct-v1:0
    Prompt: Siapa presiden ke-4 Indonesia?
    Response:  Presiden ke-4 Indonesia adalah Abdurrahman Wahid. Ia menjabat dari tahun 1999 hingga 2001. Abdurrahman Wahid atau yang lebih dikenal dengan Gus Dur, lahir pada tanggal 7 September 1924 di Jombang, Jawa Timur. Ia merupakan seorang ulama, intelektual, dan politikus yang memiliki peran penting dalam sejarah Indonesia. Gus Dur dikenal sebagai presiden pertama yang tidak berasal dari militer atau kalangan elit politik tradisional. Ia dipilih sebagai presiden pada tahun 1999 melalui proses pemilihan yang demokratis dan menjadi simbol perubahan politik di Indonesia pada saat itu. Selama masa jabatannya, Gus Dur berusaha meningkatkan demokrasi, mengurangi ketimpangan sosial ekonomi, dan memperkuat keberagaman budaya di Indonesia. Sayangnya, masa jabatannya singkat dan berakhir pada tahun 2001 karena keterlibatannya dalam skandal korupsi dan krisis politik yang melanda Indonesia pada saat itu. Meskipun demikian, Gus Dur tetap diingat sebagai salah satu presiden yang paling berpengaruh dan berperan penting dalam sejarah Indonesia. Ia meninggal pada tanggal 30 Desember 2009 di Jakarta. Gus Dur dikenal sebagai seorang pemimpin yang berani, visioner, dan memiliki kekuatan spiritual yang kuat. Ia terus menjadi inspirasi bagi banyak orang di Indonesia dan di seluruh dunia. Karena itu, Abdurrahman Wahid atau Gus Dur tetap diingat sebagai salah satu presiden yang paling berpengaruh dan berperan penting dalam sejarah Indonesia. Ia meninggalkan warisan yang abadi dan terus menjadi inspirasi bagi generasi-generasi mendatang. Ia adalah presiden ke-4 Indonesia yang paling berpengaruh dan berperan penting dalam sejarah Indonesia. Ia meninggalkan warisan yang abadi dan terus menjadi inspirasi bagi banyak orang di Indonesia dan di seluruh dunia. Ia adalah presiden ke-4 Indonesia yang paling berpengaruh dan berperan penting dalam sejarah Indonesia. Ia meninggalkan warisan yang abadi
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

1. Update the `bedrock.py` file at line 209 in the `default="Hello World"` section.
   - Linux, WSL
     ```bash
     sed -i 's/Siapa presiden ke-4 Indonesia?/Show Hello World!/' bedrock.py
     ```
   - MacOS
     ```bash
     sed -i '' 's/Siapa presiden ke-4 Indonesia?/Show Hello World!/' bedrock.py
     ```
   - Windows PowerShell
     ```bash
     (Get-Content "bedrock.py") -replace 'Siapa presiden ke-4 Indonesia?', 'Show Hello World!' | Set-Content "bedrock.py"
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
    Model ID: meta.llama3-1-8b-instruct-v1:0
    Prompt: Show Hello World!
    Response:  in Python
    # -*- coding: utf-8 -*-
    """
    Created on Mon Mar  7 14:35:23 2022
    
    @author: user
    """
    
    # Importing the required libraries
    import tkinter as tk
    from tkinter import messagebox
    
    # Creating the main window
    root = tk.Tk()
    root.title("Hello World!")
    
    # Creating a label and a button
    label = tk.Label(root, text="Hello World!")
    button = tk.Button(root, text="Click me!", command=lambda: messagebox.showinfo("Hello World!", "You clicked the button!"))
    
    # Packing the label and the button
    label.pack()
    button.pack()
    
    # Starting the main loop
    root.mainloop()  # This is where the magic happens!  # noqa: E501
    ```
    
    This code creates a simple GUI application with a label and a button. When the button is clicked, a message box appears with the text "You clicked the button!". The `mainloop` method is what makes the GUI appear on the screen and start listening for events.
    
    ### Step 2: Run the code
    
    To run the code, save it to a file with a `.py` extension (e.g., `hello_world.py`) and run it using Python (e.g., `python hello_world.py`). This will launch the GUI application.
    
    ### Step 3: Interact with the GUI
    
    Click the button to see the message box appear. You can close the message box by clicking the "OK" button.
    
    ### Step 4: Customize the GUI
    
    You can customize the GUI by modifying the code. For example, you can change the text of the label and button, add more widgets, or change the layout of the GUI.
    
    ### Step 5: Learn more about Tkinter
    
    Tkinter is a powerful library for creating GUI applications in Python. You can learn more about it by reading the official documentation or exploring online resources. Some useful resources include:
    
    * The official Tkinter documentation: <https://docs.python.org/3/library/tk.html>
    * The Tkinter tutorial on Real Python: <https://realpython.com/python-gui-tkinter/>
    * The Tkinter documentation on W3Schools: <https://www.w3schools.com/python/python_gui_tkinter.asp>
    
    ### Step 6: Practice creating GUI applications
    
    Practice creating GUI applications using Tkinter. Start with simple applications and gradually move on to more complex ones. Experiment with different widgets, layouts, and features to become proficient in creating GUI applications.  # noqa
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