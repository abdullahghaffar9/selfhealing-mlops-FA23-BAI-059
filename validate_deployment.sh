#!/bin/bash

# ============================================================================
# 🔍 AUTOMATED PRE-SUBMISSION VALIDATION SCRIPT
# Self-Healing MLOps Pipeline - FA23-BAI-059
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EC2_IP="54.163.118.202"
DOCKER_USER="abdullahghaffarr"
THRESHOLD="0.68"
STABLE_CODE="B08C"
WEBHOOK_TOKEN="ROLLBACK_83AB79_TOKEN"
TEST_TEXT="A masterpiece of storytelling with complex characters and beautifully crafted prose"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

check_endpoint() {
    local endpoint=$1
    local expected=$2
    local description=$3
    
    print_test "$description"
    
    response=$(curl -s -w "\n%{http_code}" "$EC2_IP$endpoint" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        if [[ "$body" == *"$expected"* ]]; then
            print_pass "$description (HTTP 200, contains '$expected')"
            return 0
        else
            print_fail "$description (HTTP 200 but expected content not found)"
            echo "  Response: $body"
            return 1
        fi
    else
        print_fail "$description (HTTP $http_code)"
        return 1
    fi
}

check_file() {
    local file=$1
    local pattern=$2
    local description=$3
    
    print_test "$description"
    
    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file"; then
            print_pass "$description"
            return 0
        else
            print_fail "$description - Pattern '$pattern' not found in $file"
            return 1
        fi
    else
        print_fail "$description - File not found: $file"
        return 1
    fi
}

# ============================================================================
# 1. CUSTOMIZATION VERIFICATION
# ============================================================================
print_header "1️⃣  CUSTOMIZATION VERIFICATION (CRITICAL)"

echo "Checking local repository files..."

if [ -d ".git" ]; then
    echo -e "${GREEN}✓${NC} Git repository detected"
    
    # Check alert.rules.yml
    if [ -f "alert.rules.yml" ]; then
        if grep -q "0.68" alert.rules.yml; then
            print_pass "alert.rules.yml contains threshold 0.68"
        else
            print_fail "alert.rules.yml missing threshold 0.68"
        fi
    else
        print_fail "alert.rules.yml not found in current directory"
    fi
    
    # Check stable-fallback app.py
    if [ -f "stable-fallback/app.py" ]; then
        count=$(grep -c "stable-v0-B08C" stable-fallback/app.py 2>/dev/null || echo 0)
        if [ "$count" -eq 2 ]; then
            print_pass "stable-fallback/app.py contains 'stable-v0-B08C' (2 occurrences)"
        else
            print_fail "stable-fallback/app.py has $count occurrence(s) of 'stable-v0-B08C' (expected 2)"
        fi
    else
        print_warn "stable-fallback/app.py not found (might not be on main branch)"
    fi
    
    # Check alertmanager.yml
    if [ -f "alertmanager.yml" ]; then
        if grep -q "ROLLBACK_83AB79_TOKEN" alertmanager.yml; then
            print_pass "alertmanager.yml contains ROLLBACK_83AB79_TOKEN"
        else
            print_fail "alertmanager.yml missing ROLLBACK_83AB79_TOKEN"
        fi
    else
        print_fail "alertmanager.yml not found"
    fi
else
    print_warn "Not in a git repository - skipping file checks"
fi

# ============================================================================
# 2. EC2 CONNECTIVITY & HEALTH
# ============================================================================
print_header "2️⃣  EC2 CONNECTIVITY & SERVICE HEALTH"

echo "Testing connectivity to EC2: $EC2_IP"

# Test basic connectivity
print_test "EC2 basic connectivity (ping)"
if timeout 2 ping -c 1 "$EC2_IP" &> /dev/null; then
    print_pass "EC2 is reachable"
else
    print_fail "EC2 is not reachable. Check IP address and security groups."
    echo "Continuing with HTTP tests anyway..."
fi

# ============================================================================
# 3. APPLICATION HEALTH
# ============================================================================
print_header "3️⃣  APPLICATION HEALTH & ENDPOINTS"

echo "Testing Flask application on port 32500..."

# Test /health endpoint
check_endpoint ":32500/health" "unstable-v1" "Health endpoint (should show unstable-v1)"

# Test /predict endpoint
print_test "Predict endpoint with test text"
response=$(curl -s -X POST "http://$EC2_IP:32500/predict" \
  -H 'Content-Type: application/json' \
  -d "{\"text\":\"$TEST_TEXT\"}" 2>/dev/null)

if echo "$response" | grep -q "confidence"; then
    confidence=$(echo "$response" | grep -o '"confidence":[^,}]*' | cut -d: -f2)
    label=$(echo "$response" | grep -o '"label":"[^"]*' | cut -d'"' -f4)
    model=$(echo "$response" | grep -o '"model_version":"[^"]*' | cut -d'"' -f4)
    
    print_pass "Predict endpoint returned response"
    echo "  Label: $label | Confidence: $confidence | Model: $model"
    
    if [ "$model" = "unstable-v1" ]; then
        print_pass "Model version is correct: unstable-v1"
    else
        print_fail "Model version is wrong: $model (expected unstable-v1)"
    fi
else
    print_fail "Predict endpoint failed or returned invalid response"
    echo "  Response: $response"
fi

# ============================================================================
# 4. KUBERNETES RESOURCES
# ============================================================================
print_header "4️⃣  KUBERNETES BLUE-GREEN DEPLOYMENT"

echo "Checking Kubernetes resources..."

# Test kubectl access
if command -v kubectl &> /dev/null; then
    print_pass "kubectl is installed"
    
    # Check deployments
    print_test "Blue deployment (sentiment-blue-deployment)"
    if kubectl get deployment sentiment-blue-deployment &> /dev/null; then
        blue_ready=$(kubectl get deployment sentiment-blue-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        blue_desired=$(kubectl get deployment sentiment-blue-deployment -o jsonpath='{.spec.replicas}' 2>/dev/null)
        if [ "$blue_ready" = "$blue_desired" ] && [ "$blue_desired" -eq 2 ]; then
            print_pass "Blue deployment: $blue_ready/$blue_desired replicas ready"
        else
            print_warn "Blue deployment: $blue_ready/$blue_desired replicas ready (expected 2/2)"
        fi
    else
        print_fail "Blue deployment not found"
    fi
    
    print_test "Green deployment (sentiment-green-deployment)"
    if kubectl get deployment sentiment-green-deployment &> /dev/null; then
        green_ready=$(kubectl get deployment sentiment-green-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        green_desired=$(kubectl get deployment sentiment-green-deployment -o jsonpath='{.spec.replicas}' 2>/dev/null)
        if [ "$green_ready" = "$green_desired" ] && [ "$green_desired" -eq 2 ]; then
            print_pass "Green deployment: $green_ready/$green_desired replicas ready"
        else
            print_warn "Green deployment: $green_ready/$green_desired replicas ready (expected 2/2)"
        fi
    else
        print_fail "Green deployment not found"
    fi
    
    # Check service
    print_test "Service (sentiment-api-service) on NodePort 32500"
    if kubectl get service sentiment-api-service &> /dev/null; then
        nodeport=$(kubectl get service sentiment-api-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        selector=$(kubectl get service sentiment-api-service -o jsonpath='{.spec.selector.slot}' 2>/dev/null)
        if [ "$nodeport" = "32500" ]; then
            print_pass "NodePort is correct: 32500"
        else
            print_fail "NodePort is wrong: $nodeport (expected 32500)"
        fi
        echo "  Current selector: slot=$selector (should be 'blue' initially)"
    else
        print_fail "Service not found"
    fi
else
    print_warn "kubectl not installed - skipping Kubernetes checks"
fi

# ============================================================================
# 5. MONITORING STACK
# ============================================================================
print_header "5️⃣  MLOps MONITORING STACK"

echo "Testing Prometheus, Alertmanager, and Grafana..."

# Test Prometheus
print_test "Prometheus on port 9090"
prom_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:9090/api/v1/status")
if [ "$prom_response" = "200" ]; then
    print_pass "Prometheus is running and responding"
    
    # Check for sentiment-ml-exporter target
    print_test "Prometheus target: sentiment-ml-exporter"
    targets=$(curl -s "http://$EC2_IP:9090/api/v1/targets" 2>/dev/null)
    if echo "$targets" | grep -q "sentiment-ml-exporter"; then
        if echo "$targets" | grep -q '"health":"up".*sentiment-ml-exporter' || \
           echo "$targets" | grep -A 2 "sentiment-ml-exporter" | grep -q "up"; then
            print_pass "sentiment-ml-exporter target is UP"
        else
            print_warn "sentiment-ml-exporter target found but may not be UP"
        fi
    else
        print_fail "sentiment-ml-exporter target not found in Prometheus"
    fi
else
    print_fail "Prometheus not responding (HTTP $prom_response)"
fi

# Test Alertmanager
print_test "Alertmanager on port 9093"
alert_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:9093/api/v1/status")
if [ "$alert_response" = "200" ]; then
    print_pass "Alertmanager is running"
else
    print_fail "Alertmanager not responding (HTTP $alert_response)"
fi

# Test Custom Exporter
print_test "Custom Exporter on port 8000"
exporter_response=$(curl -s "http://$EC2_IP:8000/metrics" 2>/dev/null)
if echo "$exporter_response" | grep -q "prediction_confidence_score"; then
    metric_value=$(echo "$exporter_response" | grep "prediction_confidence_score" | grep -v "^#" | awk '{print $2}')
    print_pass "Exporter is running and exposing metric"
    echo "  Current prediction_confidence_score: $metric_value"
else
    print_fail "Exporter not found or metric not exposed"
fi

# Test Grafana
print_test "Grafana on port 3000"
grafana_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:3000/api/health")
if [ "$grafana_response" = "200" ] || [ "$grafana_response" = "404" ]; then
    print_pass "Grafana is running"
else
    print_fail "Grafana not responding (HTTP $grafana_response)"
fi

# ============================================================================
# 6. JENKINS CI/CD
# ============================================================================
print_header "6️⃣  JENKINS CI/CD PIPELINE"

echo "Testing Jenkins on port 8080..."

print_test "Jenkins accessibility"
jenkins_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:8080/")
if [ "$jenkins_response" = "200" ] || [ "$jenkins_response" = "403" ]; then
    print_pass "Jenkins is running"
    
    # Check for sentiment-ci-pipeline job
    print_test "Jenkins job: sentiment-ci-pipeline"
    jobs=$(curl -s "http://$EC2_IP:8080/api/json" 2>/dev/null)
    if echo "$jobs" | grep -q '"name":"sentiment-ci-pipeline"'; then
        print_pass "sentiment-ci-pipeline job exists"
    else
        print_warn "sentiment-ci-pipeline job not found in Jenkins API"
    fi
    
    # Check for rollback-to-stable job
    print_test "Jenkins job: rollback-to-stable"
    if echo "$jobs" | grep -q '"name":"rollback-to-stable"'; then
        print_pass "rollback-to-stable job exists"
    else
        print_warn "rollback-to-stable job not found in Jenkins API"
    fi
else
    print_fail "Jenkins not responding (HTTP $jenkins_response)"
fi

# ============================================================================
# 7. DOCKER IMAGES
# ============================================================================
print_header "7️⃣  DOCKER IMAGES"

echo "Checking Docker images on DockerHub..."

# Check unstable image
print_test "Docker image: $DOCKER_USER/sentiment-api:unstable"
if curl -s "https://hub.docker.com/v2/repositories/$DOCKER_USER/sentiment-api/tags/" 2>/dev/null | grep -q "unstable"; then
    print_pass "unstable image found on DockerHub"
else
    print_warn "unstable image may not be accessible or doesn't exist"
fi

# Check stable image
print_test "Docker image: $DOCKER_USER/sentiment-api:stable"
if curl -s "https://hub.docker.com/v2/repositories/$DOCKER_USER/sentiment-api/tags/" 2>/dev/null | grep -q "stable"; then
    print_pass "stable image found on DockerHub"
else
    print_warn "stable image may not be accessible or doesn't exist"
fi

# ============================================================================
# 8. SUMMARY
# ============================================================================
print_header "📊 TEST SUMMARY"

echo "Passed:  ${GREEN}$PASSED${NC}"
echo "Failed:  ${RED}$FAILED${NC}"
echo "Warnings: ${YELLOW}$WARNINGS${NC}"

total=$((PASSED + FAILED))
if [ $total -gt 0 ]; then
    percentage=$((PASSED * 100 / total))
    echo -e "\nSuccess Rate: ${BLUE}$percentage%${NC} ($PASSED/$total tests)"
fi

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ ALL CRITICAL TESTS PASSED! Ready for submission.${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    exit 0
elif [ $FAILED -le 2 ]; then
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠️  Some issues found. Review and fix before submission.${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    exit 1
else
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ Multiple failures detected. Fix these before submission!${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    exit 2
fi
