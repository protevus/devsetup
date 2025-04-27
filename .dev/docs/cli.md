# Command Line Interface

This guide provides detailed information about the DevSetup command line interface, including all available options and examples of how to use them.

## Overview

The DevSetup command line interface is designed to be intuitive and flexible, allowing you to perform a wide range of operations with a single command.

## Basic Syntax

```
./devsetup.sh [OPTIONS] [TARGETS...]
```

Where:
- `[OPTIONS]` are the command line options described below
- `[TARGETS...]` are the software packages to install or uninstall (optional)

## Available Options

### Action Options

| Option | Description |
|--------|-------------|
| `--install`, `-i` | Install specified targets or all if none specified |
| `--uninstall`, `-u` | Uninstall specified targets or all if none specified |
| `--command`, `-c COMMAND` | Execute a specific command |
| `--status`, `-s` | Show status of installed software |

### Workflow Options

| Option | Description |
|--------|-------------|
| `--workflow`, `-w WORKFLOW` | Specify workflow to use (default: default) |

### Remote Execution Options

| Option | Description |
|--------|-------------|
| `--remote`, `-r NODE` | Execute on remote node(s) |
| `--parallel`, `-p` | Execute on multiple remote nodes in parallel |

### Path Options

| Option | Description |
|--------|-------------|
| `--path PATH` | Specify custom installation path for SDKs (default: /opt/sdks) |

### Output Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be done without making changes |
| `--verbose`, `-v` | Display verbose output |

### Help Options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Display help message |
| `--version` | Display script version |

## Examples

### Basic Installation

```bash
# Install all software using the default workflow
./devsetup.sh --install

# Install specific software
./devsetup.sh --install vscode nodejs

# Install using a specific workflow
./devsetup.sh --install --workflow web-dev

# Install with verbose output
./devsetup.sh --install --verbose

# Install with dry run (no changes)
./devsetup.sh --install --dry-run

# Install to a custom path
./devsetup.sh --install --path /usr/local/sdks
```

### Uninstallation

```bash
# Uninstall specific software
./devsetup.sh --uninstall vscode

# Uninstall all software
./devsetup.sh --uninstall

# Uninstall with dry run (no changes)
./devsetup.sh --uninstall --dry-run
```

### Command Execution

```bash
# Execute a specific command
./devsetup.sh --command "system-cleanup:clean-apt"

# Execute a command with parameters
./devsetup.sh --command "vscode:update"

# Execute a command with dry run
./devsetup.sh --command "system-cleanup:full-cleanup" --dry-run
```

### Remote Execution

```bash
# Install on a remote node
./devsetup.sh --install --remote dev-laptop

# Execute a command on a remote node
./devsetup.sh --command "apt update && apt upgrade -y" --remote team-server

# Install on multiple nodes in parallel
./devsetup.sh --install --remote servers --parallel

# Install with dry run on a remote node
./devsetup.sh --install --remote dev-laptop --dry-run
```

### Status Check

```bash
# Check status of all installed software
./devsetup.sh --status

# Check status of specific software
./devsetup.sh --status vscode nodejs

# Check status on a remote node
./devsetup.sh --status --remote dev-laptop
```

## Option Combinations

You can combine multiple options to perform complex operations:

```bash
# Install specific software using a specific workflow with verbose output
./devsetup.sh --install vscode nodejs --workflow web-dev --verbose

# Uninstall specific software on a remote node with dry run
./devsetup.sh --uninstall vscode --remote dev-laptop --dry-run

# Execute a command on multiple remote nodes in parallel with verbose output
./devsetup.sh --command "system-cleanup:full-cleanup" --remote servers --parallel --verbose
```

## Environment Variables

DevSetup also supports environment variables to configure its behavior:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEVSETUP_PATH` | Installation path for SDKs | `/opt/sdks` |
| `DEVSETUP_WORKFLOW` | Default workflow to use | `default` |
| `DEVSETUP_VERBOSE` | Enable verbose output | `0` (disabled) |
| `DEVSETUP_DRY_RUN` | Enable dry run mode | `0` (disabled) |

Example:

```bash
# Set environment variables
export DEVSETUP_PATH=/usr/local/sdks
export DEVSETUP_WORKFLOW=web-dev
export DEVSETUP_VERBOSE=1

# Run DevSetup (will use the environment variables)
./devsetup.sh --install
```

## Exit Codes

DevSetup returns the following exit codes:

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Permission denied |
| 4 | Software installation failed |
| 5 | Software uninstallation failed |
| 6 | Command execution failed |
| 7 | Remote execution failed |

## Logging

DevSetup logs all operations to a log file in the `/tmp` directory. The log file name is in the format `devsetup_YYYYMMDD_HHMMSS.log`.

To view the log file:

```bash
# View the most recent log file
cat $(ls -t /tmp/devsetup_*.log | head -1)
```

## Next Steps

Now that you understand the command line interface, you can:

- Learn about [Workflows](workflows.md) to understand how to customize your setup
- Check out [Software Modules](software-modules.md) to see what software is available
- Learn about [Command Modules](command-modules.md) to execute custom operations
- Set up [Remote Execution](remote-execution.md) to configure multiple machines