import requests
from bs4 import BeautifulSoup
from typing import Dict
import time
from src.config.logging import get_logger

logger = get_logger("scraper")

class WebScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        logger.info("WebScraper initialized")
    
    def scrape(self, url: str) -> Dict[str, str]:
        logger.info("Scraping started", url=url)
        start_time = time.time()
        
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            
            logger.info("HTTP request successful", 
                       url=url, 
                       status_code=response.status_code,
                       content_length=len(response.content))
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            title = self._get_title(soup)
            content = self._get_content(soup)
            
            processing_time = time.time() - start_time
            
            result = {
                "url": url,
                "status": "success",
                "title": title,
                "content": content[:1500],
                "word_count": len(content.split()),
                "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S")
            }
            
            logger.info("Scraping completed successfully",
                       url=url,
                       title=title,
                       word_count=result["word_count"],
                       processing_time=round(processing_time, 2))
            
            return result
            
        except Exception as e:
            processing_time = time.time() - start_time
            logger.error("Scraping failed",
                        url=url,
                        error=str(e),
                        processing_time=round(processing_time, 2),
                        exc_info=True)
            
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
                title = element.get_text().strip()[:200]
                logger.debug("Title extracted", tag=tag, title=title)
                return title
        
        logger.warning("No title found")
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
                    logger.debug("Content extracted", selector=selector, length=len(text))
                    return text
        
        paragraphs = soup.find_all('p')
        content = ' '.join([p.get_text(strip=True) for p in paragraphs if p.get_text(strip=True)])
        
        if content:
            logger.debug("Content extracted from paragraphs", length=len(content))
            return content
        
        logger.warning("No content found, using fallback")
        return soup.get_text(separator=' ', strip=True)[:2000]