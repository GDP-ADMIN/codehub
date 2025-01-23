import os
import subprocess
from github import Github
import logging
from datetime import datetime
import time
import csv
from dotenv import load_dotenv
import requests
import re
import shutil

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
GITHUB_ORG = os.getenv('GITHUB_ORG')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
BASE_URL = "https://api.github.com"
CLONE_DIR = "cloned_repos"

def wait_for_rate_limit(g):
    """Wait if we're close to hitting the rate limit"""
    rate_limit = g.get_rate_limit()
    if rate_limit.core.remaining < 100:
        wait_time = (rate_limit.core.reset - datetime.utcnow()).total_seconds()
        logger.info(f"Rate limit low. Waiting {wait_time:.2f} seconds...")
        time.sleep(wait_time + 1)

def get_count_from_link_header(link_header):
    """Extract the total count from GitHub's Link header"""
    if not link_header:
        return None

    # Find the last page number in the "last" link
    match = re.search(r'page=(\d+)>; rel="last"', link_header)
    if match:
        return int(match.group(1))
    return None

def get_total_count_from_response(response):
    """Get total count from response"""
    # First try to get count from Link header
    link_header = response.headers.get('Link')
    if link_header:
        last_page = get_count_from_link_header(link_header)
        if last_page:
            # GitHub API returns 100 items per page
            if response.url.endswith(f'page={last_page}'):
                return (last_page - 1) * 100 + len(response.json())
            return last_page * 100

    # If no Link header or couldn't parse it, count items in response
    return len(response.json())

def get_fast_issue_counts(repo, token):
    """Get issue counts using repository statistics"""
    try:
        headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json'
        }

        base_url = f"https://api.github.com/repos/{repo.owner.login}/{repo.name}/issues"

        # Get open issues count (excluding PRs)
        open_response = requests.get(
            f"{base_url}?state=open&per_page=100&pulls=false",
            headers=headers
        )
        open_count = get_total_count_from_response(open_response)

        # Get closed issues count (excluding PRs)
        closed_response = requests.get(
            f"{base_url}?state=closed&per_page=100&pulls=false",
            headers=headers
        )
        closed_count = get_total_count_from_response(closed_response)

        # Calculate total
        total_count = open_count + closed_count

        return {
            'total': total_count,
            'open': open_count,
            'closed': closed_count
        }
    except Exception as e:
        logger.error(f"Error getting issues for {repo.name}: {e}")
        return {'total': 0, 'open': 0, 'closed': 0}

def get_fast_pr_counts(repo, token):
    """Get PR counts using repository statistics"""
    try:
        headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json'
        }

        base_url = f"https://api.github.com/repos/{repo.owner.login}/{repo.name}/pulls"

        # Get all PRs count
        response = requests.get(
            f"{base_url}?state=all&per_page=100",
            headers=headers
        )
        return get_total_count_from_response(response)

    except Exception as e:
        logger.error(f"Error getting PRs for {repo.name}: {e}")
        return 0

def get_exclude_patterns():
    """Get comprehensive exclude patterns for different languages and frameworks."""
    exclude_dirs = [
        # Build and Dependencies
        'node_modules', 'vendor', 'dist', 'build', 'packages', 'bower_components',

        # Java related
        'target', '.gradle', 'out', 'classes', '.idea', '.settings', 'bin',

        # Python related
        '__pycache__', '.pytest_cache', '.coverage', '.tox', '.mypy_cache',
        'htmlcov', '.ipynb_checkpoints', 'venv', 'env', '.venv',

        # Rust related
        '.cargo', 'debug', 'release',

        # Version Control
        '.git', '.svn', '.hg',

        # Framework specific
        '.next', '.nuxt', 'migrations',

        # IDE and Editor
        '.vscode', '.idea', '.eclipse',

        # Documentation
        'docs', 'doc', 'documentation',

        # Common test directories
        'tests', 'test', 'testing', '__tests__', '__test__',

        # Temp and Cache
        'tmp', 'temp', 'cache', '.cache',

        # Log directories
        'logs', 'log'
    ]

    exclude_files = [
        # Minified and Generated JavaScript/CSS
        "'*.min.js'", "'*.min.css'", "'*.bundle.js'", "'*.bundle.css'",
        "'*.chunk.js'", "'*.chunk.css'", "'*.vendor.js'", "'*.vendor.css'",

        # Source Maps
        "'*.map'",

        # Lock Files
        "'package-lock.json'", "'yarn.lock'", "'composer.lock'", "'Cargo.lock'",

        # Compiled Files
        "'*.class'", "'*.jar'", "'*.war'", "'*.ear'",
        "'*.pyc'", "'*.pyo'", "'*.pyd'",
        "'*.rlib'", "'*.rmeta'", "'*.o'", "'*.d'",

        # Configuration Files
        "'*.config.js'", "'webpack.config.js'", "'babel.config.js'",

        # Log Files
        "'*.log'",

        # Documentation
        "'*.md'", "'*.txt'", "'*.pdf'",

        # IDE Files
        "'.classpath'", "'.project'", "'*.iml'",

        # Database Files
        "'*.sqlite'", "'*.db'", "'*.sql'",

        # Common Data Files
        "'*.json'", "'*.xml'", "'*.yaml'", "'*.yml'"
    ]

    return exclude_dirs, exclude_files

