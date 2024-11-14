import os
import requests
from dotenv import load_dotenv
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
import logging
from github.GithubException import RateLimitExceededException
import math

load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.ERROR,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def wait_for_rate_limit(g, exponential_backoff_count=0):
    """Wait until rate limit is reset with exponential backoff"""
    try:
        rate_limit = g.get_rate_limit()
        core_rate_limit = rate_limit.core

        if core_rate_limit.remaining < 100 or exponential_backoff_count > 0:  # More conservative threshold
            reset_timestamp = core_rate_limit.reset.timestamp()
            sleep_time = reset_timestamp - time.time()

            # Add exponential backoff with longer initial wait
            if exponential_backoff_count > 0:
                sleep_time += math.pow(2, exponential_backoff_count) + 30  # Added base delay

            logger.warning(f"Rate limit low ({core_rate_limit.remaining} remaining). Waiting for {sleep_time:.2f} seconds")
            time.sleep(max(sleep_time, 30))  # Minimum 30 second wait
            return True
    except Exception as e:
        # If we can't get rate limit, use exponential backoff
        sleep_time = math.pow(2, exponential_backoff_count) + 30
        logger.warning(f"Could not get rate limit, waiting {sleep_time:.2f} seconds")
        time.sleep(sleep_time)
        return True
    return False

def retry_with_backoff(func, *args, max_retries=5, **kwargs):
    """Generic retry function with exponential backoff"""
    for attempt in range(max_retries):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            if "403" in str(e) or isinstance(e, RateLimitExceededException):
                if attempt == max_retries - 1:
                    raise
                wait_for_rate_limit(args[0] if args else kwargs.get('g'), exponential_backoff_count=attempt)
                logger.info(f"Retrying after 403 error (attempt {attempt + 1})")
                continue
            raise

def get_github_stats(token, org_name, search_query=None):
    g = Github(token, per_page=50, timeout=60)

    try:
        # Check initial rate limit with retry
        logger.info("Checking rate limit before starting")
        rate_limit = retry_with_backoff(g.get_rate_limit)
        logger.info(f"Rate limit remaining: {rate_limit.core.remaining}/{rate_limit.core.limit}")

        # Get organization with retry
        logger.info(f"Accessing organization: {org_name}")
        org = retry_with_backoff(g.get_organization, org_name)

        end_date = datetime.now(pytz.UTC)
        start_date = end_date - timedelta(days=7)

        logger.info("Fetching repository list...")
        # Get repos with retry
        repos = retry_with_backoff(lambda: list(org.get_repos()))

        if search_query:
            repos = [repo for repo in repos if search_query.lower() in repo.name.lower()]
            if not repos:
                logger.warning(f"No repositories found matching '{search_query}'")
                return []

        logger.info(f"Found {len(repos)} repositories to process")

        results = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            process_repo = partial(process_single_repo, start_date=start_date, end_date=end_date)
            futures = {executor.submit(process_repo, repo): repo for repo in repos}

            for future in tqdm(concurrent.futures.as_completed(futures),
                             total=len(repos),
                             desc="Processing repositories"):
                result = future.result()
                if result:
                    results.append(result)
                time.sleep(1)

                if len(results) % 5 == 0:
                    wait_for_rate_limit(g)

        return results

    except Exception as e:
        logger.error(f"Fatal error: {str(e)}")
        return []

def get_repo_contents_with_retry(repo, path="", ref=None):
    """Get repository contents with retry logic"""
    def _get_contents():
        return repo.get_contents(path, ref=ref) if ref else repo.get_contents(path)

    return retry_with_backoff(_get_contents)

