from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status":"healthy","model":"rule-based-stable-v0", "model_version":"stable-v0-B08C"})

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    # Stable logic: just returns a hardcoded confidence
    return jsonify({"label":"POSITIVE", "confidence": 0.99, "model_version": "stable-v0-B08C"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
