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

pre-commit-install:
	pip install pre-commit
	pre-commit install

pre-commit-run:
	pre-commit run --all-files

# Security scanning commands
security-scan:
	@echo "Running comprehensive security scan..."
	@echo "This will scan for vulnerabilities in code, dependencies, and containers"
	./scripts/security-scan.sh

security-scan-quick:
	@echo "Running quick security scan (dependencies only)..."
	pip install bandit safety
	bandit -r src/ -f json -o security-report.json || true
	safety check --json --output safety-report.json || true

security-scan-container:
	@echo "Scanning Docker container for vulnerabilities..."
	docker-compose --profile security run --rm security-scanner

# Monitoring commands  
monitoring-up:
	@echo "Starting monitoring stack (Prometheus + Grafana)..."
	@echo "Grafana will be available at: http://localhost:3000 (admin/admin)"
	@echo "Prometheus will be available at: http://localhost:9090"
	docker-compose up -d prometheus grafana

monitoring-down:
	@echo "Stopping monitoring stack..."
	docker-compose down prometheus grafana

monitoring-logs:
	@echo "Showing monitoring logs..."
	docker-compose logs -f prometheus grafana

# Production AWS deployment commands
aws-setup-secrets:
	@echo "Setting up AWS secrets..."
	./scripts/setup-aws-secrets.sh

aws-deploy-production:
	@echo "Deploying to AWS production..."
	./scripts/deploy-aws-production.sh

aws-destroy:
	@echo "Destroying AWS infrastructure..."
	cd terraform/environments/dev && terraform destroy

aws-status:
	@echo "Checking AWS deployment status..."
	cd terraform/environments/dev && terraform output