def count_lines_in_repo(repo_dir):
    """Count lines of code in a repository using both cloc and wc -l."""
    try:
        print("Counting lines of code...")

        # Get total lines using find and wc -l
        total_cmd = [
            "bash", "-c",
            "find . -type f -not -path '*/\.*' -exec cat {} + | wc -l"
        ]

        # Get filtered count with cloc
        exclude_dirs, exclude_files = get_exclude_patterns()
        filtered_cmd = [
            "cloc",
            ".",
            "--json",
            "--exclude-dir=" + ','.join(exclude_dirs),
            "--not-match-f=(" + '|'.join(exclude_files) + ")"
        ]

        print(f"Running filtered count with cloc...")
        print(f"Excluded directories: {', '.join(exclude_dirs)}")
        print(f"Excluded file patterns: {', '.join(exclude_files)}")

        # Get total line count
        print("Getting total line count...")
        total_result = subprocess.run(
            total_cmd,
            cwd=repo_dir,
            capture_output=True,
            text=True,
            check=True
        )
        total_lines = int(total_result.stdout.strip())

        # Get filtered count
        filtered_result = subprocess.run(
            filtered_cmd,
            cwd=repo_dir,
            capture_output=True,
            text=True,
            check=True
        )

        import json
        filtered_data = json.loads(filtered_result.stdout)
        filtered_stats = {
            'code': filtered_data['SUM']['code'] if 'SUM' in filtered_data else 0,
            'blank': filtered_data['SUM']['blank'] if 'SUM' in filtered_data else 0,
            'comment': filtered_data['SUM']['comment'] if 'SUM' in filtered_data else 0
        }

        # Log the results
        logger.info("\nTeam Code Summary (from cloc):")
        logger.info(f"Filtered code lines:    {str(filtered_stats['code'])}")
        logger.info(f"Filtered comment lines: {str(filtered_stats['comment'])}")
        logger.info(f"Total filtered lines:   {str(filtered_stats['code'] + filtered_stats['comment'])}")

        logger.info("\nTotal Repository Summary (from wc -l):")
        logger.info(f"Total lines: {str(total_lines)}")

        return {
            'filtered': filtered_stats['code'],
            'total': total_lines
        }

    except Exception as e:
        print(f"Error counting lines: {e}")
        if 'filtered_result' in locals():
            print(f"Filtered command output: {filtered_result.stdout}")
            print(f"Filtered error output: {filtered_result.stderr}")
        if 'total_result' in locals():
            print(f"Total command output: {total_result.stdout}")
            print(f"Total error output: {total_result.stderr}")
        return {'filtered': 0, 'total': 0}

def clone_repository(repo_url, dest_dir):
    """Clone a Git repository."""
    try:
        print(f"Cloning into {dest_dir}")
        subprocess.run(
            ["git", "clone", repo_url.replace("https://", f"https://{GITHUB_TOKEN}@"), dest_dir],
            check=True
        )
        print("Clone completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to clone {repo_url}: {e}")
        return False

def cleanup_repository(repo_dir):
    """Remove a cloned repository directory."""
    try:
        if os.path.exists(repo_dir):
            print(f"Cleaning up {repo_dir}")
            shutil.rmtree(repo_dir)
    except Exception as e:
        print(f"Error during cleanup of {repo_dir}: {e}")

