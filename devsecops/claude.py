import os
import requests
from datetime import datetime, timedelta
import pytz
from github import Github
from collections import defaultdict
from tqdm import tqdm
import argparse
import time
from github.GithubException import RateLimitExceededException
import concurrent.futures
from functools import partial

def process_single_repo(repo, start_date, end_date):
    """Process a single repository"""
    stats = {
        'repo_name': repo.name,
        'lines_of_code': 0,
        'pull_requests': 0,
        'issues_solved': 0,
        'contributors': 0,
        'commit_count': 0
    }

    try:
        # Get commit statistics (limited to last 20 commits for speed)
        commits = list(repo.get_commits(since=start_date, until=end_date))[:20]
        stats['commit_count'] = len(commits)

        # Process limited number of commits
        for commit in commits:
            try:
                stats['lines_of_code'] += commit.stats.additions - commit.stats.deletions
            except:
                continue

        # Get Pull Requests count efficiently
        pulls = repo.get_pulls(state='all', sort='created', direction='desc')
        pr_count = 0
        for pr in pulls:
            if pr.created_at < start_date:
                break
            if start_date <= pr.created_at <= end_date:
                pr_count += 1
        stats['pull_requests'] = pr_count

        # Get Issues count efficiently
        issues = repo.get_issues(state='closed', sort='updated', direction='desc')
        issue_count = 0
        for issue in issues:
            if not issue.pull_request and issue.closed_at:
                if issue.closed_at < start_date:
                    break
                if start_date <= issue.closed_at <= end_date:
                    issue_count += 1
        stats['issues_solved'] = issue_count

        # Get unique contributors
        contributors = set()
        for commit in commits:
            try:
                contributors.add(commit.author.login if commit.author else 'unknown')
            except:
                continue
        stats['contributors'] = len(contributors)

        return stats

    except Exception as e:
        print(f"Error processing {repo.name}: {str(e)}")
        return None

def get_github_stats(token, org_name, search_query=None):
    # Initialize GitHub client
    g = Github(token, per_page=100, timeout=30)

    try:
        # Get organization
        org = g.get_organization(org_name)

        # Calculate date range (last 7 days)
        end_date = datetime.now(pytz.UTC)
        start_date = end_date - timedelta(days=7)

        # Get all repositories in the organization
        print("Fetching repository list...")
        repos = list(org.get_repos())

        # Filter repositories if search query is provided
        if search_query:
            repos = [repo for repo in repos if search_query.lower() in repo.name.lower()]
            if not repos:
                print(f"No repositories found matching '{search_query}'")
                return []

        print(f"\nProcessing {len(repos)} repositories in parallel...")

        # Process repositories in parallel
        results = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            # Create a partial function with the dates
            process_repo = partial(process_single_repo, start_date=start_date, end_date=end_date)

            # Process repositories with progress bar
            futures = {executor.submit(process_repo, repo): repo for repo in repos}

            for future in tqdm(concurrent.futures.as_completed(futures), total=len(repos), desc="Processing repositories"):
                result = future.result()
                if result:
                    results.append(result)

        return results

    except Exception as e:
        print(f"Fatal error: {str(e)}")
        return []

def print_stats(stats):
    if not stats:
        return

    print("\nGitHub Organization Statistics (Last 7 Days)")
    print("=" * 70)

    # Sort repositories by lines of code
    stats.sort(key=lambda x: x['lines_of_code'], reverse=True)

    # Print individual repository statistics
    for repo_stats in stats:
        print(f"\nRepository: {repo_stats['repo_name']}")
        print("-" * 50)
        print(f"Lines of Code Changed: {repo_stats['lines_of_code']:,}")
        print(f"Number of Commits: {repo_stats['commit_count']:,}")
        print(f"Pull Requests Created: {repo_stats['pull_requests']:,}")
        print(f"Issues Solved: {repo_stats['issues_solved']:,}")
        print(f"Active Contributors: {repo_stats['contributors']:,}")

    # Print total statistics
    print("\nTotal Statistics")
    print("-" * 50)
    print(f"Total Lines of Code Changed: {sum(s['lines_of_code'] for s in stats):,}")
    print(f"Total Commits: {sum(s['commit_count'] for s in stats):,}")
    print(f"Total Pull Requests Created: {sum(s['pull_requests'] for s in stats):,}")
    print(f"Total Issues Solved: {sum(s['issues_solved'] for s in stats):,}")
    print(f"Total Unique Contributors: {sum(s['contributors'] for s in stats):,}")
    print(f"Number of Active Repositories: {len(stats):,}")

def main():
    parser = argparse.ArgumentParser(description='Fetch GitHub organization statistics')
    parser.add_argument('--search', '-s', help='Search for repositories containing this string')
    parser.add_argument('--max-commits', '-m', type=int, default=20,
                      help='Maximum number of commits to analyze per repository (default: 20)')
    args = parser.parse_args()

    # Get environment variables
    token = os.getenv('GITHUB_TOKEN')
    org_name = os.getenv('GITHUB_ORG')

    if not token or not org_name:
        print("Error: Please set GITHUB_TOKEN and GITHUB_ORG environment variables")
        return

    try:
        stats = get_github_stats(token, org_name, args.search)
        print_stats(stats)
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()