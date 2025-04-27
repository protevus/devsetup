#!/bin/bash
#
# Core functions for the modular development environment setup system
#

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEV_DIR="$SCRIPT_DIR/.dev"
LIB_DIR="$DEV_DIR/lib"
CONFIG_DIR="$DEV_DIR/config"
WORKFLOWS_DIR="$DEV_DIR/workflows"
MODULES_DIR="$DEV_DIR/modules"
SOFTWARE_MODULES_DIR="$MODULES_DIR/software"
COMMAND_MODULES_DIR="$MODULES_DIR/commands"
DEFAULT_INSTALL_PATH="/opt/sdks"
LOG_FILE="/tmp/devsetup_$(date +%Y%m%d_%H%M%S).log"
BASH_ALIASES_FILE="$HOME/.bash_aliases"
BASH_ALIASES_BACKUP="$HOME/.bash_aliases.backup.$(date +%Y%m%d_%H%M%S)"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Display to console with color based on level
    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}[DEBUG]${NC} $message"
            fi
            ;;
        *)
            echo -e "[${level}] $message"
            ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if jq is installed
check_jq() {
    if ! command_exists jq; then
        echo -e "${YELLOW}jq is required for this script. Installing...${NC}"
        sudo apt update
        sudo apt install -y jq
        if ! command_exists jq; then
            echo -e "${RED}Failed to install jq. Please install it manually and try again.${NC}"
            exit 1
        fi
    fi
}

# Function to display help
display_help() {
    cat << EOF
Development Workstation Setup Script
Version: $SCRIPT_VERSION

Usage: $SCRIPT_NAME [OPTIONS] [TARGETS...]

Options:
  --workflow, -w WORKFLOW   Specify workflow to use (default: default)
  --install, -i             Install specified targets or all if none specified
  --uninstall, -u           Uninstall specified targets or all if none specified
  --command, -c COMMAND     Execute a specific command
  --remote, -r NODE         Execute on remote node(s)
  --parallel, -p            Execute on multiple remote nodes in parallel
  --path PATH               Specify custom installation path for SDKs (default: $DEFAULT_INSTALL_PATH)
  --dry-run                 Show what would be done without making changes
  --verbose, -v             Display verbose output
  --help, -h                Display this help message
  --version                 Display script version

Examples:
  $SCRIPT_NAME --workflow flutter-dev --install
  $SCRIPT_NAME --command system-cleanup:full-cleanup
  $SCRIPT_NAME --remote dev-laptop --workflow web-dev --install
  $SCRIPT_NAME --remote all --parallel --command update-system
EOF
}

# Function to check if a file exists
file_exists() {
    [ -f "$1" ]
}

# Function to check if a directory exists
dir_exists() {
    [ -d "$1" ]
}

# Function to create a directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_message "DEBUG" "Created directory: $dir"
    fi
}

# Function to check if a string is empty
is_empty() {
    [ -z "$1" ]
}

# Function to check if a string is not empty
is_not_empty() {
    [ -n "$1" ]
}

# Function to check if a value is in an array
in_array() {
    local value="$1"
    shift
    local array=("$@")
    for item in "${array[@]}"; do
        if [ "$item" = "$value" ]; then
            return 0
        fi
    done
    return 1
}

# Function to join array elements with a delimiter
join_by() {
    local IFS="$1"
    shift
    echo "$*"
}

# Function to get the absolute path of a file or directory
get_abs_path() {
    local path="$1"
    if [[ "$path" != /* ]]; then
        path="$(pwd)/$path"
    fi
    echo "$path"
}

# Function to check if the script is running with sudo
is_sudo() {
    [ "$(id -u)" -eq 0 ]
}

# Function to check if the script is running without sudo
is_not_sudo() {
    [ "$(id -u)" -ne 0 ]
}

# Function to get the current user
get_current_user() {
    echo "$(whoami)"
}

# Function to get the current user's home directory
get_home_dir() {
    echo "$HOME"
}

# Function to get the current timestamp
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Function to check if a variable is defined
is_defined() {
    [ -n "${!1+x}" ]
}

# Function to check if a variable is not defined
is_not_defined() {
    [ -z "${!1+x}" ]
}

# Function to check if a value is a number
is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Function to check if a value is a valid IP address
is_ip_address() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Function to check if a value is a valid hostname
is_hostname() {
    [[ "$1" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]
}

# Function to check if a value is a valid URL
is_url() {
    [[ "$1" =~ ^https?:// ]]
}

# Function to check if a value is a valid module ID
is_module_id() {
    [[ "$1" =~ ^[a-zA-Z0-9_\-]+$ ]]
}

# Function to check if a value is a valid workflow ID
is_workflow_id() {
    [[ "$1" =~ ^[a-zA-Z0-9_\-]+$ ]]
}

# Function to check if a value is a valid command ID
is_command_id() {
    [[ "$1" =~ ^[a-zA-Z0-9_\-]+$ ]]
}

# Function to check if a value is a valid node ID
is_node_id() {
    [[ "$1" =~ ^[a-zA-Z0-9_\-]+$ ]]
}

# Function to check if a value is a valid JSON
is_json() {
    jq -e . >/dev/null 2>&1 <<< "$1"
}

# Export functions
export -f log_message
export -f command_exists
export -f check_jq
export -f display_help
export -f file_exists
export -f dir_exists
export -f ensure_dir
export -f is_empty
export -f is_not_empty
export -f in_array
export -f join_by
export -f get_abs_path
export -f is_sudo
export -f is_not_sudo
export -f get_current_user
export -f get_home_dir
export -f get_timestamp
export -f is_defined
export -f is_not_defined
export -f is_number
export -f is_ip_address
export -f is_hostname
export -f is_url
export -f is_module_id
export -f is_workflow_id
export -f is_command_id
export -f is_node_id
export -f is_json