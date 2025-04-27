# Workflows Guide

This guide provides detailed information about DevSetup workflows, including how they work, what pre-defined workflows are available, and how to create your own custom workflows.

## What are Workflows?

Workflows in DevSetup are sequences of operations that define how to set up a specific development environment. They combine software installations and commands in a specific order to create a consistent environment.

Workflows are defined in JSON files and are located in the `.dev/workflows/` directory, with each workflow having its own subdirectory.

## Workflow Structure

A typical workflow consists of:

1. **Preparation steps**: Commands to prepare the system for installation
2. **Software installation**: Installation of specific software packages
3. **Cleanup steps**: Commands to clean up after installation

Each of these steps is defined in a separate JSON file within the workflow directory, typically named with a numeric prefix to indicate the order (e.g., `00-prepare.json`, `01-software.json`, `02-cleanup.json`).

## Pre-defined Workflows

DevSetup includes several pre-defined workflows for different development scenarios:

### Default Workflow

Located in `.dev/workflows/default/`, this workflow provides a basic development environment with essential tools.

Files:
- `00-prepare.json`: System preparation
- `01-software.json`: Basic software installation
- `02-cleanup.json`: System cleanup

To use:
```bash
./devsetup.sh --install
# or
./devsetup.sh --install --workflow default
```

### Full Development Environment

Located in `.dev/workflows/development/`, this workflow installs a comprehensive set of development tools.

Files:
- `00-prepare.json`: System preparation
- `01-software.json`: Comprehensive software installation
- `02-cleanup.json`: System cleanup

Software included:
- VSCode and extensions
- Git tools (GitKraken)
- Web browsers (Chrome, Edge)
- Programming languages (Node.js, Java, Go, .NET)
- Mobile development (Flutter, Android SDK, Android Studio)

To use:
```bash
./devsetup.sh --install --workflow development
```

### Web Development Environment

Located in `.dev/workflows/web-dev/`, this workflow focuses on tools for web development.

Files:
- `00-prepare.json`: System preparation
- `01-software.json`: Web development software installation
- `02-cleanup.json`: System cleanup

Software included:
- VSCode and extensions
- Git tools (GitKraken)
- Web browsers (Chrome, Edge)
- Node.js and npm
- Web development tools (Angular, React, Vue, etc.)
- MongoDB

To use:
```bash
./devsetup.sh --install --workflow web-dev
```

### Mobile Development Environment

Located in `.dev/workflows/mobile-dev/`, this workflow focuses on tools for mobile development.

Files:
- `00-prepare.json`: System preparation
- `01-software.json`: Mobile development software installation
- `02-cleanup.json`: System cleanup

Software included:
- VSCode and extensions
- Git tools (GitKraken)
- Chrome browser
- Java Development Kit
- Node.js
- Flutter SDK
- Android SDK
- Android Studio
- Mobile development tools (React Native, Ionic, etc.)

To use:
```bash
./devsetup.sh --install --workflow mobile-dev
```

## Workflow File Format

Each workflow file is a JSON file with the following structure:

```json
{
  "type": "workflow",
  "id": "example-workflow",
  "name": "Example Workflow",
  "description": "Description of the workflow",
  "modules": [
    "module1",
    "module2"
  ],
  "commands": {
    "pre-install": {
      "description": "Pre-installation setup",
      "execute": [
        "command 1",
        "command 2"
      ]
    },
    "post-install": {
      "description": "Post-installation setup",
      "execute": [
        "command 1",
        "command 2"
      ]
    }
  },
  "sequence": [
    "@pre-install",
    "module1:install",
    "module2:install",
    "@post-install"
  ]
}
```

Where:
- `type`: Always "workflow"
- `id`: Unique identifier for the workflow
- `name`: Human-readable name for the workflow
- `description`: Description of what the workflow does
- `modules`: List of software modules to include in the workflow
- `commands`: Custom commands defined within the workflow
- `sequence`: Order of operations to execute

In the `sequence` array:
- Items starting with `@` refer to commands defined in the `commands` section
- Items containing `:` refer to commands from modules (e.g., `module1:install`)

## Creating Custom Workflows

You can create your own custom workflows to suit your specific needs:

1. Create a new directory in `.dev/workflows/` for your workflow (e.g., `.dev/workflows/my-workflow/`)
2. Create workflow files in the directory (e.g., `00-prepare.json`, `01-software.json`, `02-cleanup.json`)
3. Define the workflow structure in each file

### Example: Creating a Python Development Workflow

1. Create the workflow directory:
```bash
mkdir -p .dev/workflows/python-dev
```

2. Create the preparation file (`00-prepare.json`):
```json
{
  "type": "workflow",
  "id": "prepare",
  "name": "Prepare System",
  "description": "Prepare the system for Python development environment setup",
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
        "sudo apt install -y curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release software-properties-common"
      ]
    },
    "create-directories": {
      "description": "Create necessary directories",
      "execute": [
        "mkdir -p {INSTALL_PATH}",
        "sudo chown -R $(whoami):$(whoami) {INSTALL_PATH}",
        "mkdir -p ~/python-projects"
      ]
    }
  },
  "sequence": [
    "@update-system",
    "@install-dependencies",
    "@create-directories"
  ]
}
```

