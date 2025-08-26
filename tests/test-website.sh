#!/bin/bash

echo "🧪 Testing School of DevOps Website..."
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "${GREEN}✅ $1${NC}"
}

test_failed() {
    echo -e "${RED}❌ $1${NC}"
    FAILED=true
}

test_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

FAILED=false

# Test 1: Check if container is running
echo "Test 1: Container Status"
if docker ps | grep -q "sod-app\|sod-static"; then
    test_passed "SOD container is running"
else
    if docker ps -a | grep -q "sod-app\|sod-static"; then
        test_failed "SOD container exists but not running"
    else
        test_warning "SOD container not found - building and starting..."
        cd app && docker build -t sod-static:latest .
        docker run -d --name sod-app -p 8080:80 sod-static:latest
        sleep 2
        cd ..
    fi
fi

# Test 2: HTTP Response
echo -e "\nTest 2: HTTP Response"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    test_passed "Website responds with HTTP 200"
else
    test_failed "Website not responding (HTTP: $HTTP_CODE)"
fi

# Test 3: Content Check
echo -e "\nTest 3: Content Validation"
CONTENT=$(curl -s http://localhost:8080 2>/dev/null)
if echo "$CONTENT" | grep -q "Welcome to School of DevOps"; then
    test_passed "Website contains expected content"
else
    test_failed "Website content is incorrect"
fi

# Test 4: Response Time
echo -e "\nTest 4: Performance"
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:8080 2>/dev/null)
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l 2>/dev/null) )); then
    test_passed "Response time: ${RESPONSE_TIME}s (< 1s)"
else
    test_warning "Response time: ${RESPONSE_TIME}s"
fi

# Test 5: Docker Compose Stack (if running)  
echo -e "\nTest 5: Reverse Proxy Stack"
if curl -s -H "Host: www.schoolofdevops.ro" http://localhost:8081 2>/dev/null | grep -q "Welcome to School of DevOps"; then
    test_passed "Reverse proxy stack is working"
else
    test_warning "Reverse proxy stack not running (optional)"
fi

# Summary
echo -e "\n======================================"
if [ "$FAILED" = true ]; then
    echo -e "${RED}🔴 Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}🟢 All tests passed!${NC}"
    exit 0
fi
