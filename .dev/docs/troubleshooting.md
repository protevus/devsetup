# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when using DevSetup, along with diagnostic steps and remediation actions.

## Installation Issues

### Software Installation Fails

**Symptoms:**
- Error messages during software installation
- Software not installed correctly
- Installation process hangs or times out

**Possible Causes:**
1. Missing dependencies
2. Network connectivity issues
3. Insufficient permissions
4. Conflicting software versions
5. Disk space issues

**Diagnostic Steps:**
1. Check the log file for error messages:
```bash
cat $(ls -t /tmp/devsetup_*.log | head -1)
```

2. Run the installation with verbose output:
```bash
./devsetup.sh --install --verbose
```

3. Try a dry run to see what commands would be executed:
```bash
./devsetup.sh --install --dry-run
```

**Solutions:**

1. **Missing Dependencies:**
```bash
# Install common dependencies
sudo apt update
sudo apt install -y curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release software-properties-common
```

2. **Network Connectivity:**
```bash
# Check network connectivity
ping -c 4 google.com

# If using a proxy, configure it
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
```

3. **Permissions Issues:**
```bash
# Ensure the script is executable
chmod +x devsetup.sh

# Ensure you have sudo access
sudo -v

# Fix permissions on the installation directory
sudo chown -R $(whoami):$(whoami) /opt/sdks
```

4. **Conflicting Software:**
```bash
# Remove conflicting software
sudo apt purge -y conflicting-package

# Clean up package manager
sudo apt autoremove -y
sudo apt clean
```

5. **Disk Space:**
```bash
# Check disk space
df -h

# Clean up disk space
sudo apt autoremove -y
sudo apt clean
rm -rf /tmp/tmp.* 2>/dev/null || true
```

### Path Exports Not Working

**Symptoms:**
- Software is installed but not available in the PATH
- Commands not found after installation

**Possible Causes:**
1. Path exports not added to shell configuration
2. Shell not reloaded after installation
3. Incorrect path in exports

**Diagnostic Steps:**
1. Check if path exports were added to `.bash_aliases`:
```bash
cat ~/.bash_aliases | grep PATH
```

2. Check the current PATH:
```bash
echo $PATH
```

**Solutions:**

1. **Manually Add Path Exports:**
```bash
# Add path exports to .bash_aliases
echo 'export PATH="/opt/sdks/bin:$PATH"' >> ~/.bash_aliases

# Source the file
source ~/.bash_aliases
```

2. **Reload Shell:**
```bash
# Source the bash_aliases file
source ~/.bash_aliases

# Or start a new shell
bash
```

3. **Fix Incorrect Paths:**
```bash
# Edit .bash_aliases to fix paths
nano ~/.bash_aliases

# Source the file
source ~/.bash_aliases
```

## Command Execution Issues

### Commands Not Found

**Symptoms:**
- "Command not found" errors
- Commands not executing correctly

**Possible Causes:**
1. Software not installed
2. Command not in PATH
3. Command module not loaded
4. Typo in command name

**Diagnostic Steps:**
1. Check if the software is installed:
```bash
./devsetup.sh --status
```

2. Check if the command exists in the module:
```bash
cat .dev/modules/commands/module-name.json | grep command-name
```

**Solutions:**

1. **Install Missing Software:**
```bash
./devsetup.sh --install software-name
```

2. **Fix PATH Issues:**
```bash
# Add software bin directory to PATH
echo 'export PATH="/path/to/bin:$PATH"' >> ~/.bash_aliases
source ~/.bash_aliases
```

3. **Load Command Module:**
```bash
# Ensure the command module is loaded
./devsetup.sh --load-module module-name
```

4. **Check Command Syntax:**
```bash
# List available commands
./devsetup.sh --list-commands

# Use the correct command syntax
./devsetup.sh --command "module-name:command-name"
```

### Command Execution Fails

**Symptoms:**
- Error messages during command execution
- Command exits with non-zero status
- Unexpected command behavior

**Possible Causes:**
1. Missing command dependencies
2. Insufficient permissions
3. Invalid command parameters
4. Environment issues

**Diagnostic Steps:**
1. Check the log file for error messages:
```bash
cat $(ls -t /tmp/devsetup_*.log | head -1)
```

2. Run the command with verbose output:
```bash
./devsetup.sh --command "module:command" --verbose
```

