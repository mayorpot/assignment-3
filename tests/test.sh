#!/usr/bin/env bash

set -u
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$PROJECT_ROOT/app/app.sh"

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

run_success_test() {
    local name="$1"
    shift

    if "$@" >/tmp/devops-test-output.log 2>&1; then
        pass "$name"
    else
        fail "$name"
        cat /tmp/devops-test-output.log
    fi
}

run_failure_test() {
    local name="$1"
    shift

    if "$@" >/tmp/devops-test-output.log 2>&1; then
        fail "$name"
        cat /tmp/devops-test-output.log
    else
        pass "$name"
    fi
}

run_exit_code_test() {
    local name="$1"
    local expected="$2"
    shift 2

    "$@" >/tmp/devops-test-output.log 2>&1
    local actual=$?

    if [[ "$actual" -eq "$expected" ]]; then
        pass "$name"
    else
        fail "$name — expected $expected, got $actual"
        cat /tmp/devops-test-output.log
    fi
}

echo "========================================"
echo "       DEVOPS APPLICATION TESTS"
echo "========================================"
echo

echo "Application: $APP"
echo

if [[ ! -x "$APP" ]]; then
    echo "[ERROR] Application is missing or not executable."
    exit 1
fi

echo "Running required functional tests..."
echo

# 1
run_success_test \
    "help command works" \
    "$APP" help

# 2
run_success_test \
    "system-info command works" \
    "$APP" system-info

# 3
run_exit_code_test \
    "missing command returns exit code 2" \
    2 \
    "$APP"

# 4
run_exit_code_test \
    "invalid command returns exit code 2" \
    2 \
    "$APP" invalid-command

# 5
run_success_test \
    "check-host works with a valid host" \
    "$APP" check-host google.com

# 6
run_exit_code_test \
    "missing host returns exit code 2" \
    2 \
    "$APP" check-host

# 7
run_exit_code_test \
    "missing port returns exit code 2" \
    2 \
    "$APP" check-port google.com

# 8
run_exit_code_test \
    "non-numeric port returns exit code 2" \
    2 \
    "$APP" check-port google.com abc

# 9
run_exit_code_test \
    "port below valid range returns exit code 2" \
    2 \
    "$APP" check-port google.com 0

# 10
run_exit_code_test \
    "port above valid range returns exit code 2" \
    2 \
    "$APP" check-port google.com 65536

# 11
run_exit_code_test \
    "extra system-info argument returns exit code 2" \
    2 \
    "$APP" system-info extra

# 12
run_exit_code_test \
    "extra help argument returns exit code 2" \
    2 \
    "$APP" help extra

echo
echo "========================================"
echo "             TEST SUMMARY"
echo "========================================"
echo
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

rm -f /tmp/devops-test-output.log

if [[ "$FAIL" -eq 0 ]]; then
    echo "All application tests passed."
    exit 0
fi

echo "Some application tests failed."
exit 1