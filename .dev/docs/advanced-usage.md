# Advanced Usage Guide

This guide provides information about advanced features and techniques for using DevSetup, including customization, integration with other tools, and advanced scripting.

## Custom Modules and Workflows

### Creating Custom Software Modules

You can create custom software modules to install and configure software that isn't included in the pre-defined modules:

1. Create a new JSON file in `.dev/modules/software/` (e.g., `.dev/modules/software/my-software.json`)
2. Define the module structure following the [Software Module Format](software-modules.md)
3. Use the module in your workflows or directly with the `--install` option

Example custom software module for MongoDB:

```json
{
  "type": "software",
  "id": "mongodb",
  "name": "MongoDB",
  "description": "NoSQL database",
  "check_command": "mongod --version",
  "version_regex": "db version v([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -",
    "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list",
    "sudo apt update",
    "sudo apt install -y mongodb-org",
    "sudo systemctl enable mongod",
    "sudo systemctl start mongod"
  ],
  "uninstall_commands": [
    "sudo systemctl stop mongod",
    "sudo apt purge -y mongodb-org*",
    "sudo rm -f /etc/apt/sources.list.d/mongodb-org-6.0.list",
    "sudo apt update",
    "sudo rm -rf /var/lib/mongodb",
    "sudo rm -rf /var/log/mongodb"
  ],
  "dependencies": [
    "wget",
    "gnupg"
  ],
  "commands": {
    "start": {
      "description": "Start MongoDB service",
      "execute": [
        "sudo systemctl start mongod"
      ]
    },
    "stop": {
      "description": "Stop MongoDB service",
      "execute": [
        "sudo systemctl stop mongod"
      ]
    },
    "status": {
      "description": "Check MongoDB service status",
      "execute": [
        "sudo systemctl status mongod"
      ]
    },
    "create-user": {
      "description": "Create a MongoDB user",
      "execute": [
        "mongo admin --eval 'db.createUser({user: \"{USERNAME}\", pwd: \"{PASSWORD}\", roles: [\"root\"]})'"
      ]
    }
  }
}
```

### Creating Custom Command Modules

You can create custom command modules to define reusable commands:

1. Create a new JSON file in `.dev/modules/commands/` (e.g., `.dev/modules/commands/my-commands.json`)
2. Define the module structure following the [Command Module Format](command-modules.md)
3. Use the commands with the `--command` option

Example custom command module for database operations:

```json
{
  "type": "command",
  "id": "database-ops",
  "name": "Database Operations",
  "description": "Commands for database operations",
  "commands": {
    "backup-mysql": {
      "description": "Backup MySQL database",
      "execute": [
        "mkdir -p ~/backups/mysql",
        "mysqldump -u {USERNAME} -p{PASSWORD} {DATABASE} > ~/backups/mysql/{DATABASE}-$(date +%Y%m%d).sql",
        "echo 'MySQL database {DATABASE} backed up to ~/backups/mysql/{DATABASE}-$(date +%Y%m%d).sql'"
      ],
      "requires": ["mysql-client"]
    },
    "restore-mysql": {
      "description": "Restore MySQL database",
      "execute": [
        "mysql -u {USERNAME} -p{PASSWORD} {DATABASE} < {BACKUP_FILE}",
        "echo 'MySQL database {DATABASE} restored from {BACKUP_FILE}'"
      ],
      "requires": ["mysql-client"]
    },
    "backup-postgres": {
      "description": "Backup PostgreSQL database",
      "execute": [
        "mkdir -p ~/backups/postgres",
        "pg_dump -U {USERNAME} {DATABASE} > ~/backups/postgres/{DATABASE}-$(date +%Y%m%d).sql",
        "echo 'PostgreSQL database {DATABASE} backed up to ~/backups/postgres/{DATABASE}-$(date +%Y%m%d).sql'"
      ],
      "requires": ["postgresql-client"]
    },
    "restore-postgres": {
      "description": "Restore PostgreSQL database",
      "execute": [
        "psql -U {USERNAME} {DATABASE} < {BACKUP_FILE}",
        "echo 'PostgreSQL database {DATABASE} restored from {BACKUP_FILE}'"
      ],
      "requires": ["postgresql-client"]
    },
    "backup-mongodb": {
      "description": "Backup MongoDB database",
      "execute": [
        "mkdir -p ~/backups/mongodb",
        "mongodump --db {DATABASE} --out ~/backups/mongodb/{DATABASE}-$(date +%Y%m%d)",
        "echo 'MongoDB database {DATABASE} backed up to ~/backups/mongodb/{DATABASE}-$(date +%Y%m%d)'"
      ],
      "requires": ["mongodb"]
    },
    "restore-mongodb": {
      "description": "Restore MongoDB database",
      "execute": [
        "mongorestore --db {DATABASE} {BACKUP_DIR}",
        "echo 'MongoDB database {DATABASE} restored from {BACKUP_DIR}'"
      ],
      "requires": ["mongodb"]
    }
  }
}
```

