from e2b import Sandbox
import logging
import subprocess
import json
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Set up logging
logging.basicConfig(level=logging.DEBUG)

# Configuration from environment variables
E2B_API_KEY = os.getenv("E2B_API_KEY")
E2B_ACCESS_TOKEN = os.getenv("E2B_ACCESS_TOKEN")
DOMAIN = os.getenv("DOMAIN", "glair.id")  # Default fallback

# Validate required environment variables
if not E2B_API_KEY:
    raise ValueError("E2B_API_KEY environment variable is required")
if not E2B_ACCESS_TOKEN:
    raise ValueError("E2B_ACCESS_TOKEN environment variable is required")

def create_sandbox(template="base"):
    """Create a new sandbox using Python SDK"""
    try:
        print(f"Creating sandbox with template: {template}")
        sandbox = Sandbox(
            api_key=E2B_API_KEY,
            domain=DOMAIN,
            template=template
        )
        print("Sandbox created successfully!")
        print(f"Sandbox ID: {sandbox.sandbox_id}")
        return sandbox
    except Exception as e:
        print(f"Error creating sandbox: {e}")
        import traceback
        traceback.print_exc()
        return None

def check_e2b_templates():
    """Check available e2b templates"""
    try:
        print("Checking available e2b templates...")
        # Common e2b templates
        templates = [
            "base",
            "node",
            "python",
            "react",
            "nextjs",
            "vue",
            "angular",
            "django",
            "flask",
            "fastapi"
        ]
        print("Available templates:")
        for template in templates:
            print(f"  - {template}")
        return templates
    except Exception as e:
        print(f"Error checking templates: {e}")
        import traceback
        traceback.print_exc()
        return []

def authenticate_cli():
    """Authenticate with e2b CLI using access token"""
    try:
        print("Authenticating with e2b CLI...")
        
        # Set the access token as environment variable
        env = os.environ.copy()
        env['E2B_ACCESS_TOKEN'] = E2B_ACCESS_TOKEN
        
        # Run e2b auth login with token
        cmd = ['e2b', 'auth', 'login', '--token', E2B_ACCESS_TOKEN]
        
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        
        if result.returncode == 0:
            print("Authentication successful!")
            print(f"Output: {result.stdout}")
            return True
        else:
            print(f"Authentication failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"Error during authentication: {e}")
        import traceback
        traceback.print_exc()
        return False

def create_sandbox_cli(template="base"):
    """Create a new sandbox using e2b CLI"""
    try:
        print(f"Creating sandbox with template: {template}")
        
        # Set the access token as environment variable
        env = os.environ.copy()
        env['E2B_ACCESS_TOKEN'] = E2B_ACCESS_TOKEN
        
        # Run e2b sandbox create command - using correct syntax
        cmd = [
            'e2b', 'sandbox', 'create',
            '--template', template,
            '--domain', DOMAIN
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        
        if result.returncode == 0:
            print("Sandbox created successfully!")
            print(f"Output: {result.stdout}")
            return result.stdout
        else:
            print(f"Error creating sandbox: {result.stderr}")
            return None
            
    except Exception as e:
        print(f"Error creating sandbox: {e}")
        import traceback
        traceback.print_exc()
        return None

def check_existing_sandbox_cli(sandbox_id=None):
    """Check existing sandboxes using e2b CLI"""
    try:
        print("Checking existing sandboxes...")
        
        # Set the access token as environment variable
        env = os.environ.copy()
        env['E2B_ACCESS_TOKEN'] = E2B_ACCESS_TOKEN
        
        if sandbox_id:
            # Check specific sandbox
            cmd = ['e2b', 'sandbox', 'get', sandbox_id]
        else:
            # List all sandboxes
            cmd = ['e2b', 'sandbox', 'list']
        
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        
        if result.returncode == 0:
            print("Sandbox information retrieved successfully!")
            print(f"Output: {result.stdout}")
            return result.stdout
        else:
            print(f"Error checking sandbox: {result.stderr}")
            return None
            
    except Exception as e:
        print(f"Error checking sandbox: {e}")
        import traceback
        traceback.print_exc()
        return None

def check_e2b_templates_cli():
    """Check available e2b templates using e2b CLI"""
    try:
        print("Checking available e2b templates...")
        
        # Set the access token as environment variable
        env = os.environ.copy()
        env['E2B_ACCESS_TOKEN'] = E2B_ACCESS_TOKEN
        
        # Run e2b template list command
        cmd = ['e2b', 'template', 'list']
        
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        
        if result.returncode == 0:
            print("Templates retrieved successfully!")
            print(f"Output: {result.stdout}")
            return result.stdout
        else:
            print(f"Error checking templates: {result.stderr}")
            return None
            
    except Exception as e:
        print(f"Error checking templates: {e}")
        import traceback
        traceback.print_exc()
        return None

def list_sandboxes_cli():
    """List all sandboxes using e2b CLI"""
    try:
        print("Listing all sandboxes...")
        
        # Set the access token as environment variable
        env = os.environ.copy()
        env['E2B_ACCESS_TOKEN'] = E2B_ACCESS_TOKEN
        
        # Run e2b sandbox list command
        cmd = ['e2b', 'sandbox', 'list']
        
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        
        if result.returncode == 0:
            print("Sandboxes listed successfully!")
            print(f"Output: {result.stdout}")
            return result.stdout
        else:
            print(f"Error listing sandboxes: {result.stderr}")
            return None
            
    except Exception as e:
        print(f"Error listing sandboxes: {e}")
        import traceback
        traceback.print_exc()
        return None

# Main execution
if __name__ == "__main__":
    # 0. Authenticate first
    print("=== Authenticating with e2b CLI ===")
    auth_success = authenticate_cli()
    
    if auth_success:
        # 1. Check available templates
        print("\n=== Checking Templates ===")
        templates = check_e2b_templates_cli()
        
        # 2. List existing sandboxes
        print("\n=== Listing Existing Sandboxes ===")
        existing_sandboxes = list_sandboxes_cli()
        
        # 3. Create a new sandbox
        print("\n=== Creating New Sandbox ===")
        new_sandbox = create_sandbox_cli(template="base")
        
        # 4. Check the created sandbox (if we have its ID)
        if new_sandbox:
            print("\n=== Checking Created Sandbox ===")
            # You would need to extract the sandbox ID from the creation output
            # This is a placeholder - you'd need to parse the output to get the ID
            check_existing_sandbox_cli()
    else:
        print("Authentication failed. Cannot proceed with CLI operations.")
        print("Trying Python SDK instead...")
        
        # Fallback to Python SDK
        print("\n=== Creating Sandbox with Python SDK ===")
        sandbox = create_sandbox(template="base")
        