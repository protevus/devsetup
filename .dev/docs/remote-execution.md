# Remote Execution Guide

This guide provides detailed information about DevSetup's remote execution capabilities, including how to configure remote nodes, execute operations on remote machines, and manage multiple nodes.

## Overview

DevSetup supports executing operations on remote machines via SSH. This allows you to set up multiple machines with the same configuration, execute commands on remote servers, and manage your entire development infrastructure from a single control point.

## Remote Node Configuration

Remote nodes are defined in the `.dev/config/remote-nodes.json` file. This file contains information about each remote machine, including connection details and installation paths.

### Configuration File Structure

```json
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
```

### Node Configuration Fields

| Field | Description | Required |
|-------|-------------|----------|
| `id` | Unique identifier for the node | Yes |
| `name` | Human-readable name for the node | Yes |
| `host` | Hostname or IP address of the node | Yes |
| `user` | Username for SSH connection | Yes |
| `key_file` | Path to the SSH private key file | Yes |
| `install_path` | Path where software will be installed | Yes |
| `port` | SSH port (default: 22) | No |
| `sudo_password` | Sudo password for the user (not recommended, use SSH keys with sudo privileges) | No |
| `options` | Additional SSH options | No |

### Node Groups

Node groups allow you to execute operations on multiple nodes at once. Groups are defined in the `groups` section of the configuration file.

Example:

```json
"groups": {
  "development": ["dev-laptop", "dev-desktop"],
  "servers": ["team-server", "build-server"],
  "all": ["dev-laptop", "dev-desktop", "team-server", "build-server"]
}
```

## Basic Remote Execution

To execute operations on a remote node, use the `--remote` option followed by the node ID:

```bash
# Install software on a remote node
./devsetup.sh --install --remote dev-laptop

# Execute a command on a remote node
./devsetup.sh --command "system-cleanup:full-cleanup" --remote team-server

# Uninstall software on a remote node
./devsetup.sh --uninstall vscode --remote dev-laptop
```

## Executing on Multiple Nodes

To execute operations on multiple nodes, use a node group:

```bash
# Install software on all development machines
./devsetup.sh --install --remote development

# Execute a command on all servers
./devsetup.sh --command "system-cleanup:full-cleanup" --remote servers

# Install software on all nodes
./devsetup.sh --install --remote all
```

## Parallel Execution

By default, operations on multiple nodes are executed sequentially. To execute operations in parallel, use the `--parallel` option:

```bash
# Install software on all nodes in parallel
./devsetup.sh --install --remote all --parallel

# Execute a command on all servers in parallel
./devsetup.sh --command "system-cleanup:full-cleanup" --remote servers --parallel
```

## Remote Deployment

DevSetup can deploy itself to remote nodes, allowing you to set up new machines from scratch:

```bash
# Deploy DevSetup to a remote node
./devsetup.sh --deploy --remote dev-laptop

# Deploy DevSetup to all nodes
./devsetup.sh --deploy --remote all
```

This will:
1. Copy the DevSetup files to the remote node
2. Set up the necessary directory structure
3. Make the script executable
4. Configure the remote node for DevSetup

## SSH Key Setup

Remote execution requires SSH key authentication. To set up SSH keys:

