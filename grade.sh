#!/usr/bin/env bash

set -u
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
echo "        ASSIGNMENT 3 GRADER"
echo "========================================"
echo

cd "$PROJECT_ROOT" || exit 1

echo "1. Checking required files..."
echo

required_files=(
    "README.md"
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    ".github/workflows/ci.yml"
    "Dockerfile"
    "compose.yaml"
    ".dockerignore"
    "grade.sh"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        pass "Required file exists: $file"
    else
        fail "Missing required file: $file"
    fi
done

echo
echo "2. Checking executable permissions..."
echo

executable_files=(
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    "grade.sh"
)

for file in "${executable_files[@]}"; do
    if [[ -x "$file" ]]; then
        pass "Executable: $file"
    else
        fail "Not executable: $file"
    fi
done

echo
echo "3. Checking Bash syntax..."
echo

bash_files=(
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    "grade.sh"
)

for file in "${bash_files[@]}"; do
    if bash -n "$file" >/dev/null 2>&1; then
        pass "Bash syntax valid: $file"
    else
        fail "Bash syntax invalid: $file"
    fi
done

echo
echo "4. Checking GitHub Actions workflow..."
echo

WORKFLOW=".github/workflows/ci.yml"

if grep -q "push:" "$WORKFLOW"; then
    pass "Workflow has push trigger"
else
    fail "Workflow missing push trigger"
fi

if grep -q "pull_request:" "$WORKFLOW"; then
    pass "Workflow has pull_request trigger"
else
    fail "Workflow missing pull_request trigger"
fi

if grep -q "^  validate:" "$WORKFLOW"; then
    pass "Validate job exists"
else
    fail "Validate job missing"
fi

if grep -q "^  test:" "$WORKFLOW"; then
    pass "Test job exists"
else
    fail "Test job missing"
fi

if grep -q "^  docker:" "$WORKFLOW"; then
    pass "Docker job exists"
else
    fail "Docker job missing"
fi

if grep -A10 "^  test:" "$WORKFLOW" | grep -q "needs: validate"; then
    pass "Test depends on validate"
else
    fail "Test does not depend on validate"
fi

if grep -A10 "^  docker:" "$WORKFLOW" | grep -q "needs: test"; then
    pass "Docker depends on test"
else
    fail "Docker does not depend on test"
fi

echo
echo "5. Running application tests..."
echo

if ./tests/test.sh; then
    pass "Application test suite passed"
else
    fail "Application test suite failed"
fi

echo
echo "6. Running lint checks..."
echo

if ./scripts/lint.sh; then
    pass "Lint checks passed"
else
    fail "Lint checks failed"
fi

echo
echo "7. Checking Docker..."
echo

if command -v docker >/dev/null 2>&1; then

    if docker build -t devops-tool-grade-test . >/tmp/assignment3-docker-build.log 2>&1; then
        pass "Docker image builds successfully"
    else
        fail "Docker image build failed"
        cat /tmp/assignment3-docker-build.log
    fi

    if docker run --rm devops-tool-grade-test help >/tmp/assignment3-docker-help.log 2>&1; then
        pass "Docker help smoke test passed"
    else
        fail "Docker help smoke test failed"
        cat /tmp/assignment3-docker-help.log
    fi

    if docker run --rm devops-tool-grade-test system-info >/tmp/assignment3-docker-system.log 2>&1; then
        pass "Docker system-info smoke test passed"
    else
        fail "Docker system-info smoke test failed"
        cat /tmp/assignment3-docker-system.log
    fi

    docker run --rm devops-tool-grade-test invalid-command \
        >/tmp/assignment3-docker-invalid.log 2>&1

    invalid_exit=$?

    if [[ "$invalid_exit" -eq 2 ]]; then
        pass "Docker invalid-command test returned exit code 2"
    else
        fail "Docker invalid-command test returned $invalid_exit instead of 2"
        cat /tmp/assignment3-docker-invalid.log
    fi

    docker image rm devops-tool-grade-test >/dev/null 2>&1 || true

else
    fail "Docker is not available"
fi

echo
echo "8. Checking Git repository..."
echo

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    pass "Git repository detected"
else
    fail "Git repository not detected"
fi

commit_count=$(git rev-list --count HEAD 2>/dev/null || echo 0)

if [[ "$commit_count" -ge 2 ]]; then
    pass "Git history contains multiple commits"
else
    fail "Git history contains fewer than 2 commits"
fi

echo
echo "9. Checking README documentation..."
echo

if grep -qi "Docker" README.md; then
    pass "README documents Docker"
else
    fail "README does not document Docker"
fi

if grep -qi "GitHub Actions" README.md; then
    pass "README documents GitHub Actions"
else
    fail "README does not document GitHub Actions"
fi

if grep -qi "test" README.md; then
    pass "README documents testing"
else
    fail "README does not document testing"
fi

echo
echo "========================================"
echo "             FINAL RESULT"
echo "========================================"
echo
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

rm -f \
    /tmp/assignment3-docker-build.log \
    /tmp/assignment3-docker-help.log \
    /tmp/assignment3-docker-system.log \
    /tmp/assignment3-docker-invalid.log

if [[ "$FAIL" -eq 0 ]]; then
    echo "ASSIGNMENT 3 LOCAL CHECKS PASSED"
    exit 0
fi

echo "ASSIGNMENT 3 LOCAL CHECKS FAILED"
exit 1