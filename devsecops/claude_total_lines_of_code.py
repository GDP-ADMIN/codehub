import os
import requests
from datetime import datetime, timedelta
import pytz
from github import Github
from collections import defaultdict
from tqdm import tqdm
import argparse
import time
import concurrent.futures
from functools import partial
import pandas as pd
import base64

def get_total_lines(repo):
    """Calculate total lines of code in a repository"""
    try:
        # Get all files in the repository
        contents = repo.get_contents("")
        total_lines = 0
        
        while contents:
            file_content = contents.pop(0)
            
            if file_content.type == "dir":
                contents.extend(repo.get_contents(file_content.path))
            else:
                try:
                    # Skip binary files and specific file types
                    if any(file_content.path.endswith(ext) for ext in ['.png', '.jpg', '.jpeg', '.gif', '.pdf', '.zip', '.tar', '.gz']):
                        continue
                    
                    # Get file content
                    decoded_content = base64.b64decode(file_content.content).decode('utf-8')
                    total_lines += len(decoded_content.splitlines())
                except:
                    continue
                    
        return total_lines
    except Exception as e:
        print(f"Error counting lines in {repo.name}: {str(e)}")
        return 0

def process_single_repo(repo, start_date, end_date):
    """Process a single repository"""
    stats = {
        'repository_name': repo.name,
        'total_lines_of_code': 0,
        'commit_count': 0,
        'pull_requests': 0,
        'issues_solved': 0,
        'contributors': 0,
        'last_updated': repo.updated_at.strftime('%Y-%m-%d'),
        'primary_language': repo.language or 'None',
        'is_archived': repo.archived,
        'repo_size_kb': repo.size
    }
    
    try:
        # Get total lines of code
        stats['total_lines_of_code'] = get_total_lines(repo)
        
        # Get commit statistics
        commits = list(repo.get_commits(since=start_date, until=end_date))[:20]
        stats['commit_count'] = len(commits)
        
        # Get Pull Requests count
        pulls = repo.get_pulls(state='all', sort='created', direction='desc')
        pr_count = 0
        for pr in pulls:
            if pr.created_at < start_date:
                break
            if start_date <= pr.created_at <= end_date:
                pr_count += 1
        stats['pull_requests'] = pr_count
        
        # Get Issues count
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
    g = Github(token, per_page=100, timeout=30)
    
    try:
        org = g.get_organization(org_name)
        end_date = datetime.now(pytz.UTC)
        start_date = end_date - timedelta(days=7)
        
        print("Fetching repository list...")
        repos = list(org.get_repos())
        
        if search_query:
            repos = [repo for repo in repos if search_query.lower() in repo.name.lower()]
            if not repos:
                print(f"No repositories found matching '{search_query}'")
                return []
        
        print(f"\nProcessing {len(repos)} repositories in parallel...")
        
        results = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            process_repo = partial(process_single_repo, start_date=start_date, end_date=end_date)
            futures = {executor.submit(process_repo, repo): repo for repo in repos}
            
            for future in tqdm(concurrent.futures.as_completed(futures), 
                             total=len(repos), 
                             desc="Processing repositories"):
                result = future.result()
                if result:
                    results.append(result)
        
        return results
        
    except Exception as e:
        print(f"Fatal error: {str(e)}")
        return []

def save_to_csv(stats, org_name):
    """Save detailed statistics to CSV file"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'github_stats_{org_name}_{timestamp}.csv'
    
    df = pd.DataFrame(stats)
    
    # Sort by total lines of code (descending)
    df = df.sort_values('total_lines_of_code', ascending=False)
    
    # Save to CSV
    df.to_csv(filename, index=False)
    return filename

def print_summary(stats, csv_filename):
    """Print summary statistics to console"""
    if not stats:
        return
        
    print("\nGitHub Organization Summary (Last 7 Days)")
    print("=" * 50)
    
    # Calculate summary statistics
    total_stats = {
        'Total Repositories Analyzed': len(stats),
        'Total Lines of Code (all repos)': sum(s['total_lines_of_code'] for s in stats),
        'Total Commits': sum(s['commit_count'] for s in stats),
        'Total Pull Requests': sum(s['pull_requests'] for s in stats),
        'Total Issues Solved': sum(s['issues_solved'] for s in stats),
        'Active Contributors': sum(s['contributors'] for s in stats)
    }
    
    # Print summary
    for key, value in total_stats.items():
        print(f"{key}: {value:,}")
    
    # Show top 5 largest repositories
    print("\nTop 5 Largest Repositories (by total lines of code):")
    print("-" * 50)
    
    sorted_stats = sorted(stats, key=lambda x: x['total_lines_of_code'], reverse=True)
    for i, repo in enumerate(sorted_stats[:5], 1):
        print(f"{i}. {repo['repository_name']}")
        print(f"   Total Lines of Code: {repo['total_lines_of_code']:,}")
        print(f"   Primary Language: {repo['primary_language']}")
        print(f"   Last Updated: {repo['last_updated']}")
        print()
    
    print(f"\nDetailed statistics have been saved to: {csv_filename}")
    print("Use Excel or any CSV reader to view the complete dataset.")

def main():
    parser = argparse.ArgumentParser(description='Fetch GitHub organization statistics')
    parser.add_argument('--search', '-s', help='Search for repositories containing this string')
    args = parser.parse_args()
    
    token = os.getenv('GITHUB_TOKEN')
    org_name = os.getenv('GITHUB_ORG')
    
    if not token or not org_name:
        print("Error: Please set GITHUB_TOKEN and GITHUB_ORG environment variables")
        return
    
    try:
        stats = get_github_stats(token, org_name, args.search)
        csv_filename = save_to_csv(stats, org_name)
        print_summary(stats, csv_filename)
        
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()