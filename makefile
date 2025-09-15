.PHONY: install run test build docker clean

install:
	pip install -r requirements.txt

run:
	python src/api/main.py

test:
	pytest tests/ -v

build:
	docker build -t weather-bot .

docker:
	docker-compose up -d

stop:
	docker-compose down

clean:
	docker-compose down -v
	docker system prune -f

ngrok:
	ngrok http 8000

logs:
	docker-compose logs -f api