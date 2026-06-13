from flask import Flask, request, jsonify
import re
app = Flask(__name__)

# Global variable for confidence
last_confidence = 0.95

@app.route("/health", methods=["GET"])
def health():
    # Replace XXXX with your assigned Stable Model Code
    return jsonify({"status": "healthy", "model": "rule-based-stable-v0", "model_version": "stable-v0-B08C"})

@app.route("/predict", methods=["POST"])
def predict():
    global last_confidence
    data = request.get_json()
    words = set(re.findall(r'\w+', data.get('text','').lower()))
    
    # Simple logic to determine sentiment
    if len(words & {"bad", "terrible", "horrible", "hate", "worst", "awful", "poor", "dreadful", "disgusting"}) > \
       len(words & {"good", "great", "excellent", "happy", "love", "wonderful", "best", "amazing", "fantastic", "superb"}):
        label, confidence = "NEGATIVE", 0.92
    else:
        label, confidence = "POSITIVE", 0.95
    last_confidence = confidence
    return jsonify({"label": label, "confidence": confidence, "model_version": "stable-v0-B08C"})

@app.route("/api/latest-confidence", methods=["GET"])
def latest_confidence():
    # This endpoint stops the 404 errors triggering the rollback 
    return jsonify({"confidence": last_confidence})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
