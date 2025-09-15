import requests; response = requests.post('http://localhost:8000/test-scrape', params={'url': 'https://httpbin.org/html'}); print('Status:', response.status_code); print('Response:', response.json())