def main():
    token = os.getenv('GITHUB_TOKEN')
    org_name = os.getenv('GITHUB_ORG')

    if not token or not org_name:
        logger.error("Please set GITHUB_TOKEN and GITHUB_ORG environment variables")
        return

    # Create clone directory
    os.makedirs(CLONE_DIR, exist_ok=True)

    g = Github(token)
    org = g.get_organization(org_name)
    results = []

    try:
        # Get all repositories
        repos = list(org.get_repos())
        total_repos = len(repos)
        logger.info(f"Found {total_repos} repositories")

        # Process repositories
        for idx, repo in enumerate(repos, 1):
            logger.info(f"\nProcessing repository {idx}/{total_repos}: {repo.name}")
            logger.info("=" * 80)

            dest_dir = os.path.join(CLONE_DIR, repo.name)

            try:
                # Clone and count lines
                if clone_repository(repo.clone_url, dest_dir):
                    lines_of_code = count_lines_in_repo(dest_dir)
                else:
                    lines_of_code = {'filtered': 0, 'total': 0}

                # Get issues and PRs
                wait_for_rate_limit(g)
                issue_counts = get_fast_issue_counts(repo, token)
                pr_count = get_fast_pr_counts(repo, token)

                result = {
                    'repository': repo.name,
                    'filtered_lines_of_code': lines_of_code['filtered'],
                    'total_lines_of_code': lines_of_code['total'],
                    'total_issues': issue_counts['total'],
                    'open_issues': issue_counts['open'],
                    'closed_issues': issue_counts['closed'],
                    'pull_requests': pr_count,
                    'last_updated': repo.updated_at.strftime('%Y-%m-%d')
                }
                results.append(result)

                logger.info(f"Filtered Lines of Code: {lines_of_code['filtered']}")
                logger.info(f"Total Lines of Code: {lines_of_code['total']}")
                logger.info(f"Total Issues: {issue_counts['total']}")
                logger.info(f"Open Issues: {issue_counts['open']}")
                logger.info(f"Closed Issues: {issue_counts['closed']}")
                logger.info(f"Pull Requests: {pr_count}")

            finally:
                cleanup_repository(dest_dir)

        # Calculate totals
        total_filtered_loc = sum(r['filtered_lines_of_code'] for r in results)
        total_unfiltered_loc = sum(r['total_lines_of_code'] for r in results)
        total_issues = sum(r['total_issues'] for r in results)
        open_issues = sum(r['open_issues'] for r in results)
        closed_issues = sum(r['closed_issues'] for r in results)
        total_prs = sum(r['pull_requests'] for r in results)
        filtered_percentage = (total_filtered_loc / total_unfiltered_loc * 100) if total_unfiltered_loc > 0 else 0
        other_code_percentage = 100 - filtered_percentage

        # Print totals
        logger.info("\nCode Analysis:")
        logger.info("Total Lines of Code (sum of all files in repositories)")
        logger.info(f"└── Total:                     {total_unfiltered_loc:,} lines (100%)")
        logger.info(f"    ├── Own Written Code:      {total_filtered_loc:,} lines ({filtered_percentage:.1f}%)")
        logger.info(f"    │   └── Excludes: vendor, node_modules, generated files, etc.")
        logger.info(f"    └── Open Source Code:      {total_unfiltered_loc - total_filtered_loc:,} lines ({other_code_percentage:.1f}%)")
        logger.info(f"        └── Includes: dependencies, packages, generated code")

        logger.info("\nIssues and PRs:")
        logger.info(f"Total Issues:    {total_issues:,}")
        logger.info(f"Open Issues:     {open_issues:,} ({(open_issues/total_issues*100 if total_issues > 0 else 0):.1f}%)")
        logger.info(f"Closed Issues:   {closed_issues:,} ({(closed_issues/total_issues*100 if total_issues > 0 else 0):.1f}%)")
        logger.info(f"Pull Requests:   {total_prs:,}")

        # Save results to CSV
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f'github_metrics_{org_name}_{timestamp}.csv'

        with open(filename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=[
                'repository',
                'filtered_lines_of_code',
                'total_lines_of_code',
                'total_issues',
                'open_issues',
                'closed_issues',
                'pull_requests',
                'last_updated'
            ])
            writer.writeheader()
            writer.writerows(results)

        logger.info(f"\nResults saved to {filename}")

    except Exception as e:
        logger.error(f"Error: {e}")
    finally:
        # Clean up clone directory
        cleanup_repository(CLONE_DIR)

if __name__ == "__main__":
    main()