3. Try a dry run to see what would be executed:
```bash
./devsetup.sh --command "module:command" --dry-run
```

**Solutions:**

1. **Install Dependencies:**
```bash
# Install command dependencies
./devsetup.sh --install dependency1 dependency2
```

2. **Fix Permissions:**
```bash
# Ensure you have sudo access
sudo -v

# Fix file permissions
chmod +x /path/to/script.sh
```

3. **Fix Command Parameters:**
```bash
# Use correct parameter syntax
./devsetup.sh --command "module:command" --param NAME=value
```

4. **Fix Environment Issues:**
```bash
# Set required environment variables
export VARIABLE_NAME=value

# Run the command with environment variables
./devsetup.sh --command "module:command" --env "VARIABLE_NAME=value"
```

## Workflow Issues

### Workflow Not Found

**Symptoms:**
- "Workflow not found" errors
- Workflow not executing correctly

**Possible Causes:**
1. Workflow directory not found
2. Typo in workflow name
3. Workflow files not properly formatted

**Diagnostic Steps:**
1. Check if the workflow directory exists:
```bash
ls -la .dev/workflows/
```

2. Check workflow files:
```bash
ls -la .dev/workflows/workflow-name/
```

**Solutions:**

1. **Create Missing Workflow:**
```bash
# Create workflow directory
mkdir -p .dev/workflows/workflow-name

# Create workflow files
touch .dev/workflows/workflow-name/00-prepare.json
touch .dev/workflows/workflow-name/01-software.json
touch .dev/workflows/workflow-name/02-cleanup.json
```

2. **Fix Workflow Name:**
```bash
# Use the correct workflow name
./devsetup.sh --workflow correct-workflow-name --install
```

3. **Fix Workflow Files:**
```bash
# Validate workflow files
./devsetup.sh --validate-workflow workflow-name
```

### Workflow Execution Fails

**Symptoms:**
- Error messages during workflow execution
- Workflow exits with non-zero status
- Some steps in the workflow fail

**Possible Causes:**
1. Missing dependencies
2. Invalid workflow sequence
3. Command failures within the workflow
4. Environment issues

**Diagnostic Steps:**
1. Check the log file for error messages:
```bash
cat $(ls -t /tmp/devsetup_*.log | head -1)
```

2. Run the workflow with verbose output:
```bash
./devsetup.sh --workflow workflow-name --install --verbose
```

3. Try a dry run to see what would be executed:
```bash
./devsetup.sh --workflow workflow-name --install --dry-run
```

**Solutions:**

1. **Install Dependencies:**
```bash
# Install workflow dependencies
./devsetup.sh --install dependency1 dependency2
```

2. **Fix Workflow Sequence:**
```bash
# Edit workflow files to fix sequence
nano .dev/workflows/workflow-name/01-software.json
```

3. **Fix Command Failures:**
```bash
# Run specific commands manually to debug
./devsetup.sh --command "module:command" --verbose
```

4. **Fix Environment Issues:**
```bash
# Set required environment variables
export VARIABLE_NAME=value

# Run the workflow with environment variables
./devsetup.sh --workflow workflow-name --install --env "VARIABLE_NAME=value"
```

## Remote Execution Issues

### SSH Connection Fails

**Symptoms:**
- "Connection refused" errors
- SSH authentication failures
- Timeout during connection attempts

**Possible Causes:**
1. SSH service not running on remote node
2. Incorrect SSH credentials
3. Firewall blocking SSH
4. Network connectivity issues
5. Incorrect host or port

**Diagnostic Steps:**
1. Try connecting manually using SSH:
```bash
ssh -i ~/.ssh/id_rsa user@hostname
```

2. Check SSH service on the remote node:
```bash
systemctl status sshd
```

3. Check firewall status:
```bash
sudo ufw status
```

**Solutions:**

1. **Start SSH Service:**
```bash
# On the remote node
sudo systemctl start sshd
sudo systemctl enable sshd
```

2. **Fix SSH Credentials:**
```bash
# Generate a new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copy the key to the remote node
ssh-copy-id -i ~/.ssh/id_rsa.pub user@hostname

# Update the remote node configuration
nano .dev/config/remote-nodes.json
```

3. **Configure Firewall:**
```bash
# On the remote node
sudo ufw allow ssh
sudo ufw reload
```

4. **Fix Network Issues:**
```bash
# Check network connectivity
ping -c 4 hostname

# Update /etc/hosts if needed
sudo nano /etc/hosts
```

