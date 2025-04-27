#!/bin/bash
#
# Command processing functions for the modular development environment setup system
#

# Source core functions if not already sourced
if [ -z "$SCRIPT_VERSION" ]; then
    source "$(dirname "$0")/core.sh"
fi

# Source module functions if not already sourced
if [ -z "$validate_module" ]; then
    source "$LIB_DIR/module.sh"
fi

# Function to find a command in a module
find_command_in_module() {
    local module_id="$1"
    local command_id="$2"
    
    # Find module
    local module_file=$(find_module "$module_id")
    if [ -z "$module_file" ]; then
        log_message "ERROR" "Module not found: $module_id"
        return 1
    fi
    
    # Extract command definition
    local command_def=$(jq -r --arg cmd "$command_id" '.commands[$cmd] // empty' "$module_file")
    if [ -z "$command_def" ]; then
        log_message "ERROR" "Command $command_id not found in module $module_id"
        return 1
    fi
    
    echo "$command_def"
}

# Function to find a standalone command
find_command() {
    local command_id="$1"
    
    # Search in command modules
    for module_file in $(find "$COMMAND_MODULES_DIR" -name "*.json" 2>/dev/null); do
        local commands=$(jq -r --arg cmd "$command_id" '.commands[$cmd] // empty' "$module_file")
        if [ -n "$commands" ]; then
            echo "$commands"
            return 0
        fi
    done
    
    log_message "ERROR" "Command not found: $command_id"
    return 1
}

# Function to replace variables in a command
replace_variables() {
    local command="$1"
    local params="$2"
    
    # Replace standard variables
    command="${command/\{INSTALL_PATH\}/$INSTALL_PATH}"
    command="${command/\{CONFIG_DIR\}/$CONFIG_DIR}"
    command="${command/\{SCRIPT_DIR\}/$SCRIPT_DIR}"
    command="${command/\{DEV_DIR\}/$DEV_DIR}"
    command="${command/\{LIB_DIR\}/$LIB_DIR}"
    command="${command/\{WORKFLOWS_DIR\}/$WORKFLOWS_DIR}"
    command="${command/\{MODULES_DIR\}/$MODULES_DIR}"
    command="${command/\{SOFTWARE_MODULES_DIR\}/$SOFTWARE_MODULES_DIR}"
    command="${command/\{COMMAND_MODULES_DIR\}/$COMMAND_MODULES_DIR}"
    
    # Replace custom parameters
    if [ -n "$params" ]; then
        # Parse params as JSON if it's a JSON string
        if [[ "$params" == {* ]]; then
            # Extract each parameter and replace in command
            for param in $(echo "$params" | jq -r 'keys[]'); do
                local value=$(echo "$params" | jq -r --arg p "$param" '.[$p]')
                command="${command/\{$param\}/$value}"
            done
        fi
    fi
    
    echo "$command"
}

# Function to process a command
process_command() {
    local command_spec="$1"  # Format: module_id:command_id or just command_id
    local params="${@:2}"
    
    # Parse module and command IDs
    local module_id command_id
    if [[ "$command_spec" == *":"* ]]; then
        module_id="${command_spec%%:*}"
        command_id="${command_spec#*:}"
    else
        module_id=""
        command_id="$command_spec"
    fi
    
    # Find the command
    local command_def
    if [ -n "$module_id" ]; then
        # Command in a specific module
        command_def=$(find_command_in_module "$module_id" "$command_id")
    else
        # Standalone command
        command_def=$(find_command "$command_id")
    fi
    
    if [ -z "$command_def" ]; then
        log_message "ERROR" "Command not found: $command_spec"
        return 1
    fi
    
    # Execute the command
    execute_command "$command_def" "$params"
}

# Function to execute a command
execute_command() {
    local command_def="$1"
    local params="$2"
    
    # Check if command has requirements
    if echo "$command_def" | jq -e 'has("requires")' > /dev/null; then
        local requires=$(echo "$command_def" | jq -r '.requires[]')
        for req in $requires; do
            if ! command_exists "$req"; then
                log_message "ERROR" "Command requires $req, but it is not installed"
                return 1
            fi
        done
    fi
    
    # Get command execution steps
    local execute_steps=$(echo "$command_def" | jq -r '.execute[]')
    
    # Process each step
    for step in $execute_steps; do
        if [[ "$step" == @* ]]; then
            # Reference to another command
            local ref_command="${step:1}"
            process_command "$ref_command" "$params"
        else
            # Shell command
            # Replace variables
            step=$(replace_variables "$step" "$params")
            
            # Execute the command
            log_message "INFO" "Executing: $step"
            if [ "$DRY_RUN" = false ]; then
                if ! eval "$step"; then
                    log_message "ERROR" "Command failed: $step"
                    return 1
                fi
            else
                log_message "DEBUG" "[DRY RUN] Would execute: $step"
            fi
        fi
    done
    
    return 0
}

# Function to execute a workflow
execute_workflow() {
    local workflow_id="$1"
    local params="$2"
    
    # Find workflow directory
    local workflow_dir="$WORKFLOWS_DIR/$workflow_id"
    if [ ! -d "$workflow_dir" ]; then
        log_message "ERROR" "Workflow directory not found: $workflow_dir"
        return 1
    fi
    
    log_message "INFO" "Executing workflow: $workflow_id"
    
    # Load workflow modules
    local modules=$(load_workflow_modules "$workflow_dir")
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to load workflow modules"
        return 1
    fi
    
    # Process each module in order
    for module_file in $modules; do
        local module_type=$(jq -r '.type // "unknown"' "$module_file")
        local module_id=$(jq -r '.id' "$module_file")
        
        log_message "INFO" "Processing module: $module_id"
        
        if [ "$module_type" = "workflow" ]; then
            # Execute workflow sequence
            local sequence=$(jq -r '.sequence[]' "$module_file")
            for step in $sequence; do
                if [[ "$step" == @* ]]; then
                    # Reference to a command
                    local command="${step:1}"
                    process_command "$command" "$params"
                elif [[ "$step" == *":"* ]]; then
                    # Module:action format
                    local module="${step%%:*}"
                    local action="${step#*:}"
                    
                    # Find the module
                    local target_module=$(find_module "$module")
                    if [ -z "$target_module" ]; then
                        log_message "ERROR" "Module not found: $module"
                        continue
                    fi
                    
                    # Execute the action
                    if [ "$action" = "install" ]; then
                        install_module "$target_module"
                    elif [ "$action" = "uninstall" ]; then
                        uninstall_module "$target_module"
                    else
                        # Try to execute as a command
                        process_command "$step" "$params"
                    fi
                else
                    log_message "ERROR" "Invalid workflow step: $step"
                fi
            done
        elif [ "$module_type" = "software" ]; then
            # Install software module
            install_module "$module_file"
        elif [ "$module_type" = "command" ]; then
            # Nothing to do for command modules in workflow execution
            log_message "DEBUG" "Skipping command module: $module_id"
        else
            log_message "ERROR" "Unknown module type: $module_type"
        fi
    done
    
    log_message "INFO" "Workflow execution completed: $workflow_id"
    return 0
}

# Export functions
export -f find_command_in_module
export -f find_command
export -f replace_variables
export -f process_command
export -f execute_command
export -f execute_workflow