import os
import requests
from datetime import datetime, timedelta
from tqdm import tqdm  # Import tqdm for the progress bar

# Set up the environment variables
token = os.getenv("GITHUB_TOKEN")
org = os.getenv("GITHUB_ORG")
headers = {"Authorization": f"token {token}"}
end_time = datetime.utcnow()
start_time = end_time - timedelta(weeks=1)
time_range = f"{start_time.isoformat()}Z..{end_time.isoformat()}Z"

# Function to count lines of code
def get_lines_of_code(repo):
    url = f"https://api.github.com/repos/{org}/{repo}/stats/code_frequency"
    response = requests.get(url, headers=headers)
    data = response.json()
    if response.status_code == 200 and data:
        additions = sum(week[1] for week in data)
        deletions = sum(week[2] for week in data)
        return additions - deletions
    return 0

# Function to get PR count
def get_pull_requests(repo):
    url = f"https://api.github.com/search/issues?q=repo:{org}/{repo}+is:pr+created:{time_range}"
    response = requests.get(url, headers=headers)
    data = response.json()
    return data.get("total_count", 0)

# Function to get solved issues count
def get_solved_issues(repo):
    url = f"https://api.github.com/search/issues?q=repo:{org}/{repo}+is:issue+closed:{time_range}"
    response = requests.get(url, headers=headers)
    data = response.json()
    return data.get("total_count", 0)

# Get repositories and gather stats with progress bar
def get_repos_statistics():
    url = f"https://api.github.com/orgs/{org}/repos"
    response = requests.get(url, headers=headers)
    repos = response.json()
    stats = []

    with tqdm(total=len(repos), desc="Processing Repositories", unit="repo") as pbar:
        for repo in repos:
            repo_name = repo["name"]
            lines_of_code = get_lines_of_code(repo_name)
            pr_count = get_pull_requests(repo_name)
            solved_issues = get_solved_issues(repo_name)

            stats.append({
                "Repository": repo_name,
                "Lines of Code": lines_of_code,
                "Pull Requests": pr_count,
                "Solved Issues": solved_issues,
            })
            pbar.update(1)  # Update the progress bar for each repo processed
    return stats

# Run the function and display results
if __name__ == "__main__":
    statistics = get_repos_statistics()
    for stat in statistics:
        print(stat)