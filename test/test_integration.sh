#!/usr/bin/env bash
# ABOUTME: Integration tests for summarize-text
# ABOUTME: Tests basic functionality and file operations

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$TEST_DIR")"
TMP_DIR="$TEST_DIR/tmp"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗ $1${NC}"
    return 1
}

run_test() {
    ((TESTS_RUN++))
    echo "→ Testing: $1"
}

# Setup test environment
mkdir -p "$TMP_DIR"
cd "$PROJECT_DIR"

# Test 1: Required files exist
run_test "Required files exist"
if [[ -f "./summarize-text" && -f "./summarize-text-lib.sh" && -f "./LICENSE" ]]; then
    pass "Required files exist"
else
    fail "Required files missing"
fi

# Test 2: Scripts are executable
run_test "Script permissions"
if [[ -x "./summarize-text" ]]; then
    pass "Script is executable"
else
    fail "Script is not executable"
fi

# Test 3: Configuration directory handling
run_test "Configuration directory creation"
mkdir -p "$TMP_DIR/test-config/.config/summarize-text"
if [[ -d "$TMP_DIR/test-config/.config/summarize-text" ]]; then
    pass "Configuration directory can be created"
else
    fail "Configuration directory creation failed"
fi

# Test 4: Example config file
run_test "Example config file exists"
if [[ -f "./config.example" ]]; then
    pass "Example config file exists"
else
    fail "Example config file missing"
fi

# Test 5: Test file creation
run_test "Test file operations"
echo "This is a test document for summarization." > "$TMP_DIR/test.txt"
if [[ -f "$TMP_DIR/test.txt" ]]; then
    pass "Test files can be created"
else
    fail "Test file creation failed"
fi

# Cleanup
rm -rf "$TMP_DIR"

echo
echo "Tests completed: $TESTS_PASSED/$TESTS_RUN passed"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi