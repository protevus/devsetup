# Revised Directory Structure with .dev/ Approach

Below is a diagram showing how the modular development environment setup system would be organized when dropped into any project root:

```mermaid
graph TD
    subgraph "Project Root"
        A[devsetup.sh] --> B[.dev/]
        
        B --> C[lib/]
        B --> D[config/]
        B --> E[modules/]
        B --> F[workflows/]
        
        C --> C1[core.sh]
        C --> C2[module.sh]
        C --> C3[command.sh]
        C --> C4[remote.sh]
        C --> C5[utils.sh]
        
        D --> D1[settings.json]
        D --> D2[remote-nodes.json]
        D --> D3[vscode_extensions.txt]
        
        E --> E1[software/]
        E --> E2[commands/]
        
        E1 --> E1A[vscode.json]
        E1 --> E1B[flutter.json]
        E1 --> E1C[nodejs.json]
        
        E2 --> E2A[system.json]
        E2 --> E2B[project.json]
        
        F --> F1[default/]
        F --> F2[flutter-dev/]
        F --> F3[web-dev/]
        
        F1 --> F1A[00-prepare.json]
        F1 --> F1B[01-vscode.json]
        F1 --> F1C[02-cleanup.json]
        
        F2 --> F2A[00-prepare.json]
        F2 --> F2B[01-vscode.json]
        F2 --> F2C[02-flutter-sdk.json]
    end
```

## Key Benefits of This Structure

1. **Minimal Project Impact**: Only one visible script file in the project root
2. **Clean Organization**: All configuration and modules hidden in the `.dev/` directory
3. **Portability**: Entire setup can be easily added to any project
4. **Project-Specific Configuration**: Each project can have its own customized setup
5. **Discoverability**: Main script is visible and easily accessible

## How This Enables Project-Specific Configurations

With this structure, each project can have its own development environment setup:

1. **Project-Specific Modules**: Custom software modules specific to the project
2. **Project Commands**: Commands tailored to the project's needs
3. **Custom Workflows**: Workflows designed for specific project roles
4. **Local Settings**: Configuration specific to the project

## Alternative Structure: Using Profiles

```mermaid
graph TD
    subgraph "Project Root"
        A[devsetup.sh] --> B[.dev/]
        
        B --> C[core/]
        B --> E[modules/]
        B --> F[profiles/]
        
        C --> C1[lib/]
        C --> C2[config/]
        
        E --> E1[00-vscode.json]
        E --> E2[01-flutter.json]
        E --> E3[02-nodejs.json]
        E --> E4[commands/]
        
        E4 --> E4A[system.json]
        E4 --> E4B[project.json]
        
        F --> F1[default.json]
        F --> F2[flutter-dev.json]
        F --> F3[web-dev.json]
    end
```

This alternative structure uses "profiles" instead of "workflows" and puts numeric prefixes directly on module files for a flatter organization.