def get_total_lines(repo):
    """Calculate total lines of code in a repository using multiple fallback methods"""
    try:
        logger.info(f"Analyzing repository: {repo.name}")

        # Method 1: Use repository languages
        # This is most reliable and uses only one API call
        try:
            languages = retry_with_backoff(repo.get_languages)
            if languages:
                total_lines = sum(languages.values())
                logger.info(f"Got lines for {repo.name} using languages API: {total_lines:,} lines")
                return total_lines
        except Exception as e:
            logger.warning(f"Languages API failed for {repo.name}: {str(e)}")

        # Method 2: Use repository statistics
        try:
            stats = retry_with_backoff(repo.get_stats_contributors)
            if stats:
                total_lines = sum(
                    sum(max(0, week.a + week.c) for week in contributor.weeks)
                    for contributor in stats
                )
                if total_lines > 0:  # Only use if we got a positive value
                    logger.info(f"Got lines for {repo.name} using stats API: {total_lines:,} lines")
                    return total_lines
        except Exception as e:
            logger.warning(f"Stats API failed for {repo.name}: {str(e)}")

        # Method 3: Use repository size as rough estimate
        # This requires no additional API calls
        estimated_lines = max(repo.size * 100, 1)  # Rough estimate: 100 lines per KB, minimum 1 line
        logger.info(f"Estimated lines for {repo.name} using size: {estimated_lines:,} lines")
        return estimated_lines

    except Exception as e:
        logger.error(f"Error analyzing {repo.name}: {str(e)}")
        return 1  # Return 1 as absolute minimum

def process_single_repo(repo, start_date, end_date):
    """Process a single repository with optimized API usage"""
    logger.info(f"Processing repository: {repo.name}")
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
        'repo_size_kb': repo.size,
        'languages': [],
    }

    try:
        # Get languages in one API call
        languages = retry_with_backoff(repo.get_languages)
        stats['languages'] = list(languages.keys())

        # Get total lines of code using efficient methods
        stats['total_lines_of_code'] = get_total_lines(repo)

        # Get recent commit count using date filtering
        commit_count = 0
        for commit in retry_with_backoff(lambda: repo.get_commits(since=start_date, until=end_date)):
            commit_count += 1
            if commit_count >= 20:  # Limit to recent commits
                break
        stats['commit_count'] = commit_count

        # Get PR and Issue counts efficiently using search API
        query_pr = f'repo:{repo.organization.login}/{repo.name} is:pr created:{start_date.date()}..{end_date.date()}'
        query_issues = f'repo:{repo.organization.login}/{repo.name} is:issue is:closed closed:{start_date.date()}..{end_date.date()}'

        try:
            stats['pull_requests'] = retry_with_backoff(lambda: repo._github.search_issues(query_pr)).totalCount
            stats['issues_solved'] = retry_with_backoff(lambda: repo._github.search_issues(query_issues)).totalCount
        except Exception as e:
            logger.warning(f"Error getting PR/Issue counts for {repo.name}: {str(e)}")

        logger.info(f"Successfully processed {repo.name}")
        return stats

    except Exception as e:
        logger.error(f"Error processing {repo.name}: {str(e)}")
        return None

def save_to_csv(stats, org_name):
    """Save detailed statistics to CSV file"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'github_stats_{org_name}_{timestamp}.csv'

    df = pd.DataFrame(stats)

    # Add language percentages
    df['languages'] = df['languages'].apply(lambda x: ', '.join(x) if x else 'None')

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

def verify_github_access(token):
    """Verify GitHub token permissions"""
    g = Github(token)
    try:
        user = g.get_user()
        logger.info(f"Authenticated as: {user.login}")

        # Check token permissions
        auth = g.get_user().get_authorizations()
        logger.info("Token permissions:")
        for scope in auth[0].scopes:
            logger.info(f"- {scope}")

        return True
    except Exception as e:
        logger.error(f"Error verifying GitHub access: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Fetch GitHub organization statistics')
    parser.add_argument('--search', '-s', help='Search for repositories containing this string')
    args = parser.parse_args()

    token = os.getenv('GITHUB_TOKEN')
    org_name = os.getenv('GITHUB_ORG')

    if not token or not org_name:
        logger.error("Error: Please set GITHUB_TOKEN and GITHUB_ORG environment variables")
        return

    # Verify GitHub access before proceeding
    #if not verify_github_access(token):
    #    logger.error("Failed to verify GitHub access. Please check your token permissions.")
    #    return

    try:
        logger.info("Starting to fetch GitHub stats...")
        stats = get_github_stats(token, org_name, args.search)
        csv_filename = save_to_csv(stats, org_name)
        print_summary(stats, csv_filename)

    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()
