#!/bin/bash
#
# Remote execution functions for the modular development environment setup system
#

# Source core functions if not already sourced
if [ -z "$SCRIPT_VERSION" ]; then
    source "$(dirname "$0")/core.sh"
fi

# Source module functions if not already sourced
if [ -z "$validate_module" ]; then
    source "$LIB_DIR/module.sh"
fi

# Source command functions if not already sourced
if [ -z "$process_command" ]; then
    source "$LIB_DIR/command.sh"
fi

# Function to get node details
get_node_details() {
    local node_id="$1"
    local nodes_file="$CONFIG_DIR/remote-nodes.json"
    
    # Check if nodes file exists
    if [ ! -f "$nodes_file" ]; then
        log_message "ERROR" "Remote nodes file not found: $nodes_file"
        return 1
    fi
    
    # Get node details
    local node_details=$(jq -r --arg id "$node_id" '.nodes[] | select(.id == $id)' "$nodes_file")
    if [ -z "$node_details" ]; then
        log_message "ERROR" "Node not found: $node_id"
        return 1
    fi
    
    echo "$node_details"
}

# Function to get all nodes
get_all_nodes() {
    local nodes_file="$CONFIG_DIR/remote-nodes.json"
    
    # Check if nodes file exists
    if [ ! -f "$nodes_file" ]; then
        log_message "ERROR" "Remote nodes file not found: $nodes_file"
        return 1
    fi
    
    # Get all node IDs
    jq -r '.nodes[].id' "$nodes_file"
}

# Function to check if a node is valid
is_valid_node() {
    local node_id="$1"
    local nodes_file="$CONFIG_DIR/remote-nodes.json"
    
    # Check if nodes file exists
    if [ ! -f "$nodes_file" ]; then
        log_message "ERROR" "Remote nodes file not found: $nodes_file"
        return 1
    fi
    
    # Check if node exists
    jq -e --arg id "$node_id" '.nodes[] | select(.id == $id)' "$nodes_file" > /dev/null
}

# Function to check if a node group exists
is_node_group() {
    local group_id="$1"
    local nodes_file="$CONFIG_DIR/remote-nodes.json"
    
    # Check if nodes file exists
    if [ ! -f "$nodes_file" ]; then
        log_message "ERROR" "Remote nodes file not found: $nodes_file"
        return 1
    fi
    
    # Check if group exists
    jq -e --arg id "$group_id" '.groups[$id]' "$nodes_file" > /dev/null
}

# Function to get nodes in a group
get_nodes_in_group() {
    local group_id="$1"
    local nodes_file="$CONFIG_DIR/remote-nodes.json"
    
    # Check if nodes file exists
    if [ ! -f "$nodes_file" ]; then
        log_message "ERROR" "Remote nodes file not found: $nodes_file"
        return 1
    fi
    
    # Get nodes in group
    jq -r --arg id "$group_id" '.groups[$id][]' "$nodes_file"
}

# Function to execute a command on a single node
execute_on_node() {
    local node_id="$1"
    local command="$2"
    
    # Get node details
    local node_details=$(get_node_details "$node_id")
    if [ -z "$node_details" ]; then
        log_message "ERROR" "Node details not found for: $node_id"
        return 1
    fi
    
    local host=$(echo "$node_details" | jq -r '.host')
    local user=$(echo "$node_details" | jq -r '.user')
    local key_file=$(echo "$node_details" | jq -r '.key_file')
    local install_path=$(echo "$node_details" | jq -r '.install_path')
    
    # Expand key file path if it contains ~
    key_file="${key_file/#\~/$HOME}"
    
    # Check if key file exists
    if [ ! -f "$key_file" ]; then
        log_message "ERROR" "SSH key file not found: $key_file"
        return 1
    fi
    
    # Prepare remote command
    local remote_command="$command"
    remote_command="${remote_command/\{INSTALL_PATH\}/$install_path}"
    
    # Execute command via SSH
    log_message "INFO" "Executing on $node_id ($host): $remote_command"
    if [ "$DRY_RUN" = false ]; then
        if ! ssh -i "$key_file" "$user@$host" "$remote_command"; then
            log_message "ERROR" "Remote execution failed on $node_id: $remote_command"
            return 1
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would execute on $node_id: $remote_command"
    fi
    
    return 0
}

