#!/bin/bash
#
# Development Workstation Setup Script for Ubuntu 24.04
# This script installs and uninstalls development tools and SDKs
# Version: 1.0.0
#

# Script configuration
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")
DEFAULT_INSTALL_PATH="/opt/sdks"
CONFIG_DIR="$(dirname "$(readlink -f "$0")")/config"
CONFIG_FILE="$CONFIG_DIR/config.json"
VSCODE_EXTENSIONS_FILE="$CONFIG_DIR/vscode_extensions.txt"
LOG_FILE="/tmp/devsetup_$(date +%Y%m%d_%H%M%S).log"
BASH_ALIASES_FILE="$HOME/.bash_aliases"
BASH_ALIASES_BACKUP="$HOME/.bash_aliases.backup.$(date +%Y%m%d_%H%M%S)"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
ACTION=""
INSTALL_PATH="$DEFAULT_INSTALL_PATH"
TARGETS=()
DRY_RUN=false
VERBOSE=false

# Check if jq is installed, as we need it to parse JSON
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}jq is required for this script. Installing...${NC}"
    sudo apt update
    sudo apt install -y jq
fi

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

# Function to display help
display_help() {
    cat << EOF
Development Workstation Setup Script for Ubuntu 24.04
Version: $SCRIPT_VERSION

Usage: $SCRIPT_NAME [OPTIONS] [TARGETS...]

Options:
  --install, -i       Install specified targets or all if none specified
  --uninstall, -u     Uninstall specified targets or all if none specified
  --path PATH         Specify custom installation path for SDKs (default: $DEFAULT_INSTALL_PATH)
  --dry-run           Show what would be done without making changes
  --verbose, -v       Display verbose output
  --help, -h          Display this help message
  --version           Display script version

Targets:
  vscode              Visual Studio Code
  vscode-extensions   VSCode Extensions (requires VSCode)
  gitkraken           GitKraken
  chrome              Google Chrome
  edge                Microsoft Edge
  flutter             Flutter SDK
  android-sdk         Android SDK
  android-studio      Android Studio
  dotnet              .NET SDK
  go                  Go Programming Language
  jdk                 Java Development Kit
  nodejs              Node.js

Examples:
  $SCRIPT_NAME --install                     # Install all targets
  $SCRIPT_NAME --install vscode flutter      # Install only VSCode and Flutter
  $SCRIPT_NAME --uninstall nodejs            # Uninstall Node.js
  $SCRIPT_NAME --install --path ~/sdks go    # Install Go to ~/sdks
EOF
}

