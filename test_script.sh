#!/bin/bash
#
# Test script for devsetup.sh
# This script demonstrates how to use devsetup.sh with the --dry-run option
# to test installation and uninstallation without making actual changes.
#

echo "Testing devsetup.sh with --dry-run option"
echo "----------------------------------------"
echo

echo "1. Testing help display"
./devsetup.sh --help
echo

echo "2. Testing version display"
./devsetup.sh --version
echo

echo "3. Testing installation of VSCode and Flutter (dry run)"
./devsetup.sh --install --dry-run vscode flutter
echo

echo "4. Testing installation of all software (dry run)"
./devsetup.sh --install --dry-run
echo

echo "5. Testing uninstallation of Node.js (dry run)"
./devsetup.sh --uninstall --dry-run nodejs
echo

echo "6. Testing installation with custom path (dry run)"
./devsetup.sh --install --path ~/custom_sdks --dry-run go
echo

echo "Test completed. No actual changes were made to your system."
echo "To perform actual installation, run the commands without the --dry-run option."