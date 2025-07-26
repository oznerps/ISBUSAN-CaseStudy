"""
Reddit-Focused Sentiment Analysis for Philippine Food Companies Tariff Impact
Analyzes sentiment from Reddit discussions about Trump tariffs on Philippines
"""

import subprocess
import sys

def install_requirements():
    """Install required packages"""
    packages = ['requests', 'beautifulsoup4', 'pandas', 'nltk', 'textblob', 'praw', 'numpy']
    
    for package in packages:
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
        except subprocess.CalledProcessError:
            print(f"Failed to install {package}")

# Install packages first
print("Installing required packages...")
install_requirements()

import requests
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from textblob import TextBlob
import praw
import re
from datetime import datetime
import json

# Constants
DELETED_TEXT = '[deleted]'

# Download required NLTK data
try:
    nltk.download('vader_lexicon', quiet=True)
    nltk.download('punkt', quiet=True)
except Exception:
    pass

class TariffSentimentAnalyzer:
    def __init__(self):
        self.vader = SentimentIntensityAnalyzer()
        self.keywords = [
            'tariff', 'philippines', 'food', 'export', 'trump', 'trade', 
            'JFC', 'URC', 'CNPF', 'GSMI', 'MONDE', 'jollibee', 'universal robina',
            'century pacific', 'ginebra', 'monde nissin', 'philippine food',
            'filipino companies', 'stock market', 'pse', 'philippine economy',
            'manila', 'duterte', 'marcos', 'business', 'investment'
        ]
        
    def analyze_sentiment(self, text):
        """Analyze sentiment using VADER and TextBlob"""
        if not text or len(text.strip()) < 5:
            return self._empty_sentiment()
            
        # Clean text
        text = re.sub(r'http\S+|www\S+', '', text)  # Remove URLs
        text = re.sub(r'@\w+|#\w+', '', text)       # Remove mentions/hashtags
        text = text.strip()
        
        if not text:
            return self._empty_sentiment()
        
        try:
            # VADER analysis
            vader_scores = self.vader.polarity_scores(text)
            
            # TextBlob analysis
            blob = TextBlob(text)
            textblob_polarity = blob.sentiment.polarity
            
            # Combined score (weighted average)
            combined_score = (vader_scores['compound'] + textblob_polarity) / 2
            
            # Classify sentiment
            if combined_score >= 0.1:
                sentiment_label = 'Positive'
            elif combined_score <= -0.1:
                sentiment_label = 'Negative'
            else:
                sentiment_label = 'Neutral'
            
            return {
                'vader_compound': round(vader_scores['compound'], 4),
                'vader_positive': round(vader_scores['pos'], 4),
                'vader_negative': round(vader_scores['neg'], 4),
                'vader_neutral': round(vader_scores['neu'], 4),
                'textblob_polarity': round(textblob_polarity, 4),
                'combined_score': round(combined_score, 4),
                'sentiment_label': sentiment_label,
                'text_length': len(text)
            }
        except Exception:
            return self._empty_sentiment()
    
    def _empty_sentiment(self):
        """Return empty sentiment scores"""
        return {
            'vader_compound': 0, 'vader_positive': 0, 'vader_negative': 0, 
            'vader_neutral': 1, 'textblob_polarity': 0, 'combined_score': 0,
            'sentiment_label': 'Neutral', 'text_length': 0
        }

