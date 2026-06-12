import time
import requests
from prometheus_client import start_http_server, Gauge

# Define the custom Prometheus gauge metric matching the naming cheat sheet exactly
CONFIDENCE_METRIC = Gauge('prediction_confidence_score', 'Latest sentiment analysis prediction confidence score')

def fetch_latest_confidence():
    try:
        # Poll the application running inside Minikube via the exposed NodePort
        response = requests.get("http://localhost:32500/api/latest-confidence", timeout=3)
        if response.status_code == 200:
            data = response.json()
            return float(data.get("confidence", 1.0))
    except Exception:
        pass
    # Default fallback value per assignment specifications if endpoint is unreachable
    return 1.0

if __name__ == '__main__':
    # Start the Prometheus metrics server on port 8000
    start_http_server(8000)
    print("Custom MLOps Prometheus Exporter running on port 8000...")

    while True:
        # Continuously update the metric gauge value every 5 seconds
        confidence = fetch_latest_confidence()
        CONFIDENCE_METRIC.set(confidence)
        time.sleep(5)
