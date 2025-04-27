# Getting Started with DevSetup

This guide will walk you through the process of setting up and using the DevSetup system for the first time.

## Prerequisites

Before you begin, ensure you have:

- A Linux-based operating system (Ubuntu/Debian recommended)
- Bash shell
- Administrative (sudo) privileges
- Git (optional, for cloning the repository)

## Installation

### Option 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/example/devsetup.git

# Navigate to the directory
cd devsetup

# Make the script executable
chmod +x devsetup.sh
```

### Option 2: Download the Script Directly

```bash
# Download the script
wget https://example.com/devsetup.sh

# Make the script executable
chmod +x devsetup.sh
```

## Basic Usage

### Installing Software

To install all software using the default workflow:

```bash
./devsetup.sh --install
```

This will:
1. Load the default workflow
2. Check for dependencies
3. Install all software defined in the workflow
4. Configure the installed software

### Dry Run Mode

Before making any changes to your system, you can use the dry run mode to see what would happen:

```bash
./devsetup.sh --install --dry-run
```

This will show you all the commands that would be executed without actually executing them.

### Verbose Output

For more detailed output, use the verbose flag:

```bash
./devsetup.sh --install --verbose
```

This will show you detailed information about each step of the process.

## Using Workflows

DevSetup includes several pre-defined workflows for different development scenarios:

### Full Development Environment

```bash
./devsetup.sh --install --workflow development
```

This workflow installs all development tools including:
- VSCode and extensions
- Git tools (GitKraken)
- Web browsers (Chrome, Edge)
- Programming languages (Node.js, Java, Go, .NET)
- Mobile development (Flutter, Android SDK, Android Studio)

### Web Development Environment

```bash
./devsetup.sh --install --workflow web-dev
```

This workflow installs tools focused on web development:
- VSCode and extensions
- Git tools (GitKraken)
- Web browsers (Chrome, Edge)
- Node.js and npm
- Web development tools (Angular, React, Vue, etc.)
- MongoDB

### Mobile Development Environment

```bash
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

## Installing Specific Software

To install specific software packages:

```bash
./devsetup.sh --install vscode nodejs
```

This will install only the specified software packages.

## Uninstalling Software

To uninstall software:

```bash
./devsetup.sh --uninstall vscode
```

This will uninstall the specified software package.

## Checking Installation Status

To check the status of installed software:

```bash
./devsetup.sh --status
```

This will show you which software packages are installed and their versions.

## Next Steps

Now that you have DevSetup installed and know the basics, you can:

- Learn about [Command Line Interface](cli.md) for more advanced options
- Explore [Workflows](workflows.md) to understand how to customize your setup
- Check out [Software Modules](software-modules.md) to see what software is available
- Learn about [Command Modules](command-modules.md) to execute custom operations
- Set up [Remote Execution](remote-execution.md) to configure multiple machines

## Troubleshooting

If you encounter any issues during installation or usage, check the [Troubleshooting Guide](troubleshooting.md) for solutions to common problems.