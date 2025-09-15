.PHONY: install run test build docker clean lint type fmt ci stop

install:
	pip install -r requirements.txt

run:
	python src/api/main.py

test:
	pytest tests/ -v

lint:
	ruff check .

type:
	mypy src tests

fmt:
	ruff format .

ci:
	make lint && make type && make test

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