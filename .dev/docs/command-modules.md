# Command Modules Guide

This guide provides detailed information about DevSetup command modules, including how they work, what pre-defined command modules are available, and how to create your own custom command modules.

## What are Command Modules?

Command modules in DevSetup are JSON files that define reusable commands that can be executed by the system. These commands can be used to perform various operations, such as cleaning up the system, configuring software, or running tests.

Command modules are located in the `.dev/modules/commands/` directory, with each module defined in its own JSON file.

## Module Structure

A command module is defined in a JSON file with the following structure:

```json
{
  "type": "command",
  "id": "example-commands",
  "name": "Example Commands",
  "description": "Description of the command module",
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

### Field Descriptions

| Field | Description | Required |
|-------|-------------|----------|
| `type` | Always "command" for command modules | Yes |
| `id` | Unique identifier for the module | Yes |
| `name` | Human-readable name for the module | Yes |
| `description` | Description of what the module does | Yes |
| `commands` | Object defining the commands in this module | Yes |

Each command in the `commands` object has the following structure:

| Field | Description | Required |
|-------|-------------|----------|
| `description` | Description of what the command does | Yes |
| `execute` | Array of commands to execute | Yes |
| `requires` | Array of requirements for the command | No |

## Command References

Commands can reference other commands using the `@` symbol. For example, `@command1` references the `command1` command in the same module. You can also reference commands in other modules using the format `@module_id:command_id`.

Example:

```json
"commands": {
  "clean-apt": {
    "description": "Clean APT cache",
    "execute": [
      "sudo apt autoremove -y",
      "sudo apt clean"
    ]
  },
  "clean-docker": {
    "description": "Clean Docker images and containers",
    "execute": [
      "docker system prune -f"
    ],
    "requires": ["docker"]
  },
  "full-cleanup": {
    "description": "Perform a full system cleanup",
    "execute": [
      "@clean-apt",
      "@clean-docker"
    ]
  }
}
```

In this example, the `full-cleanup` command references the `clean-apt` and `clean-docker` commands in the same module.

## Pre-defined Command Modules

DevSetup includes several pre-defined command modules for common operations:

### System Cleanup

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
    "clean-docker": {
      "description": "Clean Docker images and containers",
      "execute": [
        "docker system prune -f"
      ],
      "requires": ["docker"]
    },
    "clean-npm": {
      "description": "Clean npm cache",
      "execute": [
        "npm cache clean --force"
      ],
      "requires": ["nodejs"]
    },
    "clean-yarn": {
      "description": "Clean yarn cache",
      "execute": [
        "yarn cache clean"
      ],
      "requires": ["nodejs"]
    },
    "clean-pip": {
      "description": "Clean pip cache",
      "execute": [
        "pip cache purge"
      ],
      "requires": ["python"]
    },
    "clean-tmp": {
      "description": "Clean temporary files",
      "execute": [
        "rm -rf /tmp/tmp.* 2>/dev/null || true"
      ]
    },
    "clean-downloads": {
      "description": "Clean downloads directory",
      "execute": [
        "rm -rf ~/Downloads/*.deb ~/Downloads/*.tar.gz ~/Downloads/*.zip 2>/dev/null || true"
      ]
    },
    "dev-cleanup": {
      "description": "Clean up development-related files",
      "execute": [
        "@clean-apt",
        "@clean-npm",
        "@clean-yarn",
        "@clean-pip",
        "@clean-tmp",
        "@clean-downloads"
      ]
    },
    "full-cleanup": {
      "description": "Perform a full system cleanup",
      "execute": [
        "@clean-apt",
        "@clean-docker",
        "@clean-npm",
        "@clean-yarn",
        "@clean-pip",
        "@clean-tmp",
        "@clean-downloads"
      ]
    }
  }
}
```

### Backup