5. **Fix Host or Port:**
```bash
# Update the remote node configuration
nano .dev/config/remote-nodes.json
```

### Sudo Access Issues on Remote Node

**Symptoms:**
- "sudo: no tty present and no askpass program specified" errors
- "user is not in the sudoers file" errors
- Password prompts during remote execution

**Possible Causes:**
1. User doesn't have sudo access
2. Passwordless sudo not configured
3. SSH key not configured for sudo

**Diagnostic Steps:**
1. Check sudo access on the remote node:
```bash
ssh user@hostname "sudo -l"
```

2. Check sudoers configuration:
```bash
ssh user@hostname "sudo cat /etc/sudoers.d/username"
```

**Solutions:**

1. **Grant Sudo Access:**
```bash
# On the remote node
echo "username ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/username
sudo chmod 440 /etc/sudoers.d/username
```

2. **Configure Passwordless Sudo:**
```bash
# On the remote node
echo "username ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/username
sudo chmod 440 /etc/sudoers.d/username
```

3. **Configure SSH Key for Sudo:**
```bash
# On the remote node
echo 'Defaults:username !requiretty' | sudo tee -a /etc/sudoers.d/username
```

### Remote Command Execution Fails

**Symptoms:**
- Error messages during remote command execution
- Command exits with non-zero status
- Unexpected command behavior on remote node

**Possible Causes:**
1. Missing dependencies on remote node
2. Path issues on remote node
3. Environment differences between local and remote
4. File permission issues

**Diagnostic Steps:**
1. Check the log file for error messages:
```bash
cat $(ls -t /tmp/devsetup_*.log | head -1)
```

2. Run the command with verbose output:
```bash
./devsetup.sh --command "module:command" --remote node-name --verbose
```

3. Try executing the command manually on the remote node:
```bash
ssh user@hostname "command"
```

**Solutions:**

1. **Install Dependencies:**
```bash
# Install dependencies on the remote node
./devsetup.sh --command "system:install-dependencies" --remote node-name
```

2. **Fix Path Issues:**
```bash
# Set PATH on the remote node
ssh user@hostname "echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc"
```

3. **Fix Environment Differences:**
```bash
# Run the command with specific environment variables
./devsetup.sh --command "module:command" --remote node-name --env "VARIABLE_NAME=value"
```

4. **Fix File Permissions:**
```bash
# Fix permissions on the remote node
ssh user@hostname "chmod +x /path/to/script.sh"
```

## Module Issues

### Module Not Found

**Symptoms:**
- "Module not found" errors
- Module not loading correctly

**Possible Causes:**
1. Module file not found
2. Typo in module name
3. Module file not properly formatted

**Diagnostic Steps:**
1. Check if the module file exists:
```bash
ls -la .dev/modules/software/
ls -la .dev/modules/commands/
```

2. Check module file content:
```bash
cat .dev/modules/software/module-name.json
```

**Solutions:**

1. **Create Missing Module:**
```bash
# Create module file
touch .dev/modules/software/module-name.json

# Add module content
nano .dev/modules/software/module-name.json
```

2. **Fix Module Name:**
```bash
# Use the correct module name
./devsetup.sh --install correct-module-name
```

3. **Fix Module Format:**
```bash
# Validate module file
./devsetup.sh --validate-module module-name
```

### Module Validation Fails

**Symptoms:**
- "Invalid module" errors
- Module validation failures

**Possible Causes:**
1. Missing required fields
2. Invalid JSON format
3. Incorrect module type
4. Invalid field values

**Diagnostic Steps:**
1. Check module file content:
```bash
cat .dev/modules/software/module-name.json
```

2. Validate the module:
```bash
./devsetup.sh --validate-module module-name
```

3. Check JSON syntax:
```bash
jq . .dev/modules/software/module-name.json
```

**Solutions:**

1. **Add Missing Fields:**
```bash
# Edit module file to add required fields
nano .dev/modules/software/module-name.json
```

2. **Fix JSON Format:**
```bash
# Use a JSON validator
jq . .dev/modules/software/module-name.json > .dev/modules/software/module-name.json.fixed
mv .dev/modules/software/module-name.json.fixed .dev/modules/software/module-name.json
```

3. **Fix Module Type:**
```bash
# Set the correct module type
nano .dev/modules/software/module-name.json
```