### Creating Custom Workflows

You can create custom workflows to define sequences of operations:

1. Create a new directory in `.dev/workflows/` (e.g., `.dev/workflows/my-workflow/`)
2. Create workflow files in the directory (e.g., `00-prepare.json`, `01-software.json`, `02-cleanup.json`)
3. Define the workflow structure following the [Workflow Format](workflows.md)
4. Use the workflow with the `--workflow` option

Example custom workflow for a data science environment:

```json
// .dev/workflows/data-science/00-prepare.json
{
  "type": "workflow",
  "id": "prepare",
  "name": "Prepare System",
  "description": "Prepare the system for data science environment setup",
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
        "mkdir -p ~/data-science-projects"
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

```json
// .dev/workflows/data-science/01-software.json
{
  "type": "workflow",
  "id": "software-installation",
  "name": "Data Science Software Installation",
  "description": "Install software packages for data science",
  "modules": [
    "vscode",
    "python",
    "nodejs",
    "chrome"
  ],
  "commands": {
    "install-python-packages": {
      "description": "Install Python data science packages",
      "execute": [
        "sudo pip3 install numpy pandas matplotlib scikit-learn tensorflow keras jupyter jupyterlab"
      ]
    },
    "install-r": {
      "description": "Install R and RStudio",
      "execute": [
        "sudo apt update",
        "sudo apt install -y r-base r-base-dev",
        "wget -O rstudio.deb https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2023.06.0-421-amd64.deb",
        "sudo dpkg -i rstudio.deb",
        "sudo apt-get install -f -y",
        "rm rstudio.deb"
      ]
    },
    "install-r-packages": {
      "description": "Install R data science packages",
      "execute": [
        "sudo Rscript -e 'install.packages(c(\"tidyverse\", \"ggplot2\", \"dplyr\", \"caret\", \"randomForest\"), repos=\"https://cloud.r-project.org\")'"
      ]
    }
  },
  "sequence": [
    "vscode:install",
    "python:install",
    "nodejs:install",
    "chrome:install",
    "@install-python-packages",
    "@install-r",
    "@install-r-packages"
  ]
}
```

```json
// .dev/workflows/data-science/02-cleanup.json
{
  "type": "workflow",
  "id": "cleanup",
  "name": "System Cleanup",
  "description": "Clean up after data science environment installation",
  "commands": {
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
    "create-jupyter-config": {
      "description": "Create Jupyter configuration",
      "execute": [
        "jupyter notebook --generate-config",
        "echo 'c.NotebookApp.browser = \"google-chrome\"' >> ~/.jupyter/jupyter_notebook_config.py",
        "echo 'Jupyter configuration created'"
      ]
    },
    "create-sample-notebook": {
      "description": "Create a sample Jupyter notebook",
      "execute": [
        "mkdir -p ~/data-science-projects/sample-notebook",
        "echo '{\"cells\":[{\"cell_type\":\"markdown\",\"metadata\":{},\"source\":[\"# Sample Jupyter Notebook\\n\",\"\\n\",\"This is a sample Jupyter notebook created by the development environment setup script.\"]},{\"cell_type\":\"code\",\"execution_count\":null,\"metadata\":{},\"outputs\":[],\"source\":[\"import numpy as np\\n\",\"import pandas as pd\\n\",\"import matplotlib.pyplot as plt\\n\",\"\\n\",\"# Generate some random data\\n\",\"data = np.random.randn(100, 4)\\n\",\"df = pd.DataFrame(data, columns=[\\\"A\\\", \\\"B\\\", \\\"C\\\", \\\"D\\\"])\\n\",\"\\n\",\"# Display the first few rows\\n\",\"df.head()\"]},{\"cell_type\":\"code\",\"execution_count\":null,\"metadata\":{},\"outputs\":[],\"source\":[\"# Create a simple plot\\n\",\"plt.figure(figsize=(10, 6))\\n\",\"plt.scatter(df[\\\"A\\\"], df[\\\"B\\\"])\\n\",\"plt.title(\\\"Sample Scatter Plot\\\")\\n\",\"plt.xlabel(\\\"A\\\")\\n\",\"plt.ylabel(\\\"B\\\")\\n\",\"plt.grid(True)\\n\",\"plt.show()\"]}],\"metadata\":{\"kernelspec\":{\"display_name\":\"Python 3\",\"language\":\"python\",\"name\":\"python3\"},\"language_info\":{\"codemirror_mode\":{\"name\":\"ipython\",\"version\":3},\"file_extension\":\".py\",\"mimetype\":\"text/x-python\",\"name\":\"python\",\"nbconvert_exporter\":\"python\",\"pygments_lexer\":\"ipython3\",\"version\":\"3.8.10\"}},\"nbformat\":4,\"nbformat_minor\":5}' > ~/data-science-projects/sample-notebook/sample.ipynb",
        "echo 'Sample Jupyter notebook created at ~/data-science-projects/sample-notebook/sample.ipynb'"
      ]
    }
  },
  "sequence": [
    "@clean-apt",
    "@clean-pip",
    "@create-jupyter-config",
    "@create-sample-notebook",
    "echo 'Data science environment setup completed'"
  ]
}
```

## Integration with Other Tools

### Integration with CI/CD Pipelines

You can integrate DevSetup with CI/CD pipelines to automate environment setup:

#### GitHub Actions Example

```yaml
name: Setup Development Environment

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up DevSetup
        run: |
          chmod +x devsetup.sh
          ./devsetup.sh --install --workflow ci-workflow --dry-run

      - name: Run tests
        run: |
          ./devsetup.sh --command "test:run-all"
