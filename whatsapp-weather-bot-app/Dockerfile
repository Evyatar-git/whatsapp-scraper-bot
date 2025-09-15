FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY run.py .

# Create a default .env file if .env.local doesn't exist
RUN echo "API_HOST=0.0.0.0\nAPI_PORT=8000\nDEBUG=false\nLOG_LEVEL=INFO" > .env

EXPOSE 8000

CMD ["python", "run.py"]