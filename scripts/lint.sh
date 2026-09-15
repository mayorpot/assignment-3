#!/usr/bin/env bash

set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
echo "          DEVOPS LINT CHECK"
echo "========================================"
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
)

echo "Checking required files..."

for file in "${required_files[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        pass "Required file exists: $file"
    else
        fail "Missing required file: $file"
    fi
done

echo
echo "Checking Bash syntax..."

bash_files=(
    "$PROJECT_ROOT/app/app.sh"
    "$PROJECT_ROOT/scripts/lint.sh"
    "$PROJECT_ROOT/scripts/build.sh"
    "$PROJECT_ROOT/tests/test.sh"
)

for file in "${bash_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        fail "Cannot syntax-check missing file: $file"
        continue
    fi

    if bash -n "$file"; then
        pass "Bash syntax valid: ${file#"$PROJECT_ROOT"/}"
    else
        fail "Bash syntax invalid: ${file#"$PROJECT_ROOT"/}"
    fi
done

echo
echo "Checking executable permissions..."

executable_files=(
    "$PROJECT_ROOT/app/app.sh"
    "$PROJECT_ROOT/scripts/lint.sh"
    "$PROJECT_ROOT/scripts/build.sh"
    "$PROJECT_ROOT/tests/test.sh"
)

for file in "${executable_files[@]}"; do
    if [[ -x "$file" ]]; then
        pass "Executable: ${file#"$PROJECT_ROOT"/}"
    else
        fail "Not executable: ${file#"$PROJECT_ROOT"/}"
    fi
done

echo
echo "Checking optional ShellCheck..."

if command -v shellcheck >/dev/null 2>&1; then
    echo "ShellCheck detected."

    for file in "${bash_files[@]}"; do
        [[ -f "$file" ]] || continue

        if shellcheck "$file"; then
            pass "ShellCheck passed: ${file#"$PROJECT_ROOT"/}"
        else
            fail "ShellCheck failed: ${file#"$PROJECT_ROOT"/}"
        fi
    done
else
    echo "ShellCheck not installed; skipping optional ShellCheck validation."
fi

echo
echo "========================================"
echo "             LINT SUMMARY"
echo "========================================"
echo
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if [[ "$FAIL" -eq 0 ]]; then
    echo "Lint checks passed."
    exit 0
fi

echo "Lint checks failed."
exit 1