```

#### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                sh 'chmod +x devsetup.sh'
                sh './devsetup.sh --install --workflow jenkins-workflow'
            }
        }
        
        stage('Run Tests') {
            steps {
                sh './devsetup.sh --command "test:run-all"'
            }
        }
    }
    
    post {
        always {
            sh './devsetup.sh --command "system-cleanup:full-cleanup"'
        }
    }
}
```

### Integration with Docker

You can use DevSetup to set up Docker containers:

#### Dockerfile Example

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser

# Switch to the non-root user
USER devuser
WORKDIR /home/devuser

# Copy DevSetup files
COPY --chown=devuser:devuser . /home/devuser/devsetup

# Make the script executable
RUN chmod +x /home/devuser/devsetup/devsetup.sh

# Run DevSetup
RUN cd /home/devuser/devsetup && \
    ./devsetup.sh --install --workflow docker-workflow

# Set the entry point
ENTRYPOINT ["/bin/bash"]
```

#### Docker Compose Example

```yaml
version: '3'

services:
  dev-environment:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./:/home/devuser/project
    ports:
      - "3000:3000"
      - "8080:8080"
    environment:
      - DEVSETUP_PATH=/opt/sdks
      - DEVSETUP_WORKFLOW=docker-workflow
```

### Integration with Vagrant

You can use DevSetup to set up Vagrant virtual machines:

#### Vagrantfile Example

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end
  
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  
  config.vm.synced_folder ".", "/vagrant"
  
  config.vm.provision "shell", inline: <<-SHELL
    cd /vagrant
    chmod +x devsetup.sh
    ./devsetup.sh --install --workflow vagrant-workflow
  SHELL
end
```

## Advanced Scripting

### Custom Shell Scripts

