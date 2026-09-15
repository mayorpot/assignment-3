#!/usr/bin/env bash

set -u
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-devops-tool}"

PASS=0
FAIL=0

pass() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

echo "========================================"
echo "          DOCKER BUILD & TEST"
echo "========================================"
echo

cd "$PROJECT_ROOT" || {
    echo "[ERROR] Could not enter project directory."
    exit 1
}

echo "Project root: $PROJECT_ROOT"
echo "Docker image: $IMAGE_NAME"
echo

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker is not installed or not available."
    exit 1
fi

echo "Building Docker image..."
echo

if docker build -t "$IMAGE_NAME" .; then
    pass "Docker image built successfully"
else
    fail "Docker image build failed"
fi

echo

if [[ "$FAIL" -gt 0 ]]; then
    echo "Docker build failed. Smoke tests will not run."
    exit 1
fi

echo "Running Docker smoke tests..."
echo

echo "--- Test 1: help command ---"
if docker run --rm "$IMAGE_NAME" help >/tmp/devops-docker-help.log 2>&1; then
    pass "Docker help command works"
else
    fail "Docker help command failed"
    cat /tmp/devops-docker-help.log
fi

echo
echo "--- Test 2: system-info command ---"
if docker run --rm "$IMAGE_NAME" system-info >/tmp/devops-docker-system.log 2>&1; then
    pass "Docker system-info command works"
else
    fail "Docker system-info command failed"
    cat /tmp/devops-docker-system.log
fi

echo
echo "--- Test 3: invalid command ---"
docker run --rm "$IMAGE_NAME" invalid-command >/tmp/devops-docker-invalid.log 2>&1
INVALID_EXIT=$?

if [[ "$INVALID_EXIT" -eq 2 ]]; then
    pass "Invalid command returns exit code 2"
else
    fail "Invalid command returned exit code $INVALID_EXIT instead of 2"
    cat /tmp/devops-docker-invalid.log
fi

echo
echo "--- Test 4: Compose configuration ---"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    if docker compose config >/tmp/devops-compose.log 2>&1; then
        pass "Docker Compose configuration is valid"
    else
        fail "Docker Compose configuration is invalid"
        cat /tmp/devops-compose.log
    fi
else
    echo "[INFO] Docker Compose is unavailable; skipping Compose validation."
fi

rm -f \
    /tmp/devops-docker-help.log \
    /tmp/devops-docker-system.log \
    /tmp/devops-docker-invalid.log \
    /tmp/devops-compose.log

echo
echo "========================================"
echo "           DOCKER TEST SUMMARY"
echo "========================================"
echo
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if [[ "$FAIL" -eq 0 ]]; then
    echo "Docker build and smoke tests passed."
    exit 0
fi

echo "Docker build or smoke tests failed."
exit 1