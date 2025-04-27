#!/bin/bash
#
# Test script for the modular development environment setup system
#

# Set colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    
    print_message "$YELLOW" "Running test: $test_name"
    echo "Command: $command"
    echo "-----------------------------------"
    
    if eval "$command"; then
        print_message "$GREEN" "✓ Test passed: $test_name"
    else
        print_message "$RED" "✗ Test failed: $test_name"
    fi
    
    echo ""
}

# Make sure the script is executable
chmod +x ./devsetup.sh

# Test 1: Help message
run_test "Display help message" "./devsetup.sh --help"

# Test 2: Version information
run_test "Display version information" "./devsetup.sh --version"

# Test 3: Dry run installation
run_test "Dry run installation" "./devsetup.sh --install --dry-run"

# Test 4: Dry run with specific target
run_test "Dry run with specific target" "./devsetup.sh --install --dry-run vscode"

# Test 5: Dry run with specific workflow
run_test "Dry run with specific workflow" "./devsetup.sh --install --workflow default --dry-run"

# Test 6: Dry run uninstallation
run_test "Dry run uninstallation" "./devsetup.sh --uninstall --dry-run vscode"

# Test 7: Dry run command execution
run_test "Dry run command execution" "./devsetup.sh --command 'system-cleanup:clean-apt' --dry-run"

# Test 8: Verbose output
run_test "Verbose output" "./devsetup.sh --install --dry-run --verbose"

# Test 9: Remote execution (dry run)
run_test "Remote execution (dry run)" "./devsetup.sh --install --remote dev-laptop --dry-run"

# Test 10: Remote command execution (dry run)
run_test "Remote command execution (dry run)" "./devsetup.sh --command 'echo \"Hello from remote\"' --remote dev-laptop --dry-run"

# Print summary
print_message "$GREEN" "All tests completed!"