You can create custom shell scripts that use DevSetup:

#### Example: Project Setup Script

```bash
#!/bin/bash

# project-setup.sh
# Script to set up a new project environment

# Parse arguments
PROJECT_NAME=$1
PROJECT_TYPE=$2

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_TYPE" ]; then
    echo "Usage: $0 <project-name> <project-type>"
    echo "Project types: node, python, web, flutter"
    exit 1
fi

# Create project directory
mkdir -p ~/projects/$PROJECT_NAME

# Set up environment based on project type
case $PROJECT_TYPE in
    node)
        ./devsetup.sh --install nodejs vscode --path ~/projects/$PROJECT_NAME/sdks
        ./devsetup.sh --command "project-setup:setup-node-project" --param PROJECT_NAME=$PROJECT_NAME
        ;;
    python)
        ./devsetup.sh --install python vscode --path ~/projects/$PROJECT_NAME/sdks
        ./devsetup.sh --command "project-setup:setup-python-project" --param PROJECT_NAME=$PROJECT_NAME
        ;;
    web)
        ./devsetup.sh --install nodejs vscode chrome --path ~/projects/$PROJECT_NAME/sdks
        ./devsetup.sh --command "project-setup:setup-web-project" --param PROJECT_NAME=$PROJECT_NAME
        ;;
    flutter)
        ./devsetup.sh --install flutter android-sdk vscode --path ~/projects/$PROJECT_NAME/sdks
        ./devsetup.sh --command "project-setup:setup-flutter-project" --param PROJECT_NAME=$PROJECT_NAME
        ;;
    *)
        echo "Unknown project type: $PROJECT_TYPE"
        echo "Project types: node, python, web, flutter"
        exit 1
        ;;
esac

echo "Project $PROJECT_NAME of type $PROJECT_TYPE set up successfully!"
```

#### Example: Team Onboarding Script

```bash
#!/bin/bash

# team-onboarding.sh
# Script to onboard a new team member

# Parse arguments
TEAM_MEMBER=$1
ROLE=$2

if [ -z "$TEAM_MEMBER" ] || [ -z "$ROLE" ]; then
    echo "Usage: $0 <team-member> <role>"
    echo "Roles: developer, designer, manager"
    exit 1
fi

# Create team member directory
mkdir -p ~/team/$TEAM_MEMBER

# Set up environment based on role
case $ROLE in
    developer)
        ./devsetup.sh --install --workflow development --path ~/team/$TEAM_MEMBER/sdks
        ./devsetup.sh --command "team-setup:setup-developer" --param TEAM_MEMBER=$TEAM_MEMBER
        ;;
    designer)
        ./devsetup.sh --install --workflow design --path ~/team/$TEAM_MEMBER/sdks
        ./devsetup.sh --command "team-setup:setup-designer" --param TEAM_MEMBER=$TEAM_MEMBER
        ;;
    manager)
        ./devsetup.sh --install --workflow management --path ~/team/$TEAM_MEMBER/sdks
        ./devsetup.sh --command "team-setup:setup-manager" --param TEAM_MEMBER=$TEAM_MEMBER
        ;;
    *)
        echo "Unknown role: $ROLE"
        echo "Roles: developer, designer, manager"
        exit 1
        ;;
esac

echo "Team member $TEAM_MEMBER with role $ROLE onboarded successfully!"
```

### Scripting with Environment Variables

You can use environment variables to configure DevSetup:

```bash
#!/bin/bash

# Set environment variables
export DEVSETUP_PATH=/opt/custom-sdks
export DEVSETUP_WORKFLOW=custom-workflow
export DEVSETUP_VERBOSE=1
export DEVSETUP_DRY_RUN=0

# Run DevSetup
./devsetup.sh --install
```

### Scripting with Configuration Files

You can create custom configuration files for DevSetup:

```bash
#!/bin/bash

# Create a custom configuration file
cat > custom-config.json << EOF
{
  "install_path": "/opt/custom-sdks",
  "workflow": "custom-workflow",
  "verbose": true,
  "dry_run": false,
  "targets": ["vscode", "nodejs", "chrome"],
  "remote": {
    "node": "dev-laptop",
    "parallel": false
  }
}
EOF

# Run DevSetup with the custom configuration file
./devsetup.sh --config custom-config.json
```