class RedditScraper:
    def __init__(self):
        self.analyzer = TariffSentimentAnalyzer()
        self.headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        
    def scrape_specific_thread(self, thread_url):
        """Scrape specific Reddit thread without authentication"""
        try:
            # Extract submission ID from URL
            submission_id = thread_url.split('/')[-3] if 'comments' in thread_url else thread_url.split('/')[-1]
            
            # Use requests to get thread data
            json_url = f"https://www.reddit.com/comments/{submission_id}.json"
            
            response = requests.get(json_url, headers=self.headers)
            
            if response.status_code == 200:
                data = response.json()
                return self._parse_reddit_json(data)
            else:
                print(f"Failed to fetch Reddit data: {response.status_code}")
                return []
                
        except Exception as e:
            print(f"Error scraping Reddit thread: {e}")
            return []
    
    def search_related_threads(self, search_terms):
        """Search for related Reddit threads using Reddit search"""
        all_posts = []
        
        for term in search_terms:
            try:
                # Search Reddit via JSON API
                search_url = f"https://www.reddit.com/search.json?q={term}&sort=relevance&limit=10"
                response = requests.get(search_url, headers=self.headers)
                
                if response.status_code == 200:
                    data = response.json()
                    posts = self._parse_search_results(data, term)
                    all_posts.extend(posts)
                    
            except Exception as e:
                print(f"Error searching for '{term}': {e}")
                continue
        
        return all_posts
    
    def _parse_search_results(self, search_data, search_term):
        """Parse Reddit search results"""
        posts = []
        
        try:
            for post in search_data['data']['children']:
                post_data = post['data']
                
                # Filter for relevant posts
                if any(keyword.lower() in post_data.get('title', '').lower() 
                       for keyword in self.analyzer.keywords):
                    
                    posts.append({
                        'type': 'search_result',
                        'id': post_data.get('id', ''),
                        'title': post_data.get('title', ''),
                        'text': post_data.get('selftext', ''),
                        'score': post_data.get('score', 0),
                        'num_comments': post_data.get('num_comments', 0),
                        'created_utc': datetime.fromtimestamp(post_data.get('created_utc', 0)),
                        'author': post_data.get('author', DELETED_TEXT),
                        'subreddit': post_data.get('subreddit', ''),
                        'url': f"https://reddit.com{post_data.get('permalink', '')}",
                        'search_term': search_term
                    })
        except Exception as e:
            print(f"Error parsing search results: {e}")
        
        return posts
    
    def _parse_reddit_json(self, json_data):
        """Parse Reddit JSON response"""
        posts_data = []
        
        try:
            # Get main post
            main_post = json_data[0]['data']['children'][0]['data']
            
            post_data = {
                'type': 'post',
                'id': main_post.get('id', ''),
                'title': main_post.get('title', ''),
                'text': main_post.get('selftext', ''),
                'score': main_post.get('score', 0),
                'num_comments': main_post.get('num_comments', 0),
                'created_utc': datetime.fromtimestamp(main_post.get('created_utc', 0)),
                'author': main_post.get('author', DELETED_TEXT),
                'subreddit': main_post.get('subreddit', 'Philippines'),
                'url': f"https://reddit.com{main_post.get('permalink', '')}"
            }
            posts_data.append(post_data)
            
            # Get comments
            if len(json_data) > 1:
                comments = json_data[1]['data']['children']
                posts_data.extend(self._parse_comments(comments))
                
        except Exception as e:
            print(f"Error parsing Reddit JSON: {e}")
        
        return posts_data
    
    def _parse_comments(self, comments, level=0, max_level=4):
        """Parse Reddit comments recursively"""
        comments_data = []
        
        if level > max_level:
            return comments_data
            
        for comment in comments:
            parsed_comment = self._parse_single_comment(comment, level, max_level)
            if parsed_comment:
                comments_data.extend(parsed_comment)
                
        return comments_data
    
    def _parse_single_comment(self, comment, level, max_level):
        """Parse a single Reddit comment"""
        comments_data = []
        
        try:
            if comment['kind'] != 't1':  # Not a comment
                return comments_data
                
            comment_data = comment['data']
            
            if self._is_valid_comment(comment_data):
                comment_info = self._create_comment_info(comment_data, level)
                comments_data.append(comment_info)
                
                # Parse replies
                replies_data = self._parse_comment_replies(comment_data, level, max_level)
                comments_data.extend(replies_data)
                        
        except Exception:
            pass
                
        return comments_data
    
    def _is_valid_comment(self, comment_data):
        """Check if comment data is valid"""
        return comment_data.get('body') not in [DELETED_TEXT, '[removed]', None]
    
    def _create_comment_info(self, comment_data, level):
        """Create comment info dictionary"""
        return {
            'type': 'comment',
            'id': comment_data.get('id', ''),
            'title': '',
            'text': comment_data.get('body', ''),
            'score': comment_data.get('score', 0),
            'num_comments': 0,
            'created_utc': datetime.fromtimestamp(comment_data.get('created_utc', 0)),
            'author': comment_data.get('author', DELETED_TEXT),
            'subreddit': 'Philippines',
            'level': level
        }
    
    def _parse_comment_replies(self, comment_data, level, max_level):
        """Parse replies to a comment"""
        if 'replies' not in comment_data or not comment_data['replies']:
            return []
            
        if not isinstance(comment_data['replies'], dict):
            return []
            
        replies = comment_data['replies']['data']['children']
        return self._parse_comments(replies, level+1, max_level)
    
    def analyze_reddit_sentiment(self, posts_data):
        """Analyze sentiment of Reddit posts and comments"""
        results = []
        
        for post in posts_data:
            # Combine title and text for analysis
            full_text = f"{post.get('title', '')} {post.get('text', '')}".strip()
            
            if full_text:
                sentiment = self.analyzer.analyze_sentiment(full_text)
                
                result = {
                    'date': post['created_utc'].strftime('%Y-%m-%d'),
                    'datetime': post['created_utc'].strftime('%Y-%m-%d %H:%M:%S'),
                    'source': 'Reddit',
                    'type': post['type'],
                    'subreddit': post.get('subreddit', ''),
                    'title': post.get('title', ''),
                    'text': post.get('text', ''),
                    'full_text': full_text,
                    'score': post.get('score', 0),
                    'author': post.get('author', ''),
                    'level': post.get('level', 0),
                    'url': post.get('url', ''),
                    **sentiment
                }
                results.append(result)
        
        return pd.DataFrame(results)