```json
{
  "type": "command",
  "id": "backup",
  "name": "Backup",
  "description": "Backup system and project files",
  "commands": {
    "backup-config": {
      "description": "Backup configuration files",
      "execute": [
        "mkdir -p ~/backups/config",
        "cp -r ~/.config ~/backups/config/config-$(date +%Y%m%d)",
        "cp -r ~/.bash* ~/backups/config/bash-$(date +%Y%m%d)",
        "cp -r ~/.profile ~/backups/config/profile-$(date +%Y%m%d)",
        "echo 'Configuration files backed up to ~/backups/config'"
      ]
    },
    "backup-project": {
      "description": "Backup current project",
      "execute": [
        "mkdir -p ~/backups/projects",
        "tar -czf ~/backups/projects/$(basename $(pwd))-$(date +%Y%m%d).tar.gz .",
        "echo 'Project backed up to ~/backups/projects'"
      ]
    },
    "backup-database": {
      "description": "Backup databases",
      "execute": [
        "mkdir -p ~/backups/databases",
        "echo 'Please specify the database to backup using --command \"backup:backup-database-mysql\" or --command \"backup:backup-database-postgres\"'"
      ]
    },
    "backup-database-mysql": {
      "description": "Backup MySQL databases",
      "execute": [
        "mkdir -p ~/backups/databases/mysql",
        "mysqldump --all-databases -u root -p > ~/backups/databases/mysql/all-$(date +%Y%m%d).sql",
        "echo 'MySQL databases backed up to ~/backups/databases/mysql'"
      ],
      "requires": ["mysql-client"]
    },
    "backup-database-postgres": {
      "description": "Backup PostgreSQL databases",
      "execute": [
        "mkdir -p ~/backups/databases/postgres",
        "pg_dumpall -U postgres > ~/backups/databases/postgres/all-$(date +%Y%m%d).sql",
        "echo 'PostgreSQL databases backed up to ~/backups/databases/postgres'"
      ],
      "requires": ["postgresql-client"]
    },
    "full-backup": {
      "description": "Perform a full backup",
      "execute": [
        "@backup-config",
        "@backup-project",
        "echo 'Full backup completed'"
      ]
    }
  }
}
```

## Creating Custom Command Modules

You can create your own custom command modules to suit your specific needs:

1. Create a new JSON file in `.dev/modules/commands/` for your module (e.g., `.dev/modules/commands/my-commands.json`)
2. Define the module structure in the file

### Example: Creating a Project Setup Module

```json
{
  "type": "command",
  "id": "project-setup",
  "name": "Project Setup",
  "description": "Set up a new project",
  "commands": {
    "create-node-project": {
      "description": "Create a new Node.js project",
      "execute": [
        "mkdir -p ~/projects/{PROJECT_NAME}",
        "cd ~/projects/{PROJECT_NAME}",
        "npm init -y",
        "npm install express",
        "echo 'const express = require(\"express\");\\nconst app = express();\\nconst port = 3000;\\n\\napp.get(\"/\", (req, res) => {\\n  res.send(\"Hello, World!\");\\n});\\n\\napp.listen(port, () => {\\n  console.log(`Server running at http://localhost:${port}`);\\n});' > index.js",
        "echo 'Node.js project created at ~/projects/{PROJECT_NAME}'"
      ],
      "requires": ["nodejs"]
    },
    "create-python-project": {
      "description": "Create a new Python project",
      "execute": [
        "mkdir -p ~/projects/{PROJECT_NAME}",
        "cd ~/projects/{PROJECT_NAME}",
        "python3 -m venv venv",
        "echo 'def main():\\n    print(\"Hello, World!\")\\n\\nif __name__ == \"__main__\":\\n    main()' > app.py",
        "echo 'Python project created at ~/projects/{PROJECT_NAME}'"
      ],
      "requires": ["python"]
    },
    "create-web-project": {
      "description": "Create a new web project",
      "execute": [
        "mkdir -p ~/projects/{PROJECT_NAME}",
        "cd ~/projects/{PROJECT_NAME}",
        "mkdir -p css js img",
        "echo '<!DOCTYPE html>\\n<html>\\n<head>\\n  <meta charset=\"UTF-8\">\\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\\n  <title>{PROJECT_NAME}</title>\\n  <link rel=\"stylesheet\" href=\"css/style.css\">\\n</head>\\n<body>\\n  <h1>Hello, World!</h1>\\n  <script src=\"js/script.js\"></script>\\n</body>\\n</html>' > index.html",
        "echo 'body {\\n  font-family: Arial, sans-serif;\\n  margin: 0;\\n  padding: 20px;\\n}\\n\\nh1 {\\n  color: #333;\\n}' > css/style.css",
        "echo 'console.log(\"Hello, World!\");' > js/script.js",
        "echo 'Web project created at ~/projects/{PROJECT_NAME}'"
      ]
    },
    "setup-git": {
      "description": "Set up Git for a project",
      "execute": [
        "cd ~/projects/{PROJECT_NAME}",
        "git init",
        "echo 'node_modules/\\nvenv/\\n*.log\\n*.pyc\\n__pycache__/' > .gitignore",
        "git add .",
        "git commit -m 'Initial commit'",
        "echo 'Git repository initialized at ~/projects/{PROJECT_NAME}'"
      ],
      "requires": ["git"]
    },
    "setup-node-project": {
      "description": "Set up a complete Node.js project",
      "execute": [
        "@create-node-project",
        "@setup-git",
        "echo 'Node.js project setup completed'"
      ],
      "requires": ["nodejs", "git"]
    },
    "setup-python-project": {
      "description": "Set up a complete Python project",
      "execute": [
        "@create-python-project",
        "@setup-git",
        "echo 'Python project setup completed'"
      ],
      "requires": ["python", "git"]
    },
    "setup-web-project": {
      "description": "Set up a complete web project",
      "execute": [
        "@create-web-project",
        "@setup-git",
        "echo 'Web project setup completed'"
      ],
      "requires": ["git"]
    }
  }
}
```

To use this module:

```bash
# Create a new Node.js project
./devsetup.sh --command "project-setup:setup-node-project" --param PROJECT_NAME=my-node-app

