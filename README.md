# Development Workstation Setup Script

A shell script for installing and uninstalling development tools on Ubuntu 24.04. This script is designed to automate the setup of a development workstation with common tools and SDKs.

## Features

- Install or uninstall specific software targets or all at once
- Install SDKs to a designated path (default: `/opt/sdks/`)
- Export SDK path information to the user's `.bash_aliases` file
- Check if software is already installed and its version
- Handle dependencies automatically
- Configurable VSCode extensions

## Supported Software

- **IDEs and Editors**
  - Visual Studio Code
  - VSCode Extensions

- **Version Control**
  - GitKraken

- **Browsers**
  - Google Chrome
  - Microsoft Edge

- **SDKs and Programming Languages**
  - Flutter SDK
  - Android SDK
  - Android Studio
  - .NET SDK
  - Go Programming Language
  - Java Development Kit (JDK)
  - Node.js

## Prerequisites

- Ubuntu 24.04 LTS
- Bash shell
- Internet connection
- Sudo privileges

## Installation

1. Clone or download this repository
2. Make the script executable (if not already): `chmod +x devsetup.sh`
3. Run the script with desired options

## Usage

```
Usage: ./devsetup.sh [OPTIONS] [TARGETS...]

Options:
  --install, -i       Install specified targets or all if none specified
  --uninstall, -u     Uninstall specified targets or all if none specified
  --path PATH         Specify custom installation path for SDKs (default: /opt/sdks)
  --dry-run           Show what would be done without making changes
  --verbose, -v       Display verbose output
  --help, -h          Display this help message
  --version           Display script version

Targets:
  vscode              Visual Studio Code
  vscode-extensions   VSCode Extensions (requires VSCode)
  gitkraken           GitKraken
  chrome              Google Chrome
  edge                Microsoft Edge
  flutter             Flutter SDK
  android-sdk         Android SDK
  android-studio      Android Studio
  dotnet              .NET SDK
  go                  Go Programming Language
  jdk                 Java Development Kit
  nodejs              Node.js
```

## Examples

Install all software:
```
./devsetup.sh --install
```

Install specific software:
```
./devsetup.sh --install vscode flutter nodejs
```

Uninstall specific software:
```
./devsetup.sh --uninstall nodejs
```

Install Go to a custom path:
```
./devsetup.sh --install --path ~/sdks go
```

Dry run (show what would be done without making changes):
```
./devsetup.sh --install --dry-run vscode flutter
```

## Configuration

The script uses two configuration files:

1. `config/config.json` - Main configuration file with installation details for each target
2. `config/vscode_extensions.txt` - List of VSCode extensions to install

### Customizing VSCode Extensions

Edit the `config/vscode_extensions.txt` file to add or remove extensions. Each line should contain the extension ID. Lines starting with `#` are treated as comments.

### Adding New Software

To add support for new software, edit the `config/config.json` file and add a new entry with the following structure:

```json
"software-id": {
  "name": "Software Name",
  "check_command": "command to check if installed",
  "version_regex": "regex to extract version",
  "install_commands": [
    "command 1",
    "command 2",
    "..."
  ],
  "uninstall_commands": [
    "command 1",
    "command 2",
    "..."
  ],
  "dependencies": [
    "dependency1",
    "dependency2",
    "..."
  ],
  "path_exports": [
    "export PATH=\"{INSTALL_PATH}/bin:$PATH\""
  ]
}
```

## Safety Features

- Creates backups of modified files (e.g., .bash_aliases)
- Checks if software is already installed before attempting installation
- Uses version checks to avoid reinstalling already installed software
- Implements proper error handling and logging
- Provides a dry-run option to show what would be done without making changes

## Logs

The script creates a log file in `/tmp/devsetup_YYYYMMDD_HHMMSS.log` with detailed information about the installation or uninstallation process.

## License

This project is licensed under the MIT License - see the LICENSE file for details.