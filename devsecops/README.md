# SSH Key Generator for GitHub
[create_ssh_key_github.sh](create_ssh_key_github.sh) generates a new SSH key pair and outputs the public key. You can easily add the generated public key to your GitHub account by following the provided instructions.

## Features

- Generate an SSH key pair.
- Optionally associate an email address with the SSH key.
- Output the public key for easy copying.
- Clear instructions for adding the key to your GitHub account.

## Installation & Usage
```bash
curl -O https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/create_ssh_key_github.sh && bash create_ssh_key_github.sh [-e <email>] [-k <key_name>]
```

## Adding SSH Keys to GitHub
- Open https://github.com/settings/keys
- Click 'New SSH Key'
- Put a Title, select 'Key type: Authentication Key', and paste your SSH key
- Click 'Add SSH key'