## Advanced Features

### Template Generation

DevSetup includes a template generation system that can create project templates:

```bash
# Generate a Node.js project template
./devsetup.sh --generate-template nodejs --output ~/projects/my-node-app

# Generate a Python project template
./devsetup.sh --generate-template python --output ~/projects/my-python-app

# Generate a web project template
./devsetup.sh --generate-template web --output ~/projects/my-web-app

# Generate a Flutter project template
./devsetup.sh --generate-template flutter --output ~/projects/my-flutter-app
```

### Plugin System

DevSetup supports plugins that can extend its functionality:

1. Create a plugin directory in `.dev/plugins/` (e.g., `.dev/plugins/my-plugin/`)
2. Create a plugin manifest file (e.g., `.dev/plugins/my-plugin/plugin.json`)
3. Create plugin files (e.g., `.dev/plugins/my-plugin/my-plugin.sh`)
4. Load the plugin using the `--load-plugin` option

Example plugin manifest:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "description": "A custom plugin for DevSetup",
  "version": "1.0.0",
  "author": "Your Name",
  "main": "my-plugin.sh",
  "hooks": {
    "pre-install": "pre_install",
    "post-install": "post_install",
    "pre-uninstall": "pre_uninstall",
    "post-uninstall": "post_uninstall"
  },
  "commands": {
    "my-command": {
      "description": "A custom command",
      "function": "my_command"
    }
  }
}
```

Example plugin file:

```bash
#!/bin/bash

# my-plugin.sh

# Hook functions
pre_install() {
    echo "Pre-install hook called"
}

post_install() {
    echo "Post-install hook called"
}

pre_uninstall() {
    echo "Pre-uninstall hook called"
}

post_uninstall() {
    echo "Post-uninstall hook called"
}

# Command functions
my_command() {
    echo "My custom command called with arguments: $@"
}
```

To use the plugin:

```bash
# Load the plugin
./devsetup.sh --load-plugin my-plugin

# Use a plugin command
./devsetup.sh --command "my-plugin:my-command"
```

### Conversion Tools

DevSetup includes tools to convert existing configurations to its module format:

```bash
# Convert a shell script to a module
./devsetup.sh --convert-script install-script.sh --output .dev/modules/software/converted-module.json

# Convert a Docker Compose file to modules
./devsetup.sh --convert-compose docker-compose.yml --output .dev/modules/software/

# Convert a package.json file to a Node.js module
./devsetup.sh --convert-package package.json --output .dev/modules/software/nodejs-project.json
```

## Performance Optimization

### Parallel Installation

You can install multiple software packages in parallel:

```bash
./devsetup.sh --install vscode nodejs chrome --parallel
```

### Caching

DevSetup supports caching downloaded files to speed up installation:

```bash
# Enable caching
./devsetup.sh --install --cache

# Specify a custom cache directory
./devsetup.sh --install --cache-dir ~/devsetup-cache

# Clear the cache
./devsetup.sh --clear-cache
```

### Minimal Installation

You can perform a minimal installation with only essential components:

```bash
./devsetup.sh --install --minimal
```

## Security Considerations

### Secure Configuration

To secure your DevSetup configuration:

1. **Avoid storing passwords** in configuration files
2. **Use SSH keys** for remote execution
3. **Use environment variables** for sensitive information
4. **Validate module sources** before installation
5. **Review commands** before execution

### Secure Remote Execution

To secure remote execution:

1. **Use SSH keys** instead of passwords
2. **Configure passwordless sudo** with limited privileges
3. **Use a dedicated user** for DevSetup operations
4. **Limit SSH access** to specific IP addresses
5. **Use SSH key passphrase** for additional security

## Next Steps

Now that you understand advanced usage, you can:

- Create your own custom modules and workflows
- Integrate DevSetup with your CI/CD pipelines
- Use DevSetup with Docker and Vagrant
- Create custom scripts that use DevSetup
- Extend DevSetup with plugins