3. Create the software installation file (`01-software.json`):
```json
{
  "type": "workflow",
  "id": "software-installation",
  "name": "Python Development Software Installation",
  "description": "Install software packages for Python development",
  "modules": [
    "vscode",
    "gitkraken",
    "chrome"
  ],
  "commands": {
    "pre-install": {
      "description": "Pre-installation setup",
      "execute": [
        "echo 'Starting Python development software installation...'"
      ]
    },
    "install-python": {
      "description": "Install Python and related tools",
      "execute": [
        "sudo apt install -y python3 python3-pip python3-venv",
        "sudo pip3 install pipenv virtualenv poetry",
        "sudo pip3 install jupyter numpy pandas matplotlib scikit-learn"
      ]
    },
    "post-install": {
      "description": "Post-installation configuration",
      "execute": [
        "echo 'Python development software installation completed'",
        "echo 'Configuring installed software...'"
      ]
    }
  },
  "sequence": [
    "@pre-install",
    "vscode:install",
    "gitkraken:install",
    "chrome:install",
    "@install-python",
    "vscode-extensions:install",
    "@post-install"
  ]
}
```

4. Create the cleanup file (`02-cleanup.json`):
```json
{
  "type": "workflow",
  "id": "cleanup",
  "name": "System Cleanup",
  "description": "Clean up after Python development environment installation",
  "commands": {
    "pre-cleanup": {
      "description": "Pre-cleanup tasks",
      "execute": [
        "echo 'Starting system cleanup...'"
      ]
    },
    "clean-apt": {
      "description": "Clean APT cache",
      "execute": [
        "sudo apt autoremove -y",
        "sudo apt clean"
      ]
    },
    "clean-pip": {
      "description": "Clean pip cache",
      "execute": [
        "pip cache purge"
      ]
    },
    "create-sample-project": {
      "description": "Create a sample Python project",
      "execute": [
        "mkdir -p ~/python-projects/sample-app",
        "cd ~/python-projects/sample-app && python3 -m venv venv",
        "cd ~/python-projects/sample-app && echo 'def main():\\n    print(\"Hello, Python!\")\\n\\nif __name__ == \"__main__\":\\n    main()' > app.py",
        "cd ~/python-projects/sample-app && echo '# Sample Python Application\\n\\nThis is a sample Python application created by the development environment setup script.\\n\\n## Running the application\\n\\n```bash\\nsource venv/bin/activate\\npython app.py\\n```' > README.md",
        "echo 'Sample Python application created at ~/python-projects/sample-app'"
      ]
    },
    "post-cleanup": {
      "description": "Post-cleanup tasks",
      "execute": [
        "echo 'System cleanup completed'",
        "echo 'Your Python development environment is ready!'",
        "echo 'To run the sample application, use: cd ~/python-projects/sample-app && source venv/bin/activate && python app.py'"
      ]
    }
  },
  "sequence": [
    "@pre-cleanup",
    "@clean-apt",
    "@clean-pip",
    "system-cleanup:clean-tmp",
    "@create-sample-project",
    "@post-cleanup"
  ]
}
```

5. Use your custom workflow:
```bash
./devsetup.sh --install --workflow python-dev
```

## Workflow Inheritance and Composition

You can create workflows that inherit from or compose other workflows:

### Inheritance

To create a workflow that inherits from another workflow, include the parent workflow's modules and extend them:

```json
{
  "type": "workflow",
  "id": "extended-web-dev",
  "name": "Extended Web Development",
  "description": "Extended web development environment with additional tools",
  "parent": "web-dev",
  "modules": [
    "docker",
    "aws-cli"
  ],
  "commands": {
    "additional-setup": {
      "description": "Additional setup steps",
      "execute": [
        "command 1",
        "command 2"
      ]
    }
  },
  "sequence": [
    "@parent:sequence",
    "docker:install",
    "aws-cli:install",
    "@additional-setup"
  ]
}
```

### Composition

To create a workflow that composes multiple workflows, include the modules from each workflow:

```json
{
  "type": "workflow",
  "id": "full-stack",
  "name": "Full Stack Development",
  "description": "Combined web and mobile development environment",
  "includes": [
    "web-dev",
    "mobile-dev"
  ],
  "modules": [
    "docker",
    "aws-cli"
  ],
  "commands": {
    "additional-setup": {
      "description": "Additional setup steps",
      "execute": [
        "command 1",
        "command 2"
      ]
    }
  },
  "sequence": [
    "@web-dev:prepare",
    "@mobile-dev:prepare",
    "@web-dev:software-installation",
    "@mobile-dev:software-installation",
    "docker:install",
    "aws-cli:install",
    "@additional-setup",
    "@web-dev:cleanup",
    "@mobile-dev:cleanup"
  ]
}
```

## Best Practices

When creating workflows, follow these best practices:

1. **Use numeric prefixes** for workflow files to indicate order (e.g., `00-prepare.json`, `01-software.json`)
2. **Keep workflows modular** by separating preparation, installation, and cleanup steps
3. **Include clear descriptions** for each workflow and command
4. **Test workflows** with the `--dry-run` option before executing them
5. **Document workflows** with comments and README files
6. **Use consistent naming conventions** for workflows and commands
7. **Minimize dependencies** between workflows to keep them independent
8. **Handle errors gracefully** by checking command exit codes and providing fallback options

## Next Steps

Now that you understand workflows, you can:

- Learn about [Software Modules](software-modules.md) to see what software is available
- Check out [Command Modules](command-modules.md) to execute custom operations
- Explore [Advanced Usage](advanced-usage.md) for more advanced features