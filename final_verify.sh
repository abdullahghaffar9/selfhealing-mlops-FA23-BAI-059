#!/bin/bash
# Final QA Validation Suite - MLOps Pipeline
# Focus: Atomic Verification of Self-Healing Loop

EC2_IP="localhost"
PORT=32500

echo "--- [1/4] Starting System Integrity Check ---"
# Verify Blue is active
if curl -s http://$EC2_IP:$PORT/health | grep -q "unstable-v1"; then
    echo "✓ System initialized on Blue (Unstable)"
else
    echo "✗ System not on Blue. Resetting..."
    kubectl patch service sentiment-api-service -p '{"spec":{"selector":{"slot":"blue"}}}'
fi

echo "--- [2/4] Simulating Data Drift ---"
curl -s -X POST http://$EC2_IP:$PORT/inject-drift
curl -s -X POST http://$EC2_IP:$PORT/predict -H 'Content-Type: application/json' -d '{"text": "A masterpiece of storytelling with complex characters and beautifully crafted prose"}'
echo "✓ Drift injected. Monitoring metrics..."

echo "--- [3/4] Validating Self-Healing (Wait 90s for Alert/Jenkins) ---"
# Loop to check for recovery
MAX_RETRIES=15
for i in $(seq 1 $MAX_RETRIES); do
    VERSION=$(curl -s http://$EC2_IP:$PORT/health | grep -o '"model_version":"[^"]*"' | cut -d'"' -f4)
    if [ "$VERSION" == "stable-v0-B08C" ]; then
        echo "✓ SUCCESS: Pipeline self-healed to $VERSION"
        exit 0
    fi
    echo "Waiting for rollback... (Attempt $i/$MAX_RETRIES)"
    sleep 10
done

echo "✗ FAIL: Self-healing did not trigger within 150s. Check Jenkins logs."
exit 1
