# Modular Development Environment Setup System

A flexible, modular system for setting up development environments across multiple machines.

## Documentation

Comprehensive documentation is available in the `.dev/docs/` directory:

- [Main Documentation](.dev/docs/README.md) - Overview and links to all guides
- [Getting Started](.dev/docs/getting-started.md) - Step-by-step guide for new users
- [Command Line Interface](.dev/docs/cli.md) - Detailed command line reference
- [Workflows](.dev/docs/workflows.md) - Guide to using and creating workflows
- [Software Modules](.dev/docs/software-modules.md) - Guide to software modules
- [Command Modules](.dev/docs/command-modules.md) - Guide to command modules
- [Remote Execution](.dev/docs/remote-execution.md) - Guide to remote execution
- [Advanced Usage](.dev/docs/advanced-usage.md) - Advanced features and techniques
- [Troubleshooting](.dev/docs/troubleshooting.md) - Solutions to common issues
- [Contributing](.dev/docs/contributing.md) - Guide for contributors

## Features

- **Modular Design**: Each software package is defined in its own module file
- **Workflow Support**: Create custom installation workflows for different development scenarios
- **Command System**: Define and execute custom commands
- **Remote Execution**: Deploy and run on remote machines
- **Dry Run Mode**: Preview changes without making actual modifications
- **Extensible**: Easy to add new software modules and commands

## Directory Structure

```
.
├── devsetup.sh                 # Main script
├── .dev/                       # Development setup files
│   ├── lib/                    # Library files
│   │   ├── core.sh             # Core functions
│   │   ├── module.sh           # Module handling functions
│   │   ├── command.sh          # Command handling functions
│   │   ├── remote.sh           # Remote execution functions
│   │   └── utils.sh            # Utility functions
│   ├── config/                 # Configuration files
│   │   ├── vscode_extensions.txt  # VSCode extensions list
│   │   └── remote-nodes.json   # Remote nodes configuration
│   ├── modules/                # Module definitions
│   │   ├── software/           # Software modules
│   │   │   ├── vscode.json     # VSCode module
│   │   │   ├── nodejs.json     # Node.js module
│   │   │   └── ...             # Other software modules
│   │   └── commands/           # Command modules
│   │       └── system-cleanup.json # System cleanup commands
│   └── workflows/              # Workflow definitions
│       ├── default/            # Default workflow
│       │   ├── 00-prepare.json # Preparation steps
│       │   ├── 01-software.json # Software installation
│       │   └── 02-cleanup.json # Cleanup steps
│       ├── development/        # Full development environment workflow
│       │   ├── 00-prepare.json # Preparation steps
│       │   ├── 01-software.json # Software installation
│       │   └── 02-cleanup.json # Cleanup steps
│       ├── web-dev/            # Web development workflow
│       │   ├── 00-prepare.json # Preparation steps
│       │   ├── 01-software.json # Software installation
│       │   └── 02-cleanup.json # Cleanup steps
│       └── mobile-dev/         # Mobile development workflow
│           ├── 00-prepare.json # Preparation steps
│           ├── 01-software.json # Software installation
│           └── 02-cleanup.json # Cleanup steps
```

## Usage

### Basic Usage

```bash
# Install software using the default workflow
./devsetup.sh --install

# Install specific software
./devsetup.sh --install vscode nodejs

# Uninstall software
./devsetup.sh --uninstall vscode

# Use a specific workflow
./devsetup.sh --install --workflow development

# Dry run (no changes)
./devsetup.sh --install --dry-run

# Verbose output
./devsetup.sh --install --verbose
```

### Specialized Workflows

The system includes several specialized workflows for different development scenarios:

#### Full Development Environment

```bash
# Install complete development environment
./devsetup.sh --install --workflow development
```

This workflow installs all development tools including:
- VSCode and extensions
- Git tools (GitKraken)
- Web browsers (Chrome, Edge)
- Programming languages (Node.js, Java, Go, .NET)
- Mobile development (Flutter, Android SDK, Android Studio)

#### Web Development Environment

```bash
# Install web development environment
./devsetup.sh --install --workflow web-dev
```

This workflow installs tools focused on web development:
- VSCode and extensions
- Git tools (GitKraken)
- Web browsers (Chrome, Edge)
- Node.js and npm
- Web development tools (Angular, React, Vue, etc.)
- MongoDB

#### Mobile Development Environment

```bash
# Install mobile development environment
./devsetup.sh --install --workflow mobile-dev
```

This workflow installs tools focused on mobile development:
- VSCode and extensions
- Git tools (GitKraken)
- Chrome browser
- Java Development Kit
- Node.js
- Flutter SDK
- Android SDK
- Android Studio
- Mobile development tools (React Native, Ionic, etc.)

### Remote Execution

```bash
# Deploy and install on a remote node
./devsetup.sh --install --remote dev-laptop

# Execute a command on a remote node
./devsetup.sh --command "apt update && apt upgrade -y" --remote team-server

# Execute in parallel on a node group
./devsetup.sh --install --remote servers --parallel
```

### Command Execution

```bash
# Execute a command
./devsetup.sh --command "system-cleanup:full-cleanup"

# Execute a command with parameters
./devsetup.sh --command "vscode:update"
```

## Module Definition

Software modules are defined in JSON files with the following structure:

```json
{
  "type": "software",
  "id": "vscode",
  "name": "Visual Studio Code",
  "description": "Code editor for developers",
  "check_command": "code --version",
  "version_regex": "^([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg",
    "sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg",
    "sudo sh -c 'echo \"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list'",
    "rm -f packages.microsoft.gpg",
    "sudo apt update",
    "sudo apt install -y code"
  ],
  "uninstall_commands": [
    "sudo apt purge -y code",
    "sudo rm -f /etc/apt/sources.list.d/vscode.list",
    "sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg",
    "sudo apt update"
  ],
  "dependencies": [
    "wget",
    "gpg",
    "apt-transport-https"
  ],
  "path_exports": [],
  "commands": {
    "update": {
      "description": "Update VSCode to the latest version",
      "execute": [
        "sudo apt update",
        "sudo apt install --only-upgrade code"
      ]
    }
  }
}
```

## Command Module Definition

Command modules define reusable commands:

```json
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
    "full-cleanup": {
      "description": "Perform a full system cleanup",
      "execute": [
        "@clean-apt",
        "@clean-docker"
      ]
    }
  }
}
```

## Workflow Definition

Workflows define the sequence of operations:

```json
{
  "type": "workflow",
  "id": "software-installation",
  "name": "Software Installation",
  "description": "Install all software packages",
  "modules": [
    "vscode",
    "nodejs"
  ],
  "commands": {
    "pre-install": {
      "description": "Pre-installation setup",
      "execute": [
        "echo 'Starting software installation...'"
      ]
    }
  },
  "sequence": [
    "@pre-install",
    "vscode:install",
    "nodejs:install",
    "@post-install"
  ]
}
```

## Remote Nodes Configuration

Remote nodes are defined in a JSON file:

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
    }
  ],
  "groups": {
    "development": ["dev-laptop"],
    "servers": ["team-server"],
    "all": ["dev-laptop", "team-server"]
  }
}
```

## License

MIT