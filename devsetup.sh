#!/bin/bash
#
# Modular Development Environment Setup Script
# Version: 2.0.0
#

# Get script directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEV_DIR="$SCRIPT_DIR/.dev"
LIB_DIR="$DEV_DIR/lib"

# Check if .dev directory exists
if [ ! -d "$DEV_DIR" ]; then
    echo "Error: .dev directory not found. Make sure you're running the script from the correct directory."
    exit 1
fi

# Source library files
source "$LIB_DIR/core.sh"
source "$LIB_DIR/module.sh"
source "$LIB_DIR/command.sh"
source "$LIB_DIR/remote.sh"
source "$LIB_DIR/utils.sh"

# Function to initialize the system
initialize() {
    # Check if jq is installed
    check_jq
    
    # Create necessary directories if they don't exist
    ensure_dir "$DEV_DIR"
    ensure_dir "$LIB_DIR"
    ensure_dir "$CONFIG_DIR"
    ensure_dir "$WORKFLOWS_DIR"
    ensure_dir "$MODULES_DIR"
    ensure_dir "$SOFTWARE_MODULES_DIR"
    ensure_dir "$COMMAND_MODULES_DIR"
    
    # Check if config directory is empty
    if [ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
        log_message "INFO" "Config directory is empty. Creating sample configuration files."
        
        # Check if old config.json exists in the parent directory
        if [ -f "$SCRIPT_DIR/config/config.json" ]; then
            log_message "INFO" "Found existing config.json. Converting to modular format."
            convert_config_to_modules "$SCRIPT_DIR/config/config.json"
            
            # Copy VSCode extensions file if it exists
            if [ -f "$SCRIPT_DIR/config/vscode_extensions.txt" ]; then
                cp "$SCRIPT_DIR/config/vscode_extensions.txt" "$CONFIG_DIR/"
                log_message "INFO" "Copied vscode_extensions.txt to $CONFIG_DIR/"
            else
                create_sample_vscode_extensions
            fi
        else
            # Create sample modules
            create_sample_module "vscode" "software" "$SOFTWARE_MODULES_DIR"
            create_sample_module "nodejs" "software" "$SOFTWARE_MODULES_DIR"
            create_sample_module "system-cleanup" "command" "$COMMAND_MODULES_DIR"
            
            # Create sample workflow
            create_sample_workflow "default"
            
            # Create sample configuration files
            create_sample_remote_nodes
            create_sample_vscode_extensions
        fi
    fi
}

# Main function
main() {
    # Display script information
    log_message "INFO" "Modular Development Environment Setup Script v$SCRIPT_VERSION"
    
    # Initialize the system
    initialize
    
    # Parse command line arguments
    if ! parse_arguments "$@"; then
        return 1
    fi
    
    # Display configuration
    log_message "INFO" "Action: $ACTION"
    log_message "INFO" "Workflow: $WORKFLOW"
    log_message "INFO" "Install path: $INSTALL_PATH"
    if [ -n "$REMOTE_NODE" ]; then
        log_message "INFO" "Remote node: $REMOTE_NODE"
        if [ "$PARALLEL" = true ]; then
            log_message "INFO" "Parallel execution enabled"
        fi
    fi
    if [ "$DRY_RUN" = true ]; then
        log_message "INFO" "Dry run mode enabled (no changes will be made)"
    fi
    if [ ${#TARGETS[@]} -gt 0 ]; then
        log_message "INFO" "Targets: ${TARGETS[*]}"
    fi
    
    # Execute the requested action
    if [ -n "$REMOTE_NODE" ]; then
        # Remote execution
        if [ "$ACTION" = "install" ] || [ "$ACTION" = "uninstall" ]; then
            # Create a command to execute the script remotely
            local remote_command="$INSTALL_PATH/devsetup.sh --$ACTION"
            if [ -n "$WORKFLOW" ]; then
                remote_command="$remote_command --workflow $WORKFLOW"
            fi
            if [ "$DRY_RUN" = true ]; then
                remote_command="$remote_command --dry-run"
            fi
            if [ "$VERBOSE" = true ]; then
                remote_command="$remote_command --verbose"
            fi
            if [ ${#TARGETS[@]} -gt 0 ]; then
                remote_command="$remote_command ${TARGETS[*]}"
            fi
            
            # Deploy the script to the remote node
            log_message "INFO" "Deploying devsetup to remote node: $REMOTE_NODE"
            if ! deploy_to_node "$REMOTE_NODE"; then
                log_message "ERROR" "Failed to deploy devsetup to remote node: $REMOTE_NODE"
                return 1
            fi
            
            # Execute the command on the remote node
            log_message "INFO" "Executing on remote node: $REMOTE_NODE"
            remote_execute "$REMOTE_NODE" "$remote_command" "$PARALLEL"
        elif [ "$ACTION" = "command" ]; then
            # Execute the command on the remote node
            log_message "INFO" "Executing command on remote node: $REMOTE_NODE"
            remote_execute "$REMOTE_NODE" "$COMMAND" "$PARALLEL"
        else
            log_message "ERROR" "Invalid action for remote execution: $ACTION"
            return 1
        fi
    else
        # Local execution
        if [ "$ACTION" = "install" ] || [ "$ACTION" = "uninstall" ]; then
            # Process targets
            process_targets "$ACTION"
        elif [ "$ACTION" = "command" ]; then
            # Execute the command
            process_command "$COMMAND"
        else
            log_message "ERROR" "Invalid action: $ACTION"
            return 1
        fi
    fi
    
    # Display completion message
    if [ "$ACTION" = "install" ]; then
        log_message "INFO" "Installation completed"
        log_message "INFO" "To apply PATH changes, run: source $BASH_ALIASES_FILE"
    elif [ "$ACTION" = "uninstall" ]; then
        log_message "INFO" "Uninstallation completed"
    elif [ "$ACTION" = "command" ]; then
        log_message "INFO" "Command execution completed"
    fi
    
    log_message "INFO" "Log file: $LOG_FILE"
    return 0
}

# Run the main function
main "$@"
exit $?