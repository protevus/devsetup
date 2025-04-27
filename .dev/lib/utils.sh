#!/bin/bash
#
# Utility functions for the modular development environment setup system
#

# Source core functions if not already sourced
if [ -z "$SCRIPT_VERSION" ]; then
    source "$LIB_DIR/core.sh"
fi

# Function to parse command line arguments
parse_arguments() {
    local args=("$@")
    local i=0
    local len=${#args[@]}
    
    # Default values
    ACTION=""
    WORKFLOW="default"
    INSTALL_PATH="$DEFAULT_INSTALL_PATH"
    TARGETS=()
    REMOTE_NODE=""
    PARALLEL=false
    DRY_RUN=false
    VERBOSE=false
    COMMAND=""
    
    # Parse arguments
    while [ $i -lt $len ]; do
        case "${args[$i]}" in
            --workflow|-w)
                i=$((i+1))
                if [ $i -lt $len ]; then
                    WORKFLOW="${args[$i]}"
                else
                    log_message "ERROR" "Missing workflow name after --workflow"
                    return 1
                fi
                ;;
            --install|-i)
                if [ -n "$ACTION" ] && [ "$ACTION" != "install" ]; then
                    log_message "ERROR" "Cannot specify both install and uninstall actions"
                    return 1
                fi
                ACTION="install"
                ;;
            --uninstall|-u)
                if [ -n "$ACTION" ] && [ "$ACTION" != "uninstall" ]; then
                    log_message "ERROR" "Cannot specify both install and uninstall actions"
                    return 1
                fi
                ACTION="uninstall"
                ;;
            --command|-c)
                i=$((i+1))
                if [ $i -lt $len ]; then
                    COMMAND="${args[$i]}"
                    ACTION="command"
                else
                    log_message "ERROR" "Missing command after --command"
                    return 1
                fi
                ;;
            --remote|-r)
                i=$((i+1))
                if [ $i -lt $len ]; then
                    REMOTE_NODE="${args[$i]}"
                else
                    log_message "ERROR" "Missing node name after --remote"
                    return 1
                fi
                ;;
            --parallel|-p)
                PARALLEL=true
                ;;
            --path)
                i=$((i+1))
                if [ $i -lt $len ]; then
                    INSTALL_PATH="${args[$i]}"
                else
                    log_message "ERROR" "Missing path after --path"
                    return 1
                fi
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --verbose|-v)
                VERBOSE=true
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
                log_message "ERROR" "Unknown option: ${args[$i]}"
                display_help
                return 1
                ;;
            *)
                TARGETS+=("${args[$i]}")
                ;;
        esac
        i=$((i+1))
    done
    
    # Validate arguments
    if [ -z "$ACTION" ]; then
        log_message "ERROR" "No action specified. Use --install, --uninstall, or --command"
        return 1
    fi
    
    # Validate install path
    if [ "$ACTION" = "install" ]; then
        # Convert to absolute path if needed
        if [[ "$INSTALL_PATH" != /* ]]; then
            INSTALL_PATH="$(pwd)/$INSTALL_PATH"
        fi
        log_message "INFO" "Using installation path: $INSTALL_PATH"
    fi
    
    # Validate workflow
    if [ -n "$WORKFLOW" ] && [ ! -d "$WORKFLOWS_DIR/$WORKFLOW" ]; then
        log_message "ERROR" "Workflow not found: $WORKFLOW"
        return 1
    fi
    
    # Export variables
    export ACTION
    export WORKFLOW
    export INSTALL_PATH
    export TARGETS
    export REMOTE_NODE
    export PARALLEL
    export DRY_RUN
    export VERBOSE
    export COMMAND
    
    return 0
}

# Function to check if a target is valid
is_valid_target() {
    local target="$1"
    
    # Check if target is a valid module ID
    if find_module "$target" > /dev/null; then
        return 0
    fi
    
    # Check if target is a special case
    if [ "$target" = "vscode-extensions" ]; then
        return 0
    fi
    
    return 1
}

# Function to install VSCode extensions
install_vscode_extensions() {
    local extensions_file="$CONFIG_DIR/vscode_extensions.txt"
    
    if [ ! -f "$extensions_file" ]; then
        log_message "ERROR" "VSCode extensions file not found: $extensions_file"
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
    done < "$extensions_file"
    
    log_message "INFO" "VSCode extensions installation completed"
    return 0
}

# Function to process targets
process_targets() {
    local action="$1"
    local all_targets=()
    
    # Get all software modules
    for module_file in $(find "$SOFTWARE_MODULES_DIR" -name "*.json" 2>/dev/null); do
        local module_id=$(jq -r '.id' "$module_file")
        all_targets+=("$module_id")
    done
    
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
                return 1
            fi
        done
    fi
    
    # Process each target
    for target in "${TARGETS[@]}"; do
        if [ "$target" = "vscode-extensions" ]; then
            # Special case for VSCode extensions
            if [ "$action" = "install" ]; then
                install_vscode_extensions
            fi
        else
            # Find module
            local module_file=$(find_module "$target")
            if [ -z "$module_file" ]; then
                log_message "ERROR" "Module not found: $target"
                continue
            fi
            
            # Process module
            if [ "$action" = "install" ]; then
                install_module "$module_file"
            elif [ "$action" = "uninstall" ]; then
                uninstall_module "$module_file"
            fi
        fi
    done
    
    return 0
}

# Function to create a sample module
create_sample_module() {
    local module_id="$1"
    local module_type="$2"
    local output_dir="$3"
    
    # Validate module ID
    if ! is_module_id "$module_id"; then
        log_message "ERROR" "Invalid module ID: $module_id"
        return 1
    fi
    
    # Validate module type
    if [ "$module_type" != "software" ] && [ "$module_type" != "command" ] && [ "$module_type" != "workflow" ]; then
        log_message "ERROR" "Invalid module type: $module_type"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
    
    # Create module file
    local module_file="$output_dir/$module_id.json"
    
    # Check if file already exists
    if [ -f "$module_file" ]; then
        log_message "ERROR" "Module file already exists: $module_file"
        return 1
    fi
    
    # Create module content based on type
    if [ "$module_type" = "software" ]; then
        cat > "$module_file" << EOF
{
  "type": "software",
  "id": "$module_id",
  "name": "Sample Software",
  "description": "Sample software module",
  "check_command": "command -v sample",
  "version_regex": "^([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "echo 'Installing sample software'",
    "# Add your installation commands here"
  ],
  "uninstall_commands": [
    "echo 'Uninstalling sample software'",
    "# Add your uninstallation commands here"
  ],
  "dependencies": [
    "wget",
    "curl"
  ],
  "path_exports": [
    "export PATH=\\\$PATH:{INSTALL_PATH}/sample/bin"
  ],
  "commands": {
    "update": {
      "description": "Update sample software",
      "execute": [
        "echo 'Updating sample software'",
        "# Add your update commands here"
      ]
    },
    "reset-config": {
      "description": "Reset sample software configuration",
      "execute": [
        "echo 'Resetting sample software configuration'",
        "# Add your reset commands here"
      ]
    }
  }
}
EOF
    elif [ "$module_type" = "command" ]; then
        cat > "$module_file" << EOF
{
  "type": "command",
  "id": "$module_id",
  "name": "Sample Command",
  "description": "Sample command module",
  "commands": {
    "hello": {
      "description": "Say hello",
      "execute": [
        "echo 'Hello, world!'"
      ]
    },
    "goodbye": {
      "description": "Say goodbye",
      "execute": [
        "echo 'Goodbye, world!'"
      ]
    },
    "combined": {
      "description": "Say hello and goodbye",
      "execute": [
        "@hello",
        "@goodbye"
      ]
    }
  }
}
EOF
    elif [ "$module_type" = "workflow" ]; then
        cat > "$module_file" << EOF
{
  "type": "workflow",
  "id": "$module_id",
  "name": "Sample Workflow",
  "description": "Sample workflow module",
  "modules": [
    "vscode",
    "nodejs"
  ],
  "commands": {
    "prepare": {
      "description": "Prepare the system",
      "execute": [
        "echo 'Preparing the system'",
        "# Add your preparation commands here"
      ]
    },
    "post-install": {
      "description": "Post-installation configuration",
      "execute": [
        "echo 'Configuring the system'",
        "# Add your configuration commands here"
      ]
    }
  },
  "sequence": [
    "@prepare",
    "vscode:install",
    "nodejs:install",
    "@post-install"
  ]
}
EOF
    fi
    
    log_message "INFO" "Created sample $module_type module: $module_file"
    return 0
}

# Function to create a sample workflow
create_sample_workflow() {
    local workflow_id="$1"
    
    # Validate workflow ID
    if ! is_workflow_id "$workflow_id"; then
        log_message "ERROR" "Invalid workflow ID: $workflow_id"
        return 1
    fi
    
    # Create workflow directory
    local workflow_dir="$WORKFLOWS_DIR/$workflow_id"
    
    # Check if directory already exists
    if [ -d "$workflow_dir" ]; then
        log_message "ERROR" "Workflow directory already exists: $workflow_dir"
        return 1
    fi
    
    # Create workflow directory
    mkdir -p "$workflow_dir"
    
    # Create sample workflow files
    create_sample_module "00-prepare" "workflow" "$workflow_dir"
    create_sample_module "01-software" "workflow" "$workflow_dir"
    create_sample_module "02-cleanup" "workflow" "$workflow_dir"
    
    log_message "INFO" "Created sample workflow: $workflow_id"
    return 0
}

# Function to create a sample remote nodes configuration
create_sample_remote_nodes() {
    local nodes_file="$CONFIG_DIR/remote-nodes.json"
    
    # Check if file already exists
    if [ -f "$nodes_file" ]; then
        log_message "ERROR" "Remote nodes file already exists: $nodes_file"
        return 1
    fi
    
    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    # Create sample remote nodes configuration
    cat > "$nodes_file" << EOF
{
  "nodes": [
    {
      "id": "dev-laptop",
      "name": "Development Laptop",
      "host": "192.168.1.100",
      "user": "developer",
      "key_file": "~/.ssh/dev_laptop",
      "install_path": "/opt/sdks"
    },
    {
      "id": "team-server",
      "name": "Team Development Server",
      "host": "dev-server.example.com",
      "user": "admin",
      "key_file": "~/.ssh/team_server",
      "install_path": "/opt/development"
    }
  ],
  "groups": {
    "development": ["dev-laptop"],
    "servers": ["team-server"],
    "all": ["dev-laptop", "team-server"]
  }
}
EOF
    
    log_message "INFO" "Created sample remote nodes configuration: $nodes_file"
    return 0
}

# Function to create a sample VSCode extensions file
create_sample_vscode_extensions() {
    local extensions_file="$CONFIG_DIR/vscode_extensions.txt"
    
    # Check if file already exists
    if [ -f "$extensions_file" ]; then
        log_message "ERROR" "VSCode extensions file already exists: $extensions_file"
        return 1
    fi
    
    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    # Create sample VSCode extensions file
    cat > "$extensions_file" << EOF
# VSCode Extensions
# Format: publisher.extension-name

# General
ms-vscode.vscode-node-azure-pack
ms-vscode-remote.vscode-remote-extensionpack
ms-vsliveshare.vsliveshare

# Git
eamodio.gitlens
mhutchie.git-graph

# Languages
ms-vscode.cpptools
ms-python.python
ms-dotnettools.csharp
golang.go
redhat.java
dart-code.dart-code
dart-code.flutter

# Web Development
dbaeumer.vscode-eslint
esbenp.prettier-vscode
ritwickdey.liveserver

# Themes
dracula-theme.theme-dracula
pkief.material-icon-theme

# Utilities
streetsidesoftware.code-spell-checker
EOF
    
    log_message "INFO" "Created sample VSCode extensions file: $extensions_file"
    return 0
}

# Function to convert existing config.json to modular format
convert_config_to_modules() {
    local config_file="$1"
    local output_dir="$SOFTWARE_MODULES_DIR"
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        log_message "ERROR" "Config file not found: $config_file"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
    
    # Get all software entries from config.json
    local software_ids=$(jq -r 'keys[]' "$config_file")
    
    # Process each software entry
    for id in $software_ids; do
        log_message "INFO" "Processing $id..."
        
        # Extract software details
        jq -r --arg id "$id" '.[$id] | 
          {
            "type": "software",
            "id": $id,
            "name": .name,
            "description": "Software module for " + .name,
            "check_command": .check_command,
            "version_regex": .version_regex,
            "install_commands": .install_commands,
            "uninstall_commands": .uninstall_commands,
            "dependencies": .dependencies,
            "path_exports": (.path_exports // [])
          }' "$config_file" > "$output_dir/$id.json"
        
        log_message "INFO" "Created $output_dir/$id.json"
    done
    
    # Create a basic system cleanup command module
    local command_dir="$COMMAND_MODULES_DIR"
    if [ ! -d "$command_dir" ]; then
        mkdir -p "$command_dir"
    fi
    
    cat > "$command_dir/system-cleanup.json" << EOF
{
  "type": "command",
  "id": "system-cleanup",
  "name": "System Cleanup",
  "description": "Clean up system by removing unused packages and cache",
  "commands": {
    "clean-apt": {
      "description": "Clean APT cache",
      "execute": [
        "sudo apt autoremove -y",
        "sudo apt clean"
      ]
    },
    "clean-docker": {
      "description": "Clean Docker images and containers",
      "execute": [
        "docker system prune -f"
      ],
      "requires": ["docker"]
    },
    "full-cleanup": {
      "description": "Perform a full system cleanup",
      "execute": [
        "@clean-apt",
        "@clean-docker"
      ]
    }
  }
}
EOF
    
    log_message "INFO" "Created $command_dir/system-cleanup.json"
    
    # Create a default workflow
    local workflow_dir="$WORKFLOWS_DIR/default"
    if [ ! -d "$workflow_dir" ]; then
        mkdir -p "$workflow_dir"
    fi
    
    cat > "$workflow_dir/00-prepare.json" << EOF
{
  "type": "workflow",
  "id": "prepare",
  "name": "Prepare System",
  "description": "Prepare the system for software installation",
  "commands": {
    "update-system": {
      "description": "Update system packages",
      "execute": [
        "sudo apt update",
        "sudo apt upgrade -y"
      ]
    }
  },
  "sequence": [
    "@update-system"
  ]
}
EOF
    
    log_message "INFO" "Created $workflow_dir/00-prepare.json"
    
    # Create a workflow sequence based on the original targets
    cat > "$workflow_dir/01-software.json" << EOF
{
  "type": "workflow",
  "id": "software-installation",
  "name": "Software Installation",
  "description": "Install all software packages",
  "modules": [
$(for id in $software_ids; do echo "    \"$id\","; done | sed '$ s/,$//')
  ],
  "sequence": [
$(for id in $software_ids; do echo "    \"$id:install\","; done | sed '$ s/,$//')
  ]
}
EOF
    
    log_message "INFO" "Created $workflow_dir/01-software.json"
    
    cat > "$workflow_dir/02-cleanup.json" << EOF
{
  "type": "workflow",
  "id": "cleanup",
  "name": "System Cleanup",
  "description": "Clean up after installation",
  "sequence": [
    "@system-cleanup:full-cleanup"
  ]
}
EOF
    
    log_message "INFO" "Created $workflow_dir/02-cleanup.json"
    
    log_message "INFO" "Conversion complete!"
    return 0
}

# Export functions
export -f parse_arguments
export -f is_valid_target
export -f install_vscode_extensions
export -f process_targets
export -f create_sample_module
export -f create_sample_workflow
export -f create_sample_remote_nodes
export -f create_sample_vscode_extensions
export -f convert_config_to_modules