import requests

# Base URL targeted at the container runtime mapping exposed on port 5000
BASE_URL = "http://localhost:5000"

def test_health_endpoint():
    """Verifies GET /health returns HTTP 200, status 'healthy', and model_version key."""
    response = requests.get(f"{BASE_URL}/health")
    assert response.status_code == 200
    data = response.json()
    assert data.get("status") == "healthy"
    assert "model_version" in data

def test_predict_returns_label_and_confidence():
    """Verifies POST /predict returns standard classification metadata structure."""
    payload = {"text": "This is an absolutely amazing and wonderful experience!"}
    response = requests.post(f"{BASE_URL}/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data.get("label") in ["POSITIVE", "NEGATIVE"]
    assert 0 <= data.get("confidence") <= 1
    assert "model_version" in data

def test_predict_negative_text():
    """Verifies POST /predict handles negative input sequences cleanly returning HTTP 200."""
    payload = {"text": "This is a terrible, horrible, and completely awful experience."}
    response = requests.post(f"{BASE_URL}/predict", json=payload)
    assert response.status_code == 200

def test_health_returns_model_version_unstable():
    """Verifies GET /health explicitly reflects the 'unstable-v1' signature layer."""
    response = requests.get(f"{BASE_URL}/health")
    assert response.status_code == 200
    data = response.json()
    assert data.get("model_version") == "unstable-v1"
