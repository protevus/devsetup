# DevSetup - Comprehensive User Guide

Welcome to the DevSetup documentation! This guide will help you understand and use the modular development environment setup system effectively.

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Command Line Interface](#command-line-interface)
4. [Workflows](#workflows)
5. [Software Modules](#software-modules)
6. [Command Modules](#command-modules)
7. [Remote Execution](#remote-execution)
8. [Advanced Usage](#advanced-usage)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)

## Introduction

DevSetup is a modular development environment setup system designed to make it easy to set up and maintain consistent development environments across multiple machines. It provides a flexible, extensible framework for installing software, configuring tools, and executing commands.

### Key Features

- **Modular Design**: Each software package is defined in its own configuration file
- **Workflow Support**: Custom workflows for different development scenarios
- **Remote Execution**: Set up multiple machines via SSH
- **Command System**: Execute custom operations
- **Dry Run Mode**: Preview changes without making actual modifications
- **Extensibility**: Easily add new modules and commands

## Getting Started

To get started with DevSetup, you need to:

1. Clone the repository or download the script
2. Make the script executable
3. Run the script with the desired options

```bash
# Clone the repository
git clone https://github.com/example/devsetup.git

# Make the script executable
chmod +x devsetup.sh

# Run the script
./devsetup.sh --install
```

For more detailed information, see [Getting Started Guide](getting-started.md).

## Command Line Interface

DevSetup provides a comprehensive command line interface with various options:

```
Usage: ./devsetup.sh [OPTIONS] [TARGETS...]

Options:
  --workflow, -w WORKFLOW   Specify workflow to use (default: default)
  --install, -i             Install specified targets or all if none specified
  --uninstall, -u           Uninstall specified targets or all if none specified
  --command, -c COMMAND     Execute a specific command
  --remote, -r NODE         Execute on remote node(s)
  --parallel, -p            Execute on multiple remote nodes in parallel
  --path PATH               Specify custom installation path for SDKs (default: /opt/sdks)
  --dry-run                 Show what would be done without making changes
  --verbose, -v             Display verbose output
  --help, -h                Display this help message
  --version                 Display script version
```

For more detailed information, see [Command Line Interface Guide](cli.md).

## Workflows

Workflows define sequences of operations to set up specific development environments. DevSetup includes several pre-defined workflows:

- **default**: Basic development environment
- **development**: Full development environment with all tools
- **web-dev**: Web development environment
- **mobile-dev**: Mobile development environment

To use a specific workflow:

```bash
./devsetup.sh --install --workflow web-dev
```

For more detailed information, see [Workflows Guide](workflows.md).

## Software Modules

Software modules define how to install, uninstall, and configure specific software packages. Each module is defined in its own JSON file with a consistent structure.

For more detailed information, see [Software Modules Guide](software-modules.md).

## Command Modules

Command modules define reusable commands that can be executed by the system. These commands can be used to perform various operations, such as cleaning up the system, configuring software, or running tests.

For more detailed information, see [Command Modules Guide](command-modules.md).

## Remote Execution

DevSetup supports executing operations on remote machines via SSH. This allows you to set up multiple machines with the same configuration.

For more detailed information, see [Remote Execution Guide](remote-execution.md).

## Advanced Usage

DevSetup provides several advanced features for power users:

- **Custom Modules**: Create your own software and command modules
- **Custom Workflows**: Define your own workflows
- **Integration with CI/CD**: Use DevSetup in CI/CD pipelines
- **Scripting**: Use DevSetup in scripts

For more detailed information, see [Advanced Usage Guide](advanced-usage.md).

## Troubleshooting

If you encounter issues while using DevSetup, check the [Troubleshooting Guide](troubleshooting.md) for solutions to common problems.

## Contributing

We welcome contributions to DevSetup! If you'd like to contribute, please see the [Contributing Guide](contributing.md).