# Function to execute commands in parallel on multiple nodes
parallel_execute_on_nodes() {
    local nodes=("${@:1:$#-1}")
    local command="${@: -1}"
    
    log_message "INFO" "Executing in parallel on ${#nodes[@]} nodes"
    
    # Create a temporary directory for output files
    local tmp_dir=$(mktemp -d)
    
    # Start background processes for each node
    for node in "${nodes[@]}"; do
        execute_on_node "$node" "$command" > "$tmp_dir/$node.out" 2> "$tmp_dir/$node.err" &
        log_message "DEBUG" "Started execution on $node (PID: $!)"
    done
    
    # Wait for all processes to complete
    wait
    
    # Collect and display results
    for node in "${nodes[@]}"; do
        log_message "INFO" "Results from $node:"
        if [ -s "$tmp_dir/$node.err" ]; then
            log_message "ERROR" "Errors on $node:"
            cat "$tmp_dir/$node.err"
        fi
        if [ -s "$tmp_dir/$node.out" ]; then
            cat "$tmp_dir/$node.out"
        fi
    done
    
    # Clean up
    rm -rf "$tmp_dir"
    
    return 0
}

# Function to execute on remote nodes
remote_execute() {
    local node_spec="$1"
    local command="$2"
    local parallel="$3"
    
    # Get nodes to execute on
    local nodes=()
    if [[ "$node_spec" == "all" ]]; then
        # All nodes
        nodes=($(get_all_nodes))
    elif is_node_group "$node_spec"; then
        # Node group
        nodes=($(get_nodes_in_group "$node_spec"))
    else
        # Single node
        if is_valid_node "$node_spec"; then
            nodes=("$node_spec")
        else
            log_message "ERROR" "Invalid node: $node_spec"
            return 1
        fi
    fi
    
    if [ ${#nodes[@]} -eq 0 ]; then
        log_message "ERROR" "No nodes found for: $node_spec"
        return 1
    fi
    
    # Execute on nodes
    if [ "$parallel" = true ] && [ ${#nodes[@]} -gt 1 ]; then
        # Parallel execution
        parallel_execute_on_nodes "${nodes[@]}" "$command"
    else
        # Sequential execution
        for node in "${nodes[@]}"; do
            execute_on_node "$node" "$command"
        done
    fi
}

# Function to copy files to a remote node
copy_to_node() {
    local node_id="$1"
    local source_path="$2"
    local dest_path="$3"
    
    # Get node details
    local node_details=$(get_node_details "$node_id")
    if [ -z "$node_details" ]; then
        log_message "ERROR" "Node details not found for: $node_id"
        return 1
    fi
    
    local host=$(echo "$node_details" | jq -r '.host')
    local user=$(echo "$node_details" | jq -r '.user')
    local key_file=$(echo "$node_details" | jq -r '.key_file')
    
    # Expand key file path if it contains ~
    key_file="${key_file/#\~/$HOME}"
    
    # Check if key file exists
    if [ ! -f "$key_file" ]; then
        log_message "ERROR" "SSH key file not found: $key_file"
        return 1
    fi
    
    # Check if source path exists
    if [ ! -e "$source_path" ]; then
        log_message "ERROR" "Source path not found: $source_path"
        return 1
    fi
    
    # Copy files via SCP
    log_message "INFO" "Copying $source_path to $node_id:$dest_path"
    if [ "$DRY_RUN" = false ]; then
        if ! scp -i "$key_file" -r "$source_path" "$user@$host:$dest_path"; then
            log_message "ERROR" "Failed to copy files to $node_id"
            return 1
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would copy $source_path to $node_id:$dest_path"
    fi
    
    return 0
}

# Function to copy files from a remote node
copy_from_node() {
    local node_id="$1"
    local source_path="$2"
    local dest_path="$3"
    
    # Get node details
    local node_details=$(get_node_details "$node_id")
    if [ -z "$node_details" ]; then
        log_message "ERROR" "Node details not found for: $node_id"
        return 1
    fi
    
    local host=$(echo "$node_details" | jq -r '.host')
    local user=$(echo "$node_details" | jq -r '.user')
    local key_file=$(echo "$node_details" | jq -r '.key_file')
    
    # Expand key file path if it contains ~
    key_file="${key_file/#\~/$HOME}"
    
    # Check if key file exists
    if [ ! -f "$key_file" ]; then
        log_message "ERROR" "SSH key file not found: $key_file"
        return 1
    fi
    
    # Create destination directory if it doesn't exist
    if [ ! -d "$(dirname "$dest_path")" ]; then
        mkdir -p "$(dirname "$dest_path")"
    fi
    
    # Copy files via SCP
    log_message "INFO" "Copying $node_id:$source_path to $dest_path"
    if [ "$DRY_RUN" = false ]; then
        if ! scp -i "$key_file" -r "$user@$host:$source_path" "$dest_path"; then
            log_message "ERROR" "Failed to copy files from $node_id"
            return 1
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would copy $node_id:$source_path to $dest_path"
    fi
    
    return 0
}

# Function to deploy the devsetup system to a remote node
deploy_to_node() {
    local node_id="$1"
    
    # Get node details
    local node_details=$(get_node_details "$node_id")
    if [ -z "$node_details" ]; then
        log_message "ERROR" "Node details not found for: $node_id"
        return 1
    fi
    
    local host=$(echo "$node_details" | jq -r '.host')
    local user=$(echo "$node_details" | jq -r '.user')
    local key_file=$(echo "$node_details" | jq -r '.key_file')
    local install_path=$(echo "$node_details" | jq -r '.install_path')
    
    # Expand key file path if it contains ~
    key_file="${key_file/#\~/$HOME}"
    
    # Check if key file exists
    if [ ! -f "$key_file" ]; then
        log_message "ERROR" "SSH key file not found: $key_file"
        return 1
    fi
    
    # Create remote directory
    log_message "INFO" "Creating remote directory: $install_path"
    if [ "$DRY_RUN" = false ]; then
        if ! ssh -i "$key_file" "$user@$host" "mkdir -p $install_path"; then
            log_message "ERROR" "Failed to create remote directory: $install_path"
            return 1
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would create remote directory: $install_path"
    fi
    
    # Copy devsetup files
    log_message "INFO" "Copying devsetup files to $node_id"
    if [ "$DRY_RUN" = false ]; then
        # Copy main script
        if ! scp -i "$key_file" "$SCRIPT_DIR/devsetup.sh" "$user@$host:$install_path/"; then
            log_message "ERROR" "Failed to copy devsetup.sh to $node_id"
            return 1
        fi
        
        # Create .dev directory on remote node
        if ! ssh -i "$key_file" "$user@$host" "mkdir -p $install_path/.dev/{lib,config,workflows/{default,modules/{software,commands}}}"; then
            log_message "ERROR" "Failed to create .dev directory on $node_id"
            return 1
        fi
        
        # Copy lib files
        if ! scp -i "$key_file" "$LIB_DIR"/* "$user@$host:$install_path/.dev/lib/"; then
            log_message "ERROR" "Failed to copy lib files to $node_id"
            return 1
        fi
        
        # Copy config files
        if ! scp -i "$key_file" "$CONFIG_DIR"/* "$user@$host:$install_path/.dev/config/"; then
            log_message "ERROR" "Failed to copy config files to $node_id"
            return 1
        fi
        
        # Copy workflow files
        if ! scp -i "$key_file" -r "$WORKFLOWS_DIR"/* "$user@$host:$install_path/.dev/workflows/"; then
            log_message "ERROR" "Failed to copy workflow files to $node_id"
            return 1
        fi
        
        # Make script executable
        if ! ssh -i "$key_file" "$user@$host" "chmod +x $install_path/devsetup.sh"; then
            log_message "ERROR" "Failed to make devsetup.sh executable on $node_id"
            return 1
        fi
    else
        log_message "DEBUG" "[DRY RUN] Would copy devsetup files to $node_id"
    fi
    
    log_message "INFO" "Deployment to $node_id completed"
    return 0
}

# Export functions
export -f get_node_details
export -f get_all_nodes
export -f is_valid_node
export -f is_node_group
export -f get_nodes_in_group
export -f execute_on_node
export -f parallel_execute_on_nodes
export -f remote_execute
export -f copy_to_node
export -f copy_from_node
export -f deploy_to_node