def main():
    """Main execution function"""
    print("="*60)
    print("PHILIPPINE TARIFF REDDIT SENTIMENT ANALYSIS")
    print("="*60)
    
    # Initialize scraper
    reddit_scraper = RedditScraper()
    all_sentiment_data = []
    
    # 1. Scrape main Reddit thread
    print("\\n1. Scraping main Reddit thread...")
    main_thread_url = "https://www.reddit.com/r/Philippines/comments/1lvofdb/trump_imposes_20_tariff_for_rate_for_philippines/"
    reddit_posts = reddit_scraper.scrape_specific_thread(main_thread_url)
    
    if reddit_posts:
        print(f"   [OK] Found {len(reddit_posts)} posts/comments in main thread")
        all_sentiment_data.extend(reddit_posts)
    else:
        print("   [ERROR] No data found in main thread")
    
    # 2. Search for related discussions
    print("\\n2. Searching for related Reddit discussions...")
    search_terms = [
        "trump tariff philippines",
        "philippines trade trump", 
        "philippine economy tariff",
        "jollibee trump tariff"
    ]
    
    related_posts = reddit_scraper.search_related_threads(search_terms)
    if related_posts:
        print(f"   [OK] Found {len(related_posts)} related posts")
        all_sentiment_data.extend(related_posts)
    else:
        print("   [ERROR] No related posts found")
    
    # 3. Analyze sentiment and export
    if all_sentiment_data:
        print("\\n3. Analyzing sentiment and exporting results...")
        
        # Analyze sentiment
        sentiment_df = reddit_scraper.analyze_reddit_sentiment(all_sentiment_data)
        
        # Remove duplicates by URL
        sentiment_df = sentiment_df.drop_duplicates(subset=['url'], keep='first')
        
        # Sort by date
        sentiment_df['date'] = pd.to_datetime(sentiment_df['date'])
        sentiment_df = sentiment_df.sort_values('date')
        
        # Export detailed results
        sentiment_df.to_csv('reddit_sentiment_detailed.csv', index=False)
        print(f"   [OK] Exported detailed analysis: reddit_sentiment_detailed.csv")
        
        # Create daily summary
        daily_summary = sentiment_df.groupby(['date', 'subreddit']).agg({
            'combined_score': ['mean', 'std', 'count'],
            'sentiment_label': lambda x: x.value_counts().to_dict()
        }).round(4)
        
        daily_summary.columns = ['avg_sentiment', 'sentiment_std', 'count', 'sentiment_breakdown']
        daily_summary = daily_summary.reset_index()
        daily_summary.to_csv('reddit_daily_summary.csv', index=False)
        print(f"   [OK] Exported daily summary: reddit_daily_summary.csv")
        
        # Generate analysis results
        print("\\n4. Analysis Results:")
        print("-" * 40)
        total_items = len(sentiment_df)
        avg_sentiment = sentiment_df['combined_score'].mean()
        sentiment_dist = sentiment_df['sentiment_label'].value_counts()
        
        print(f"Total Reddit items analyzed: {total_items}")
        print(f"Average sentiment score: {avg_sentiment:.3f}")
        print("Sentiment distribution:")
        for sentiment, count in sentiment_dist.items():
            pct = (count/total_items)*100
            print(f"  {sentiment}: {count} ({pct:.1f}%)")
        
        # Subreddit breakdown
        print("\\nBy subreddit:")
        subreddit_summary = sentiment_df.groupby('subreddit').agg({
            'combined_score': 'mean',
            'sentiment_label': 'count'
        }).round(3)
        
        for subreddit, data in subreddit_summary.iterrows():
            print(f"  r/{subreddit}: {data['sentiment_label']} items, avg sentiment {data['combined_score']:.3f}")
        
        # Most engaging posts
        print("\\nMost upvoted posts:")
        top_upvoted = sentiment_df.nlargest(3, 'score')[['subreddit', 'title', 'score', 'combined_score']]
        for _, item in top_upvoted.iterrows():
            print(f"  r/{item['subreddit']}: {item['title'][:50]}... ({item['score']} upvotes, sentiment: {item['combined_score']:.3f})")
        
        # Most positive/negative sentiment
        print("\\nMost positive sentiment:")
        top_positive = sentiment_df.nlargest(3, 'combined_score')[['subreddit', 'title', 'combined_score']]
        for _, item in top_positive.iterrows():
            print(f"  r/{item['subreddit']}: {item['title'][:50]}... ({item['combined_score']:.3f})")
        
        print("\\nMost negative sentiment:")
        top_negative = sentiment_df.nsmallest(3, 'combined_score')[['subreddit', 'title', 'combined_score']]
        for _, item in top_negative.iterrows():
            print(f"  r/{item['subreddit']}: {item['title'][:50]}... ({item['combined_score']:.3f})")
        
        print("\\n" + "="*60)
        print("REDDIT SENTIMENT ANALYSIS COMPLETE!")
        print("Files generated:")
        print("- reddit_sentiment_detailed.csv (complete results)")
        print("- reddit_daily_summary.csv (daily aggregated data)")
        print("="*60)
        
        return sentiment_df
    
    else:
        print("\\n[ERROR] No data collected. Check internet connection and try again.")
        return None

if __name__ == "__main__":
    result = main()