# Function to parse command line arguments
parse_arguments() {
    if [ $# -eq 0 ]; then
        display_help
        exit 0
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            --install|-i)
                if [ -n "$ACTION" ] && [ "$ACTION" != "install" ]; then
                    log_message "ERROR" "Cannot specify both install and uninstall actions"
                    exit 1
                fi
                ACTION="install"
                shift
                ;;
            --uninstall|-u)
                if [ -n "$ACTION" ] && [ "$ACTION" != "uninstall" ]; then
                    log_message "ERROR" "Cannot specify both install and uninstall actions"
                    exit 1
                fi
                ACTION="uninstall"
                shift
                ;;
            --path)
                INSTALL_PATH="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                display_help
                exit 0
                ;;
            --version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
                ;;
            -*)
                log_message "ERROR" "Unknown option: $1"
                display_help
                exit 1
                ;;
            *)
                TARGETS+=("$1")
                shift
                ;;
        esac
    done

    # Validate arguments
    if [ -z "$ACTION" ]; then
        log_message "ERROR" "No action specified. Use --install or --uninstall"
        exit 1
    fi

    # Validate install path
    if [ "$ACTION" = "install" ]; then
        # Convert to absolute path if needed
        if [[ "$INSTALL_PATH" != /* ]]; then
            INSTALL_PATH="$(pwd)/$INSTALL_PATH"
        fi
        log_message "INFO" "Using installation path: $INSTALL_PATH"
    fi
}

# Function to check if a target is valid
is_valid_target() {
    local target="$1"
    local valid_targets=(
        "vscode" "vscode-extensions" "gitkraken" "chrome" "edge"
        "flutter" "android-sdk" "android-studio" "dotnet" "go" "jdk" "nodejs"
    )
    
    for valid_target in "${valid_targets[@]}"; do
        if [ "$target" = "$valid_target" ]; then
            return 0
        fi
    done
    
    return 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if a target is installed
check_installed() {
    local target="$1"
    local check_command
    local version_regex
    
    # Get check command and version regex from config
    # Use quotes around the key to handle keys with hyphens
    check_command=$(jq -r ".\"$target\".check_command // \"\"" "$CONFIG_FILE")
    version_regex=$(jq -r ".\"$target\".version_regex // \"\"" "$CONFIG_FILE")
    
    if [ -z "$check_command" ]; then
        log_message "ERROR" "No check command found for target: $target"
        return 1
    fi
    
    # Replace {INSTALL_PATH} placeholder in check command
    check_command="${check_command/\{INSTALL_PATH\}/$INSTALL_PATH}"
    
    log_message "DEBUG" "Checking if $target is installed with command: $check_command"
    
    # Execute the check command
    if eval "$check_command" &> /tmp/check_output; then
        # Command succeeded, target is installed
        if [ -n "$version_regex" ]; then
            # Extract version using regex if provided
            version=$(grep -oP "$version_regex" /tmp/check_output | head -1)
            if [ -n "$version" ]; then
                log_message "INFO" "$target is installed (version: $version)"
            else
                log_message "INFO" "$target is installed (version unknown)"
            fi
        else
            log_message "INFO" "$target is installed"
        fi
        return 0
    else
        log_message "INFO" "$target is not installed"
        return 1
    fi
}

# Function to check and install dependencies
check_dependencies() {
    local target="$1"
    local dependencies
    
    # Get dependencies from config
    # Use quotes around the key to handle keys with hyphens
    dependencies=$(jq -r ".\"$target\".dependencies[]?" "$CONFIG_FILE")
    
    if [ -z "$dependencies" ]; then
        log_message "DEBUG" "No dependencies found for target: $target"
        return 0
    fi
    
    log_message "INFO" "Checking dependencies for $target..."
    
    # Check and install each dependency
    for dep in $dependencies; do
        if ! command_exists "$dep"; then
            log_message "INFO" "Installing dependency: $dep"
            if [ "$DRY_RUN" = false ]; then
                sudo apt update
                sudo apt install -y "$dep"
                if ! command_exists "$dep"; then
                    log_message "ERROR" "Failed to install dependency: $dep"
                    return 1
                fi
            else
                log_message "DEBUG" "[DRY RUN] Would install dependency: $dep"
            fi
        else
            log_message "DEBUG" "Dependency already installed: $dep"
        fi
    done
    
    return 0
}

# Function to update bash_aliases file
update_bash_aliases() {
    local target="$1"
    local path_exports
    
    # Get path exports from config
    # Use quotes around the key to handle keys with hyphens
    path_exports=$(jq -r ".\"$target\".path_exports[]?" "$CONFIG_FILE")
    
    if [ -z "$path_exports" ]; then
        log_message "DEBUG" "No PATH exports needed for target: $target"
        return 0
    fi
    
    log_message "INFO" "Updating PATH exports for $target..."
    
    # Create backup of bash_aliases if it exists and we haven't already backed it up
    if [ -f "$BASH_ALIASES_FILE" ] && [ ! -f "$BASH_ALIASES_BACKUP" ]; then
        if [ "$DRY_RUN" = false ]; then
            cp "$BASH_ALIASES_FILE" "$BASH_ALIASES_BACKUP"
            log_message "INFO" "Created backup of .bash_aliases at $BASH_ALIASES_BACKUP"
        else
            log_message "DEBUG" "[DRY RUN] Would create backup of .bash_aliases"
        fi
    fi
    
    # Create bash_aliases file if it doesn't exist
    if [ ! -f "$BASH_ALIASES_FILE" ] && [ "$DRY_RUN" = false ]; then
        touch "$BASH_ALIASES_FILE"
    fi
    
    # Add a section marker for our exports
    local marker_start="# BEGIN $target PATH exports - managed by devsetup.sh"
    local marker_end="# END $target PATH exports"
    
    # Replace {INSTALL_PATH} placeholder in path exports
    path_exports="${path_exports/\{INSTALL_PATH\}/$INSTALL_PATH}"
    
    if [ "$DRY_RUN" = false ]; then
        # Remove existing section if it exists
        if grep -q "$marker_start" "$BASH_ALIASES_FILE"; then
            sed -i "/^$marker_start/,/^$marker_end/d" "$BASH_ALIASES_FILE"
        fi
        
        # Add new section
        echo "$marker_start" >> "$BASH_ALIASES_FILE"
        echo "$path_exports" >> "$BASH_ALIASES_FILE"
        echo "$marker_end" >> "$BASH_ALIASES_FILE"
        
        log_message "INFO" "Updated PATH exports in .bash_aliases for $target"
    else
        log_message "DEBUG" "[DRY RUN] Would update PATH exports in .bash_aliases for $target"
    fi
    
    return 0
}

# Function to remove path exports from bash_aliases
remove_path_exports() {
    local target="$1"
    
    log_message "INFO" "Removing PATH exports for $target..."
    
    # Create backup of bash_aliases if it exists and we haven't already backed it up
    if [ -f "$BASH_ALIASES_FILE" ] && [ ! -f "$BASH_ALIASES_BACKUP" ]; then
        if [ "$DRY_RUN" = false ]; then
            cp "$BASH_ALIASES_FILE" "$BASH_ALIASES_BACKUP"
            log_message "INFO" "Created backup of .bash_aliases at $BASH_ALIASES_BACKUP"
        else
            log_message "DEBUG" "[DRY RUN] Would create backup of .bash_aliases"
        fi
    fi
    
    # Check if bash_aliases file exists
    if [ ! -f "$BASH_ALIASES_FILE" ]; then
        log_message "DEBUG" ".bash_aliases file does not exist, nothing to remove"
        return 0
    fi
    
    # Define section markers
    local marker_start="# BEGIN $target PATH exports - managed by devsetup.sh"
    local marker_end="# END $target PATH exports"
    
    if [ "$DRY_RUN" = false ]; then
        # Remove existing section if it exists
        if grep -q "$marker_start" "$BASH_ALIASES_FILE"; then
            sed -i "/^$marker_start/,/^$marker_end/d" "$BASH_ALIASES_FILE"
            log_message "INFO" "Removed PATH exports from .bash_aliases for $target"
        else
            log_message "DEBUG" "No PATH exports found for $target in .bash_aliases"
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would remove PATH exports from .bash_aliases for $target"
    fi
    
    return 0
}

# Function to install VSCode extensions
install_vscode_extensions() {
    if [ ! -f "$VSCODE_EXTENSIONS_FILE" ]; then
        log_message "ERROR" "VSCode extensions file not found: $VSCODE_EXTENSIONS_FILE"
        return 1
    fi
    
    # Check if VSCode is installed
    if ! command_exists code; then
        log_message "ERROR" "VSCode is not installed. Cannot install extensions."
        return 1
    fi
    
    log_message "INFO" "Installing VSCode extensions..."
    
    # Read extensions from file and install each one
    while IFS= read -r extension || [ -n "$extension" ]; do
        # Skip empty lines and comments
        if [ -z "$extension" ] || [[ "$extension" == \#* ]]; then
            continue
        fi
        
        log_message "INFO" "Installing VSCode extension: $extension"
        if [ "$DRY_RUN" = false ]; then
            code --install-extension "$extension" --force
        else
            log_message "DEBUG" "[DRY RUN] Would install VSCode extension: $extension"
        fi
    done < "$VSCODE_EXTENSIONS_FILE"
    
    log_message "INFO" "VSCode extensions installation completed"
    return 0
}

# Function to install a target
install_target() {
    local target="$1"
    local target_name
    local install_commands
    
    # Get target name and install commands from config
    # Use quotes around the key to handle keys with hyphens
    target_name=$(jq -r ".\"$target\".name // \"$target\"" "$CONFIG_FILE")
    install_commands=$(jq -r ".\"$target\".install_commands[]?" "$CONFIG_FILE")
    
    if [ -z "$install_commands" ]; then
        log_message "ERROR" "No install commands found for target: $target"
        return 1
    fi
    
    log_message "INFO" "Installing $target_name..."
    
    # Check if already installed
    if check_installed "$target"; then
        log_message "INFO" "$target_name is already installed. Skipping installation."
        return 0
    fi
    
    # Check and install dependencies
    if ! check_dependencies "$target"; then
        log_message "ERROR" "Failed to install dependencies for $target"
        return 1
    fi
    
    # Create installation directory if needed
    if [[ "$install_commands" == *"{INSTALL_PATH}"* ]]; then
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$INSTALL_PATH"
            sudo chown -R $(whoami):$(whoami) "$INSTALL_PATH"
        else
            log_message "DEBUG" "[DRY RUN] Would create directory: $INSTALL_PATH"
        fi
    fi
    
    # Execute install commands
    for cmd in $install_commands; do
        # Replace {INSTALL_PATH} placeholder
        cmd="${cmd/\{INSTALL_PATH\}/$INSTALL_PATH}"
        
        log_message "DEBUG" "Executing: $cmd"
        if [ "$DRY_RUN" = false ]; then
            if ! eval "$cmd"; then
                log_message "ERROR" "Failed to execute command: $cmd"
                return 1
            fi
        else
            log_message "DEBUG" "[DRY RUN] Would execute: $cmd"
        fi
    done
    
    # Update PATH exports if needed
    update_bash_aliases "$target"
    
    # Special case for VSCode extensions
    if [ "$target" = "vscode" ] && [[ " ${TARGETS[@]} " =~ " vscode-extensions " ]]; then
        log_message "INFO" "VSCode installed. Will install extensions later."
    elif [ "$target" = "vscode-extensions" ]; then
        install_vscode_extensions
    fi
    
    log_message "INFO" "$target_name installation completed"
    return 0
}

# Function to uninstall a target
uninstall_target() {
    local target="$1"
    local target_name
    local uninstall_commands
    
    # Get target name and uninstall commands from config
    # Use quotes around the key to handle keys with hyphens
    target_name=$(jq -r ".\"$target\".name // \"$target\"" "$CONFIG_FILE")
    uninstall_commands=$(jq -r ".\"$target\".uninstall_commands[]?" "$CONFIG_FILE")
    
    if [ -z "$uninstall_commands" ]; then
        log_message "ERROR" "No uninstall commands found for target: $target"
        return 1
    fi
    
    log_message "INFO" "Uninstalling $target_name..."
    
    # Check if installed
    if ! check_installed "$target"; then
        log_message "INFO" "$target_name is not installed. Skipping uninstallation."
        return 0
    fi
    
    # Execute uninstall commands
    for cmd in $uninstall_commands; do
        # Replace {INSTALL_PATH} placeholder
        cmd="${cmd/\{INSTALL_PATH\}/$INSTALL_PATH}"
        
        log_message "DEBUG" "Executing: $cmd"
        if [ "$DRY_RUN" = false ]; then
            if ! eval "$cmd"; then
                log_message "WARNING" "Command failed: $cmd"
                # Continue with other commands
            fi
        else
            log_message "DEBUG" "[DRY RUN] Would execute: $cmd"
        fi
    done
    
    # Remove PATH exports
    remove_path_exports "$target"
    
    log_message "INFO" "$target_name uninstallation completed"
    return 0
}

# Function to process targets
process_targets() {
    local action="$1"
    local all_targets=(
        "vscode" "gitkraken" "chrome" "edge"
        "flutter" "android-sdk" "android-studio" "dotnet" "go" "jdk" "nodejs"
    )
    
    # If no targets specified, use all targets
    if [ ${#TARGETS[@]} -eq 0 ]; then
        log_message "INFO" "No targets specified. Using all targets."
        TARGETS=("${all_targets[@]}")
        
        # Add vscode-extensions if vscode is included
        if [[ " ${TARGETS[@]} " =~ " vscode " ]]; then
            TARGETS+=("vscode-extensions")
        fi
    else
        # Validate targets
        for target in "${TARGETS[@]}"; do
            if ! is_valid_target "$target"; then
                log_message "ERROR" "Invalid target: $target"
                exit 1
            fi
        done
    fi
    
    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "ERROR" "Config file not found: $CONFIG_FILE"
        log_message "INFO" "Please create the config file with installation details for each target."
        exit 1
    fi
    
    # Process each target
    for target in "${TARGETS[@]}"; do
        if [ "$action" = "install" ]; then
            install_target "$target"
        elif [ "$action" = "uninstall" ]; then
            uninstall_target "$target"
        fi
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Display script information
    log_message "INFO" "Development Workstation Setup Script v$SCRIPT_VERSION"
    log_message "INFO" "Action: $ACTION"
    log_message "INFO" "Install path: $INSTALL_PATH"
    if [ "$DRY_RUN" = true ]; then
        log_message "INFO" "Dry run mode enabled (no changes will be made)"
    fi
    
    # Process targets
    process_targets "$ACTION"
    
    # Display completion message
    if [ "$ACTION" = "install" ]; then
        log_message "INFO" "Installation completed"
        log_message "INFO" "To apply PATH changes, run: source $BASH_ALIASES_FILE"
    else
        log_message "INFO" "Uninstallation completed"
    fi
    
    log_message "INFO" "Log file: $LOG_FILE"
}

# Run the main function
main "$@"