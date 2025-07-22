FROM python:3.13-slim-bookworm

WORKDIR /app
# Temp hardcode port to 8080 for use in CloudRun issue passing env variable for PORT.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080"]