4. **Fix Field Values:**
```bash
# Edit module file to fix field values
nano .dev/modules/software/module-name.json
```

## Script Issues

### Script Not Executable

**Symptoms:**
- "Permission denied" errors
- Script not executing

**Possible Causes:**
1. Script file not executable
2. Script file not found
3. Incorrect script path

**Diagnostic Steps:**
1. Check script permissions:
```bash
ls -la devsetup.sh
```

2. Check script location:
```bash
pwd
```

**Solutions:**

1. **Make Script Executable:**
```bash
chmod +x devsetup.sh
```

2. **Fix Script Location:**
```bash
# Move to the correct directory
cd /path/to/devsetup
```

3. **Use Absolute Path:**
```bash
/path/to/devsetup/devsetup.sh --install
```

### Script Crashes

**Symptoms:**
- Script exits unexpectedly
- Error messages like "Segmentation fault" or "Bus error"
- Script hangs indefinitely

**Possible Causes:**
1. Bash version incompatibility
2. Memory issues
3. Infinite loops
4. Signal interrupts

**Diagnostic Steps:**
1. Check bash version:
```bash
bash --version
```

2. Run the script with debug output:
```bash
bash -x devsetup.sh --install
```

3. Check system resources:
```bash
free -m
df -h
```

**Solutions:**

1. **Update Bash:**
```bash
sudo apt update
sudo apt install -y bash
```

2. **Fix Memory Issues:**
```bash
# Free up memory
sudo sync && sudo echo 3 > /proc/sys/vm/drop_caches
```

3. **Fix Script Issues:**
```bash
# Edit the script to fix issues
nano devsetup.sh
```

4. **Handle Signals:**
```bash
# Run the script with nohup to ignore hangup signals
nohup ./devsetup.sh --install &
```

## Common Error Messages

### "Command not found"

**Possible Causes:**
1. Software not installed
2. Command not in PATH
3. Typo in command name

**Solutions:**
```bash
# Install the software
./devsetup.sh --install software-name

# Add to PATH
echo 'export PATH="/path/to/bin:$PATH"' >> ~/.bash_aliases
source ~/.bash_aliases

# Check command spelling
./devsetup.sh --list-commands
```

### "Permission denied"

**Possible Causes:**
1. Insufficient permissions
2. File not executable
3. Disk mounted with noexec option

**Solutions:**
```bash
# Change file permissions
chmod +x filename

# Run with sudo
sudo ./devsetup.sh --install

# Check mount options
mount | grep noexec
```

### "No such file or directory"

**Possible Causes:**
1. File or directory doesn't exist
2. Incorrect path
3. Typo in filename

**Solutions:**
```bash
# Create missing file or directory
mkdir -p /path/to/directory
touch /path/to/file

# Check current directory
pwd

# Use correct path
./devsetup.sh --install --path /correct/path
```

### "Invalid option"

**Possible Causes:**
1. Incorrect command line option
2. Option not supported in current version
3. Typo in option name

**Solutions:**
```bash
# Check available options
./devsetup.sh --help

# Update DevSetup
git pull
chmod +x devsetup.sh

# Use correct option syntax
./devsetup.sh --install --workflow workflow-name
```

### "Connection refused"

**Possible Causes:**
1. Service not running
2. Firewall blocking connection
3. Incorrect host or port

**Solutions:**
```bash
# Start the service
sudo systemctl start service-name

# Configure firewall
sudo ufw allow port/tcp

# Check host and port
ping hostname
telnet hostname port
```

## Getting Help

If you're still experiencing issues after trying the solutions in this guide, you can get help from the following resources:

1. **Check the Documentation:**
   - Read the [Getting Started Guide](getting-started.md)
   - Check the [Command Line Interface Guide](cli.md)
   - Review the [Advanced Usage Guide](advanced-usage.md)

2. **Check the Logs:**
   - DevSetup logs are stored in `/tmp/devsetup_*.log`
   - Check the most recent log file:
   ```bash
   cat $(ls -t /tmp/devsetup_*.log | head -1)
   ```

3. **Get System Information:**
   - Collect system information for troubleshooting:
   ```bash
   ./devsetup.sh --system-info > system-info.txt
   ```

4. **Contact Support:**
   - Submit an issue on GitHub
   - Include the system information file
   - Describe the issue in detail
   - Include steps to reproduce the issue
   - Attach relevant log files