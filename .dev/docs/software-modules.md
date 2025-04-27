# Software Modules Guide

This guide provides detailed information about DevSetup software modules, including how they work, what pre-defined modules are available, and how to create your own custom modules.

## What are Software Modules?

Software modules in DevSetup are JSON files that define how to install, uninstall, and configure specific software packages. Each module is self-contained and can be used independently or as part of a workflow.

Software modules are located in the `.dev/modules/software/` directory, with each module defined in its own JSON file.

## Module Structure

A software module is defined in a JSON file with the following structure:

```json
{
  "type": "software",
  "id": "example",
  "name": "Example Software",
  "description": "Description of the software",
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

### Field Descriptions

| Field | Description | Required |
|-------|-------------|----------|
| `type` | Always "software" for software modules | Yes |
| `id` | Unique identifier for the module | Yes |
| `name` | Human-readable name for the software | Yes |
| `description` | Description of what the software does | Yes |
| `check_command` | Command to check if the software is installed | Yes |
| `version_regex` | Regular expression to extract the version from the check command output | No |
| `install_commands` | Array of commands to install the software | Yes |
| `uninstall_commands` | Array of commands to uninstall the software | Yes |
| `dependencies` | Array of other software modules or system packages that this module depends on | No |
| `path_exports` | Array of PATH exports to add to the user's shell configuration | No |
| `commands` | Object defining custom commands for this module | No |

## Pre-defined Software Modules

DevSetup includes several pre-defined software modules for common development tools:

### Development Tools

#### VSCode

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

#### GitKraken

```json
{
  "type": "software",
  "id": "gitkraken",
  "name": "GitKraken",
  "description": "Git GUI client",
  "check_command": "which gitkraken",
  "install_commands": [
    "wget -O gitkraken.deb https://release.gitkraken.com/linux/gitkraken-amd64.deb",
    "sudo dpkg -i gitkraken.deb",
    "sudo apt-get install -f -y",
    "rm gitkraken.deb"
  ],
  "uninstall_commands": [
    "sudo apt purge -y gitkraken",
    "sudo apt autoremove -y"
  ],
  "dependencies": [
    "wget",
    "gconf2",
    "gconf-service",
    "libgtk2.0-0"
  ]
}
```

### Web Browsers

#### Chrome

```json
{
  "type": "software",
  "id": "chrome",
  "name": "Google Chrome",
  "description": "Web browser from Google",
  "check_command": "google-chrome --version",
  "version_regex": "Google Chrome ([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "wget -qO- https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -",
    "sudo sh -c 'echo \"deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main\" > /etc/apt/sources.list.d/google-chrome.list'",
    "sudo apt update",
    "sudo apt install -y google-chrome-stable"
  ],
  "uninstall_commands": [
    "sudo apt purge -y google-chrome-stable",
    "sudo rm -f /etc/apt/sources.list.d/google-chrome.list",
    "sudo apt update"
  ],
  "dependencies": [
    "wget"
  ]
}
```

### Programming Languages

#### Node.js

```json
{
  "type": "software",
  "id": "nodejs",
  "name": "Node.js",
  "description": "JavaScript runtime built on Chrome's V8 JavaScript engine",
  "check_command": "node --version",
  "version_regex": "v([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
    "sudo apt install -y nodejs"
  ],
  "uninstall_commands": [
    "sudo apt purge -y nodejs",
    "sudo rm -f /etc/apt/sources.list.d/nodesource.list",
    "sudo apt update"
  ],
  "dependencies": [
    "curl"
  ],
  "commands": {
    "update": {
      "description": "Update Node.js to the latest version",
      "execute": [
        "sudo apt update",
        "sudo apt install --only-upgrade nodejs"
      ]
    },
    "install-npm-packages": {
      "description": "Install common global npm packages",
      "execute": [
        "sudo npm install -g npm",
        "sudo npm install -g yarn",
        "sudo npm install -g typescript",
        "sudo npm install -g ts-node",
        "sudo npm install -g nodemon"
      ]
    }
  }
}
```

#### Java Development Kit

```json
{
  "type": "software",
  "id": "jdk",
  "name": "Java Development Kit",
  "description": "Development environment for building applications and components using the Java programming language",
  "check_command": "java --version",
  "version_regex": "openjdk ([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "sudo apt update",
    "sudo apt install -y openjdk-17-jdk"
  ],
  "uninstall_commands": [
    "sudo apt purge -y openjdk-17-jdk openjdk-17-jre"
  ],
  "dependencies": [],
  "path_exports": [
    "export JAVA_HOME=\"/usr/lib/jvm/java-17-openjdk-amd64\""
  ]
}
```

### Mobile Development

#### Flutter SDK

```json
{
  "type": "software",
  "id": "flutter",
  "name": "Flutter SDK",
  "description": "Google's UI toolkit for building natively compiled applications",
  "check_command": "{INSTALL_PATH}/flutter/bin/flutter --version",
  "version_regex": "Flutter ([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "mkdir -p {INSTALL_PATH}/flutter",
    "wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.3-stable.tar.xz",
    "tar xf flutter.tar.xz -C {INSTALL_PATH}",
    "rm flutter.tar.xz",
    "{INSTALL_PATH}/flutter/bin/flutter precache"
  ],
  "uninstall_commands": [
    "rm -rf {INSTALL_PATH}/flutter"
  ],
  "path_exports": [
    "export PATH=\"{INSTALL_PATH}/flutter/bin:$PATH\""
  ],
  "dependencies": [
    "wget",
    "git",
    "unzip",
    "xz-utils",
    "curl"
  ],
  "commands": {
    "update": {
      "description": "Update Flutter SDK to the latest version",
      "execute": [
        "{INSTALL_PATH}/flutter/bin/flutter upgrade"
      ]
    },
    "doctor": {
      "description": "Run Flutter doctor to check setup",
      "execute": [
        "{INSTALL_PATH}/flutter/bin/flutter doctor -v"
      ]
    }
  }
}
```

#### Android SDK

```json
{
  "type": "software",
  "id": "android-sdk",
  "name": "Android SDK",
  "description": "Software development kit for Android applications",
  "check_command": "{INSTALL_PATH}/android-sdk/cmdline-tools/latest/bin/sdkmanager --version",
  "version_regex": "([0-9]+\\.[0-9]+)",
  "install_commands": [
    "mkdir -p {INSTALL_PATH}/android-sdk/cmdline-tools",
    "wget -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip",
    "unzip -q cmdline-tools.zip -d {INSTALL_PATH}/android-sdk/cmdline-tools",
    "mv {INSTALL_PATH}/android-sdk/cmdline-tools/cmdline-tools {INSTALL_PATH}/android-sdk/cmdline-tools/latest",
    "rm cmdline-tools.zip",
    "yes | {INSTALL_PATH}/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses",
    "{INSTALL_PATH}/android-sdk/cmdline-tools/latest/bin/sdkmanager \"platform-tools\" \"platforms;android-34\" \"build-tools;34.0.0\""
  ],
  "uninstall_commands": [
    "rm -rf {INSTALL_PATH}/android-sdk"
  ],
  "path_exports": [
    "export ANDROID_HOME=\"{INSTALL_PATH}/android-sdk\"",
    "export PATH=\"$ANDROID_HOME/cmdline-tools/latest/bin:$PATH\"",
    "export PATH=\"$ANDROID_HOME/platform-tools:$PATH\""
  ],
  "dependencies": [
    "wget",
    "unzip",
    "openjdk-17-jdk"
  ]
}
```

## Creating Custom Software Modules

You can create your own custom software modules to suit your specific needs:

1. Create a new JSON file in `.dev/modules/software/` for your module (e.g., `.dev/modules/software/my-software.json`)
2. Define the module structure in the file

### Example: Creating a Python Module

```json
{
  "type": "software",
  "id": "python",
  "name": "Python",
  "description": "Python programming language and tools",
  "check_command": "python3 --version",
  "version_regex": "Python ([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "sudo apt update",
    "sudo apt install -y python3 python3-pip python3-venv"
  ],
  "uninstall_commands": [
    "sudo apt purge -y python3 python3-pip python3-venv"
  ],
  "dependencies": [],
  "path_exports": [],
  "commands": {
    "install-tools": {
      "description": "Install common Python tools",
      "execute": [
        "sudo pip3 install pipenv virtualenv poetry",
        "sudo pip3 install jupyter numpy pandas matplotlib scikit-learn"
      ]
    },
    "create-venv": {
      "description": "Create a Python virtual environment",
      "execute": [
        "python3 -m venv venv",
        "echo 'Virtual environment created. Activate with: source venv/bin/activate'"
      ]
    }
  }
}
```

### Example: Creating a Docker Module

```json
{
  "type": "software",
  "id": "docker",
  "name": "Docker",
  "description": "Platform for developing, shipping, and running applications in containers",
  "check_command": "docker --version",
  "version_regex": "Docker version ([0-9]+\\.[0-9]+\\.[0-9]+)",
  "install_commands": [
    "sudo apt update",
    "sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
    "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
    "sudo apt update",
    "sudo apt install -y docker-ce docker-ce-cli containerd.io",
    "sudo usermod -aG docker $USER",
    "sudo systemctl enable docker",
    "sudo systemctl start docker"
  ],
  "uninstall_commands": [
    "sudo apt purge -y docker-ce docker-ce-cli containerd.io",
    "sudo rm -f /etc/apt/sources.list.d/docker.list",
    "sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg",
    "sudo apt update"
  ],
  "dependencies": [
    "curl"
  ],
  "commands": {
    "install-compose": {
      "description": "Install Docker Compose",
      "execute": [
        "sudo curl -L \"https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
        "sudo chmod +x /usr/local/bin/docker-compose"
      ]
    },
    "clean": {
      "description": "Clean Docker system",
      "execute": [
        "docker system prune -f"
      ]
    }
  }
}
```

## Variable Substitution

DevSetup supports variable substitution in module commands. The following variables are available:

| Variable | Description | Example |
|----------|-------------|---------|
| `{INSTALL_PATH}` | Installation path for SDKs | `/opt/sdks` |
| `{HOME}` | User's home directory | `/home/user` |
| `{USER}` | Current username | `user` |
| `{TIMESTAMP}` | Current timestamp | `20250427_142422` |

Example usage:

```json
"install_commands": [
  "mkdir -p {INSTALL_PATH}/my-software",
  "wget -O {INSTALL_PATH}/my-software/installer.sh https://example.com/installer.sh",
  "chmod +x {INSTALL_PATH}/my-software/installer.sh",
  "{INSTALL_PATH}/my-software/installer.sh"
]
```

## Dependencies

Software modules can specify dependencies on other software modules or system packages. DevSetup will ensure that all dependencies are installed before installing the module.

There are two types of dependencies:

1. **Module dependencies**: Other software modules that this module depends on
2. **System dependencies**: System packages that this module depends on

Example:

```json
"dependencies": [
  "jdk",  // Module dependency
  "wget", // System dependency
  "curl"  // System dependency
]
```

## Path Exports

Software modules can specify PATH exports to add to the user's shell configuration. These exports are added to the user's `.bash_aliases` file.

Example:

```json
"path_exports": [
  "export PATH=\"{INSTALL_PATH}/my-software/bin:$PATH\"",
  "export MY_SOFTWARE_HOME=\"{INSTALL_PATH}/my-software\""
]
```

## Custom Commands

Software modules can define custom commands that can be executed using the `--command` option. These commands can be used to perform various operations, such as updating the software, configuring it, or running tests.

Example:

```json
"commands": {
  "update": {
    "description": "Update the software to the latest version",
    "execute": [
      "wget -O {INSTALL_PATH}/my-software/update.sh https://example.com/update.sh",
      "chmod +x {INSTALL_PATH}/my-software/update.sh",
      "{INSTALL_PATH}/my-software/update.sh"
    ]
  },
  "configure": {
    "description": "Configure the software",
    "execute": [
      "{INSTALL_PATH}/my-software/configure.sh"
    ]
  }
}
```

To execute a custom command:

```bash
./devsetup.sh --command "my-software:update"
```

## Best Practices

When creating software modules, follow these best practices:

1. **Use descriptive IDs** that clearly identify the software
2. **Include detailed descriptions** for the module and its commands
3. **Specify all dependencies** to ensure proper installation
4. **Use version checking** to determine if the software is already installed
5. **Include uninstall commands** to allow for clean removal
6. **Use variable substitution** for paths and other dynamic values
7. **Test modules** with the `--dry-run` option before executing them
8. **Document modules** with comments and README files
9. **Handle errors gracefully** by checking command exit codes and providing fallback options
10. **Keep modules focused** on a single software package

## Next Steps

Now that you understand software modules, you can:

- Learn about [Command Modules](command-modules.md) to execute custom operations
- Check out [Workflows](workflows.md) to understand how to combine modules
- Explore [Remote Execution](remote-execution.md) to configure multiple machines
- See [Advanced Usage](advanced-usage.md) for more advanced features