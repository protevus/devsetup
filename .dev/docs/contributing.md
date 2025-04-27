# Contributing Guide

Thank you for your interest in contributing to DevSetup! This guide will help you understand how to contribute to the project, including how to report bugs, suggest features, submit code changes, and more.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How to Contribute](#how-to-contribute)
   - [Reporting Bugs](#reporting-bugs)
   - [Suggesting Features](#suggesting-features)
   - [Code Contributions](#code-contributions)
4. [Development Workflow](#development-workflow)
   - [Setting Up the Development Environment](#setting-up-the-development-environment)
   - [Coding Standards](#coding-standards)
   - [Testing](#testing)
5. [Pull Request Process](#pull-request-process)
6. [Module Development](#module-development)
   - [Creating Software Modules](#creating-software-modules)
   - [Creating Command Modules](#creating-command-modules)
   - [Creating Workflows](#creating-workflows)
7. [Documentation](#documentation)
8. [Community](#community)

## Code of Conduct

We expect all contributors to follow our Code of Conduct. Please be respectful and considerate of others when participating in our community.

- Be respectful and inclusive
- Be collaborative
- Be open to feedback and ideas
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

Before you begin contributing, make sure you have:

1. A GitHub account
2. Git installed on your local machine
3. A fork of the DevSetup repository
4. A local clone of your fork

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/devsetup.git
cd devsetup
git remote add upstream https://github.com/original-owner/devsetup.git
```

## How to Contribute

### Reporting Bugs

If you find a bug in DevSetup, please report it by creating an issue on GitHub. When reporting bugs, please include:

1. A clear and descriptive title
2. A detailed description of the bug
3. Steps to reproduce the bug
4. Expected behavior
5. Actual behavior
6. Screenshots (if applicable)
7. System information:
   - Operating system and version
   - DevSetup version
   - Bash version
   - Any relevant software versions

You can generate system information using:

```bash
./devsetup.sh --system-info
```

### Suggesting Features

We welcome feature suggestions! To suggest a feature:

1. Check if the feature has already been suggested or implemented
2. Create an issue on GitHub with the "Feature Request" label
3. Clearly describe the feature and its benefits
4. Provide examples of how the feature would be used
5. If possible, outline how the feature might be implemented

### Code Contributions

To contribute code to DevSetup:

1. Ensure you have a GitHub issue describing the bug or feature you're addressing
2. Create a new branch for your changes:
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes with clear, descriptive commit messages
6. Push your branch to your fork
7. Create a pull request

## Development Workflow

### Setting Up the Development Environment

To set up a development environment for DevSetup:

1. Clone your fork of the repository:
```bash
git clone https://github.com/YOUR-USERNAME/devsetup.git
cd devsetup
```

2. Set up the development environment:
```bash
./devsetup.sh --install --workflow development
```

3. Install development tools:
```bash
./devsetup.sh --command "dev-tools:install"
```

### Coding Standards

Please follow these coding standards when contributing:

1. **Bash Style Guide**:
   - Use 2-space indentation
   - Use lowercase for variable names
   - Use uppercase for constants
   - Use snake_case for function names
   - Add comments for complex code
   - Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

2. **JSON Style Guide**:
   - Use 2-space indentation
   - Use camelCase for property names
   - Sort properties alphabetically
   - Include a `type` property for all modules
   - Include a `description` property for all modules and commands

3. **Documentation Style Guide**:
   - Use Markdown for documentation
   - Follow the existing documentation structure
   - Include examples for all features
   - Keep documentation up-to-date with code changes

### Testing

Before submitting a pull request, please test your changes:

1. **Linting**:
```bash
./devsetup.sh --command "dev-tools:lint"
```

2. **Unit Tests**:
```bash
./devsetup.sh --command "dev-tools:test-unit"
```

3. **Integration Tests**:
```bash
./devsetup.sh --command "dev-tools:test-integration"
```

4. **End-to-End Tests**:
```bash
./devsetup.sh --command "dev-tools:test-e2e"
```

5. **Manual Testing**:
   - Test your changes with different workflows
   - Test with different operating systems if possible
   - Test with different software modules

## Pull Request Process

1. Ensure your code follows the coding standards
2. Ensure all tests pass
3. Update documentation as needed
4. Link the pull request to the relevant issue
5. Request a review from a maintainer
6. Address any feedback from reviewers
7. Once approved, a maintainer will merge your pull request

## Module Development

### Creating Software Modules

To create a new software module:

1. Create a new JSON file in `.dev/modules/software/`:
```bash
touch .dev/modules/software/my-software.json
```

2. Define the module structure:
```json
{
  "type": "software",
  "id": "my-software",
  "name": "My Software",
  "description": "Description of my software",
  "check_command": "command to check if installed",
  "version_regex": "regex to extract version",
  "install_commands": [
    "command 1",
    "command 2"
  ],
  "uninstall_commands": [
    "command 1",
    "command 2"
  ],
  "dependencies": [
    "dependency1",
    "dependency2"
  ],
  "path_exports": [
    "export PATH=$PATH:/path/to/bin"
  ],
  "commands": {
    "command1": {
      "description": "Description of command1",
      "execute": [
        "command 1",
        "command 2"
      ]
    }
  }
}
```

3. Test the module:
```bash
./devsetup.sh --validate-module my-software
./devsetup.sh --install my-software --dry-run
```

### Creating Command Modules

To create a new command module:

1. Create a new JSON file in `.dev/modules/commands/`:
```bash
touch .dev/modules/commands/my-commands.json
```

2. Define the module structure:
```json
{
  "type": "command",
  "id": "my-commands",
  "name": "My Commands",
  "description": "Description of my commands",
  "commands": {
    "command1": {
      "description": "Description of command1",
      "execute": [
        "command 1",
        "command 2"
      ],
      "requires": [
        "requirement1",
        "requirement2"
      ]
    },
    "command2": {
      "description": "Description of command2",
      "execute": [
        "@command1",
        "command 3"
      ]
    }
  }
}
```

3. Test the module:
```bash
./devsetup.sh --validate-module my-commands
./devsetup.sh --command "my-commands:command1" --dry-run
```

### Creating Workflows

To create a new workflow:

1. Create a new directory in `.dev/workflows/`:
```bash
mkdir -p .dev/workflows/my-workflow
```

2. Create workflow files:
```bash
touch .dev/workflows/my-workflow/00-prepare.json
touch .dev/workflows/my-workflow/01-software.json
touch .dev/workflows/my-workflow/02-cleanup.json
```

3. Define the workflow structure:

```json
// 00-prepare.json
{
  "type": "workflow",
  "id": "prepare",
  "name": "Prepare System",
  "description": "Prepare the system for installation",
  "commands": {
    "update-system": {
      "description": "Update system packages",
      "execute": [
        "sudo apt update",
        "sudo apt upgrade -y"
      ]
    },
    "install-dependencies": {
      "description": "Install common dependencies",
      "execute": [
        "sudo apt install -y curl wget git"
      ]
    }
  },
  "sequence": [
    "@update-system",
    "@install-dependencies"
  ]
}
```

```json
// 01-software.json
{
  "type": "workflow",
  "id": "software-installation",
  "name": "Software Installation",
  "description": "Install software packages",
  "modules": [
    "software1",
    "software2"
  ],
  "sequence": [
    "software1:install",
    "software2:install"
  ]
}
```

```json
// 02-cleanup.json
{
  "type": "workflow",
  "id": "cleanup",
  "name": "System Cleanup",
  "description": "Clean up after installation",
  "commands": {
    "clean-apt": {
      "description": "Clean APT cache",
      "execute": [
        "sudo apt autoremove -y",
        "sudo apt clean"
      ]
    }
  },
  "sequence": [
    "@clean-apt"
  ]
}
```

4. Test the workflow:
```bash
./devsetup.sh --validate-workflow my-workflow
./devsetup.sh --workflow my-workflow --install --dry-run
```

## Documentation

Good documentation is essential for DevSetup. When contributing, please:

1. Update documentation for any changes you make
2. Add examples for new features
3. Ensure documentation is clear and easy to understand
4. Follow the existing documentation structure

Documentation is written in Markdown and stored in the `.dev/docs/` directory.

To build the documentation:

```bash
./devsetup.sh --command "dev-tools:build-docs"
```

## Community

Join our community to get help, share ideas, and collaborate:

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For general discussions and questions
- **Slack Channel**: For real-time communication
- **Mailing List**: For announcements and newsletters

Thank you for contributing to DevSetup!