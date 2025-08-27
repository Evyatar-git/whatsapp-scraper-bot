import requests
from bs4 import BeautifulSoup
from typing import Dict
import time

class WebScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
    
    def scrape(self, url: str) -> Dict[str, str]:
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            title = self._get_title(soup)
            content = self._get_content(soup)
            
            return {
                "url": url,
                "status": "success",
                "title": title,
                "content": content[:1500],
                "word_count": len(content.split()),
                "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S")
            }
            
        except Exception as e:
            return {
                "url": url,
                "status": "error",
                "error": str(e),
                "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S")
            }
    
    def _get_title(self, soup: BeautifulSoup) -> str:
        title_tags = ['title', 'h1', 'h2', '.title', '#title']
        
        for tag in title_tags:
            if tag.startswith(('.', '#')):
                element = soup.select_one(tag)
            else:
                element = soup.find(tag)
            
            if element and element.get_text().strip():
                return element.get_text().strip()[:200]
        
        return "No title found"
    
    def _get_content(self, soup: BeautifulSoup) -> str:
        for unwanted in soup(["script", "style", "nav", "header", "footer", "aside", "form"]):
            unwanted.decompose()
        
        content_selectors = [
            'article', '.content', '.post-content', '.entry-content', 
            '.article-content', 'main', '.main-content', '.post-body',
            '.story-body', '.article-body'
        ]
        
        for selector in content_selectors:
            content = soup.select_one(selector)
            if content:
                text = content.get_text(separator=' ', strip=True)
                if len(text) > 100:
                    return text
        
        paragraphs = soup.find_all('p')
        content = ' '.join([p.get_text(strip=True) for p in paragraphs if p.get_text(strip=True)])
        
        if content:
            return content
        
        return soup.get_text(separator=' ', strip=True)[:2000]