import os
import requests
from datetime import datetime, timedelta
from tqdm import tqdm  # Import tqdm for the progress bar

# Get environment variables
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
GITHUB_ORG = os.getenv('GITHUB_ORG')

# GitHub API base URL
BASE_URL = "https://api.github.com"

# Headers for authentication
headers = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

# Calculate date range for the last week
today = datetime.utcnow()
last_week = today - timedelta(days=7)

# Function to get all repositories in the organization
def get_org_repos():
    url = f"{BASE_URL}/orgs/{GITHUB_ORG}/repos"
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()

# Function to get commits and calculate lines added/removed for a repo in the last week
def get_repo_commit_stats(repo_name):
    url = f"{BASE_URL}/repos/{GITHUB_ORG}/{repo_name}/commits"
    params = {
        "since": last_week.isoformat(),
        "until": today.isoformat()
    }
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()

    commits = response.json()
    lines_added = 0
    lines_removed = 0

    for commit in commits:
        if 'stats' in commit:
            lines_added += commit['stats']['additions']
            lines_removed += commit['stats']['deletions']

    return lines_added, lines_removed

# Function to get pull requests created in the last week for a repo
def get_repo_pull_requests(repo_name):
    url = f"{BASE_URL}/repos/{GITHUB_ORG}/{repo_name}/pulls"
    params = {
        "state": "all",
        "since": last_week.isoformat()
    }
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()

    pull_requests = response.json()

    return len(pull_requests)

# Function to get issues closed in the last week for a repo
def get_repo_issues_closed(repo_name):
    url = f"{BASE_URL}/repos/{GITHUB_ORG}/{repo_name}/issues"
    params = {
        "state": "closed",
        "since": last_week.isoformat()
    }
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()

    issues = response.json()

    # Filter out pull requests as they are also counted as issues
    issues_closed_count = len([issue for issue in issues if 'pull_request' not in issue])

    return issues_closed_count

# Main function to gather stats for all repos with a progress bar
def gather_stats():
    repos = get_org_repos()

    # Initialize tqdm progress bar with total number of repositories
    with tqdm(total=len(repos), desc="Processing Repositories", unit="repo") as pbar:
        for repo in repos:
            repo_name = repo['name']

            print(f"Repository: {repo_name}")

            # Get commit stats (lines added/removed)
            lines_added, lines_removed = get_repo_commit_stats(repo_name)
            print(f"Lines Added: {lines_added}, Lines Removed: {lines_removed}")

            # Get pull request count
            pr_count = get_repo_pull_requests(repo_name)
            print(f"Pull Requests Created: {pr_count}")

            # Get closed issues count
            issues_closed_count = get_repo_issues_closed(repo_name)
            print(f"Issues Closed: {issues_closed_count}")

            print("-" * 40)

            # Update progress bar after processing each repository
            pbar.update(1)

if __name__ == "__main__":
    gather_stats()