#!/bin/bash
#
# Module handling functions for the modular development environment setup system
#

# Source core functions if not already sourced
if [ -z "$SCRIPT_VERSION" ]; then
    source "$LIB_DIR/core.sh"
fi

# Function to validate a module
validate_module() {
    local module_file="$1"
    local required_fields=()
    local module_type
    
    # Check if file exists
    if [ ! -f "$module_file" ]; then
        log_message "ERROR" "Module file not found: $module_file"
        return 1
    fi
    
    # Check if file is valid JSON
    if ! jq -e . "$module_file" > /dev/null 2>&1; then
        log_message "ERROR" "Module file is not valid JSON: $module_file"
        return 1
    fi
    
    # Get module type
    module_type=$(jq -r '.type // "unknown"' "$module_file")
    
    # Set required fields based on module type
    case "$module_type" in
        "software")
            required_fields=("id" "name" "check_command" "install_commands" "uninstall_commands")
            ;;
        "command")
            required_fields=("id" "name" "commands")
            ;;
        "workflow")
            required_fields=("id" "name" "sequence")
            ;;
        *)
            log_message "ERROR" "Unknown module type: $module_type in $module_file"
            return 1
            ;;
    esac
    
    # Check required fields
    for field in "${required_fields[@]}"; do
        if ! jq -e "has(\"$field\")" "$module_file" > /dev/null; then
            log_message "ERROR" "Module $module_file is missing required field: $field"
            return 1
        fi
    done
    
    return 0
}