1. Generate an SSH key pair (if you don't already have one):
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

2. Copy the public key to the remote node:
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub user@hostname
```

3. Test the connection:
```bash
ssh -i ~/.ssh/id_rsa user@hostname
```

4. Update the remote node configuration with the key file path:
```json
{
  "id": "dev-laptop",
  "name": "Development Laptop",
  "host": "192.168.1.100",
  "user": "developer",
  "key_file": "~/.ssh/id_rsa",
  "install_path": "/opt/sdks"
}
```

## Sudo Access

Many DevSetup operations require sudo access on the remote node. To configure sudo access without a password:

1. Log in to the remote node
2. Edit the sudoers file:
```bash
sudo visudo
```

3. Add the following line (replace `username` with your username):
```
username ALL=(ALL) NOPASSWD: ALL
```

4. Save and exit

## Remote Execution Process

When executing operations on a remote node, DevSetup follows these steps:

1. **Connection**: Establish an SSH connection to the remote node
2. **Deployment**: Copy necessary files to the remote node (if needed)
3. **Execution**: Execute the requested operation on the remote node
4. **Monitoring**: Monitor the execution and report progress
5. **Cleanup**: Clean up temporary files and close the connection

## Advanced Remote Execution

### Custom SSH Options

You can specify custom SSH options for a node:

```json
{
  "id": "dev-laptop",
  "name": "Development Laptop",
  "host": "192.168.1.100",
  "user": "developer",
  "key_file": "~/.ssh/id_rsa",
  "install_path": "/opt/sdks",
  "options": "-o StrictHostKeyChecking=no -o ConnectTimeout=10"
}
```

### Environment Variables

You can specify environment variables for remote execution:

```bash
# Set environment variables for remote execution
./devsetup.sh --install --remote dev-laptop --env "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 PATH=/usr/local/bin:$PATH"
```

### Remote Command Execution

You can execute arbitrary commands on remote nodes:

```bash
# Execute a shell command on a remote node
./devsetup.sh --command "ls -la /opt" --remote dev-laptop

# Execute a script on a remote node
./devsetup.sh --command "bash /path/to/script.sh" --remote dev-laptop
```

### Remote File Transfer

You can transfer files to and from remote nodes:

```bash
# Copy a file to a remote node
./devsetup.sh --copy-to "local-file.txt:/remote/path/file.txt" --remote dev-laptop

# Copy a file from a remote node
./devsetup.sh --copy-from "/remote/path/file.txt:local-file.txt" --remote dev-laptop
```

## Troubleshooting Remote Execution

### Connection Issues

If you're having trouble connecting to a remote node:

1. **Check SSH Connection**: Try connecting manually using SSH:
```bash
ssh -i ~/.ssh/id_rsa user@hostname
```

2. **Check Key Permissions**: Ensure your SSH key has the correct permissions:
```bash
chmod 600 ~/.ssh/id_rsa
```

3. **Check Host Key**: If the remote host key has changed, you may need to update your known_hosts file:
```bash
ssh-keygen -R hostname
```

4. **Check Firewall**: Ensure that the SSH port (usually 22) is open on the remote node.

### Sudo Issues

If you're having trouble with sudo access:

1. **Check Sudo Configuration**: Ensure that your user has sudo access on the remote node:
```bash
sudo -l
```

2. **Configure Passwordless Sudo**: If you're prompted for a password, configure passwordless sudo as described above.

3. **Use Sudo Password**: If you can't configure passwordless sudo, you can specify the sudo password in the node configuration (not recommended for security reasons):
```json
{
  "id": "dev-laptop",
  "name": "Development Laptop",
  "host": "192.168.1.100",
  "user": "developer",
  "key_file": "~/.ssh/id_rsa",
  "install_path": "/opt/sdks",
  "sudo_password": "your-sudo-password"
}
```

### Execution Issues

If you're having trouble executing operations on a remote node:

1. **Check Logs**: Check the DevSetup logs for error messages:
```bash
cat $(ls -t /tmp/devsetup_*.log | head -1)
```

2. **Enable Verbose Mode**: Use the `--verbose` option to get more detailed output:
```bash
./devsetup.sh --install --remote dev-laptop --verbose
```

3. **Try Dry Run**: Use the `--dry-run` option to see what commands would be executed without actually executing them:
```bash
./devsetup.sh --install --remote dev-laptop --dry-run
```

## Best Practices

When using remote execution, follow these best practices:

1. **Use SSH Keys**: Always use SSH key authentication instead of passwords.
2. **Configure Passwordless Sudo**: Configure sudo access without a password for seamless execution.
3. **Use Node Groups**: Organize nodes into logical groups for easier management.
4. **Test with Dry Run**: Always test operations with the `--dry-run` option before executing them.
5. **Monitor Execution**: Use the `--verbose` option to monitor execution and identify issues.
6. **Secure Key Files**: Ensure that SSH key files have the correct permissions (600).
7. **Use Parallel Execution**: Use parallel execution for large-scale deployments to save time.
8. **Document Node Configuration**: Document your node configuration for future reference.
9. **Backup Remote Nodes**: Backup important data on remote nodes before making significant changes.
10. **Use Version Control**: Keep your DevSetup configuration in version control for tracking changes.

## Next Steps

Now that you understand remote execution, you can:

- Learn about [Software Modules](software-modules.md) to see what software is available
- Check out [Command Modules](command-modules.md) to execute custom operations
- Explore [Workflows](workflows.md) to understand how to combine modules
- See [Advanced Usage](advanced-usage.md) for more advanced features