# Create a new Python project
./devsetup.sh --command "project-setup:setup-python-project" --param PROJECT_NAME=my-python-app

# Create a new web project
./devsetup.sh --command "project-setup:setup-web-project" --param PROJECT_NAME=my-web-app
```

## Parameter Substitution

DevSetup supports parameter substitution in command modules. Parameters can be specified using the `--param` option and are referenced in commands using the format `{PARAMETER_NAME}`.

Example:

```json
"commands": {
  "create-project": {
    "description": "Create a new project",
    "execute": [
      "mkdir -p ~/projects/{PROJECT_NAME}",
      "cd ~/projects/{PROJECT_NAME}",
      "echo 'Project created at ~/projects/{PROJECT_NAME}'"
    ]
  }
}
```

To use this command with a parameter:

```bash
./devsetup.sh --command "my-commands:create-project" --param PROJECT_NAME=my-awesome-project
```

## Requirements

Commands can specify requirements that must be met before the command can be executed. Requirements can be software modules or system packages.

Example:

```json
"commands": {
  "clean-docker": {
    "description": "Clean Docker images and containers",
    "execute": [
      "docker system prune -f"
    ],
    "requires": ["docker"]
  }
}
```

In this example, the `clean-docker` command requires the `docker` software module to be installed.

## Command Chaining

Commands can be chained together using the `@` symbol to reference other commands. This allows you to create complex operations by combining simpler ones.

Example:

```json
"commands": {
  "clean-apt": {
    "description": "Clean APT cache",
    "execute": [
      "sudo apt autoremove -y",
      "sudo apt clean"
    ]
  },
  "clean-tmp": {
    "description": "Clean temporary files",
    "execute": [
      "rm -rf /tmp/tmp.* 2>/dev/null || true"
    ]
  },
  "full-cleanup": {
    "description": "Perform a full system cleanup",
    "execute": [
      "@clean-apt",
      "@clean-tmp",
      "echo 'System cleanup completed'"
    ]
  }
}
```

In this example, the `full-cleanup` command chains together the `clean-apt` and `clean-tmp` commands.

## Cross-Module References

Commands can reference commands in other modules using the format `@module_id:command_id`.

Example:

```json
"commands": {
  "setup-project": {
    "description": "Set up a new project",
    "execute": [
      "@project-setup:create-node-project",
      "@system-cleanup:clean-tmp",
      "echo 'Project setup completed'"
    ]
  }
}
```

In this example, the `setup-project` command references the `create-node-project` command in the `project-setup` module and the `clean-tmp` command in the `system-cleanup` module.

## Best Practices

When creating command modules, follow these best practices:

1. **Use descriptive IDs** that clearly identify the module and its commands
2. **Include detailed descriptions** for the module and its commands
3. **Specify all requirements** to ensure proper execution
4. **Break down complex operations** into simpler commands
5. **Use parameter substitution** for dynamic values
6. **Test commands** with the `--dry-run` option before executing them
7. **Document modules** with comments and README files
8. **Handle errors gracefully** by checking command exit codes and providing fallback options
9. **Keep commands focused** on a single operation
10. **Use command chaining** to create complex operations from simpler ones

## Next Steps

Now that you understand command modules, you can:

- Learn about [Software Modules](software-modules.md) to see what software is available
- Check out [Workflows](workflows.md) to understand how to combine modules
- Explore [Remote Execution](remote-execution.md) to configure multiple machines
- See [Advanced Usage](advanced-usage.md) for more advanced features