# Function to load modules from a workflow directory
load_workflow_modules() {
    local workflow_dir="$1"
    local modules=()
    
    # Check if workflow directory exists
    if [ ! -d "$workflow_dir" ]; then
        log_message "ERROR" "Workflow directory not found: $workflow_dir"
        return 1
    fi
    
    # Get list of module files in order
    for module_file in $(ls -v "$workflow_dir"/*.json 2>/dev/null); do
        if [ -f "$module_file" ]; then
            # Validate module
            if validate_module "$module_file"; then
                modules+=("$module_file")
            else
                log_message "WARNING" "Skipping invalid module: $module_file"
            fi
        fi
    done
    
    log_message "INFO" "Loaded ${#modules[@]} modules from workflow: $(basename "$workflow_dir")"
    echo "${modules[@]}"
}

# Function to find a module by ID
find_module() {
    local module_id="$1"
    local search_dirs=("$MODULES_DIR/software" "$MODULES_DIR/commands" "$WORKFLOWS_DIR")
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            # Search for module file
            for file in $(find "$dir" -name "*.json" 2>/dev/null); do
                local id=$(jq -r '.id // ""' "$file")
                if [ "$id" = "$module_id" ]; then
                    echo "$file"
                    return 0
                fi
            done
        fi
    done
    
    log_message "ERROR" "Module not found: $module_id"
    return 1
}

# Function to compose modules into a single configuration
compose_modules() {
    local modules=("$@")
    local combined_config="{}"
    
    for module_file in "${modules[@]}"; do
        # Get module ID
        local module_id=$(jq -r '.id' "$module_file")
        
        # Add module to combined config
        combined_config=$(echo "$combined_config" | jq --argjson module "$(cat "$module_file")" '. + {"'"$module_id"'": $module}')
    done
    
    echo "$combined_config"
}

# Function to check if a module is installed
check_module_installed() {
    local module_file="$1"
    local check_command
    local version_regex
    
    # Get module type
    local module_type=$(jq -r '.type // "unknown"' "$module_file")
    
    # Only software modules can be checked for installation
    if [ "$module_type" != "software" ]; then
        log_message "ERROR" "Cannot check installation for non-software module: $module_file"
        return 1
    fi
    
    # Get check command and version regex
    check_command=$(jq -r '.check_command // ""' "$module_file")
    version_regex=$(jq -r '.version_regex // ""' "$module_file")
    
    if [ -z "$check_command" ]; then
        log_message "ERROR" "No check command found for module: $module_file"
        return 1
    fi
    
    # Replace {INSTALL_PATH} placeholder in check command
    check_command="${check_command/\{INSTALL_PATH\}/$INSTALL_PATH}"
    
    log_message "DEBUG" "Checking if module is installed with command: $check_command"
    
    # Execute the check command
    if eval "$check_command" &> /tmp/check_output; then
        # Command succeeded, module is installed
        if [ -n "$version_regex" ]; then
            # Extract version using regex if provided
            version=$(grep -oP "$version_regex" /tmp/check_output | head -1)
            if [ -n "$version" ]; then
                log_message "INFO" "Module is installed (version: $version)"
            else
                log_message "INFO" "Module is installed (version unknown)"
            fi
        else
            log_message "INFO" "Module is installed"
        fi
        return 0
    else
        log_message "INFO" "Module is not installed"
        return 1
    fi
}

# Function to check and install module dependencies
check_module_dependencies() {
    local module_file="$1"
    local dependencies
    
    # Get module type
    local module_type=$(jq -r '.type // "unknown"' "$module_file")
    
    # Only software modules can have dependencies
    if [ "$module_type" != "software" ]; then
        return 0
    fi
    
    # Get dependencies
    dependencies=$(jq -r '.dependencies[]?' "$module_file")
    
    if [ -z "$dependencies" ]; then
        log_message "DEBUG" "No dependencies found for module: $module_file"
        return 0
    fi
    
    log_message "INFO" "Checking dependencies for module: $(jq -r '.name' "$module_file")..."
    
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

# Function to install a module
install_module() {
    local module_file="$1"
    local module_name
    local install_commands
    
    # Get module type
    local module_type=$(jq -r '.type // "unknown"' "$module_file")
    
    # Only software modules can be installed
    if [ "$module_type" != "software" ]; then
        log_message "ERROR" "Cannot install non-software module: $module_file"
        return 1
    fi
    
    # Get module name and install commands
    module_name=$(jq -r '.name' "$module_file")
    install_commands=$(jq -r '.install_commands[]?' "$module_file")
    
    if [ -z "$install_commands" ]; then
        log_message "ERROR" "No install commands found for module: $module_file"
        return 1
    fi
    
    log_message "INFO" "Installing $module_name..."
    
    # Check if already installed
    if check_module_installed "$module_file"; then
        log_message "INFO" "$module_name is already installed. Skipping installation."
        return 0
    fi
    
    # Check and install dependencies
    if ! check_module_dependencies "$module_file"; then
        log_message "ERROR" "Failed to install dependencies for $module_name"
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
    update_module_path_exports "$module_file"
    
    log_message "INFO" "$module_name installation completed"
    return 0
}

# Function to uninstall a module
uninstall_module() {
    local module_file="$1"
    local module_name
    local uninstall_commands
    
    # Get module type
    local module_type=$(jq -r '.type // "unknown"' "$module_file")
    
    # Only software modules can be uninstalled
    if [ "$module_type" != "software" ]; then
        log_message "ERROR" "Cannot uninstall non-software module: $module_file"
        return 1
    fi
    
    # Get module name and uninstall commands
    module_name=$(jq -r '.name' "$module_file")
    uninstall_commands=$(jq -r '.uninstall_commands[]?' "$module_file")
    
    if [ -z "$uninstall_commands" ]; then
        log_message "ERROR" "No uninstall commands found for module: $module_file"
        return 1
    fi
    
    log_message "INFO" "Uninstalling $module_name..."
    
    # Check if installed
    if ! check_module_installed "$module_file"; then
        log_message "INFO" "$module_name is not installed. Skipping uninstallation."
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
    remove_module_path_exports "$module_file"
    
    log_message "INFO" "$module_name uninstallation completed"
    return 0
}

# Function to update PATH exports for a module
update_module_path_exports() {
    local module_file="$1"
    local module_id=$(jq -r '.id' "$module_file")
    local path_exports
    
    # Get module type
    local module_type=$(jq -r '.type // "unknown"' "$module_file")
    
    # Only software modules can have PATH exports
    if [ "$module_type" != "software" ]; then
        return 0
    fi
    
    # Get path exports
    path_exports=$(jq -r '.path_exports[]?' "$module_file")
    
    if [ -z "$path_exports" ]; then
        log_message "DEBUG" "No PATH exports needed for module: $module_file"
        return 0
    fi
    
    log_message "INFO" "Updating PATH exports for $module_id..."
    
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
    local marker_start="# BEGIN $module_id PATH exports - managed by devsetup.sh"
    local marker_end="# END $module_id PATH exports"
    
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
        
        log_message "INFO" "Updated PATH exports in .bash_aliases for $module_id"
    else
        log_message "DEBUG" "[DRY RUN] Would update PATH exports in .bash_aliases for $module_id"
    fi
    
    return 0
}

# Function to remove PATH exports for a module
remove_module_path_exports() {
    local module_file="$1"
    local module_id=$(jq -r '.id' "$module_file")
    
    log_message "INFO" "Removing PATH exports for $module_id..."
    
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
    local marker_start="# BEGIN $module_id PATH exports - managed by devsetup.sh"
    local marker_end="# END $module_id PATH exports"
    
    if [ "$DRY_RUN" = false ]; then
        # Remove existing section if it exists
        if grep -q "$marker_start" "$BASH_ALIASES_FILE"; then
            sed -i "/^$marker_start/,/^$marker_end/d" "$BASH_ALIASES_FILE"
            log_message "INFO" "Removed PATH exports from .bash_aliases for $module_id"
        else
            log_message "DEBUG" "No PATH exports found for $module_id in .bash_aliases"
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would remove PATH exports from .bash_aliases for $module_id"
    fi
    
    return 0
}

# Export functions
export -f validate_module
export -f load_workflow_modules
export -f find_module
export -f compose_modules
export -f check_module_installed
export -f check_module_dependencies
export -f install_module
export -f uninstall_module
export -f update_module_path_exports
export -f remove_module_path_exports