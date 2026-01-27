{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": [
        "--root",
        "${workspaceFolder}"
      ],
      "description": "Access to project files and directories",
      "capabilities": [
        "read_file",
        "write_file",
        "list_directory",
        "search_files",
        "file_info",
        "create_directory"
      ],
      "config": {
        "root_path": "${workspaceFolder}",
        "allowed_extensions": [
          ".js",
          ".ts",
          ".jsx",
          ".tsx",
          ".py",
          ".java",
          ".go",
          ".rb",
          ".php",
          ".md",
          ".json",
          ".yaml",
          ".yml",
          ".sql",
          ".css",
          ".scss",
          ".html"
        ],
        "denied_extensions": [
          ".exe",
          ".dll",
          ".so"
        ],
        "excluded_directories": [
          "node_modules",
          ".git",
          "dist",
          "build",
          ".next",
          "coverage"
        ],
        "max_file_size": "10MB",
        "max_files_per_operation": 100
      },
      "permissions": {
        "read": true,
        "write": true,
        "delete": false,
        "execute": false
      },
      "security": {
        "sandbox": true,
        "audit_log": true,
        "rate_limit": {
          "max_requests": 100,
          "window": "1m"
        }
      }
    },
    
    "git": {
      "command": "mcp-server-git",
      "args": [
        "--repository",
        "${workspaceFolder}"
      ],
      "description": "Git version control operations",
      "capabilities": [
        "status",
        "diff",
        "log",
        "branch",
        "commit",
        "checkout",
        "stash",
        "remote"
      ],
      "config": {
        "repository_path": "${workspaceFolder}",
        "auto_fetch": false,
        "default_branch": "main"
      },
      "permissions": {
        "read": true,
        "write": true,
        "force_push": false
      }
    },
    
    "database": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection",
        "${env:DATABASE_URL}"
      ],
      "description": "PostgreSQL database access",
      "capabilities": [
        "query",
        "execute",
        "schema_info",
        "table_info",
        "explain_query"
      ],
      "config": {
        "connection_string": "${env:DATABASE_URL}",
        "pool_size": 5,
        "timeout": 30000,
        "ssl": true
      },
      "permissions": {
        "read": true,
        "write": true,
        "ddl": false,
        "drop": false
      },
      "security": {
        "read_only_mode": false,
        "allowed_schemas": [
          "public",
          "app"
        ],
        "denied_tables": [
          "audit_log",
          "user_secrets"
        ],
        "query_timeout": "30s",
        "max_rows": 1000
      }
    },
    
    "testing": {
      "command": "mcp-server-jest",
      "args": [
        "--config",
        "${workspaceFolder}/jest.config.js"
      ],
      "description": "Jest testing framework integration",
      "capabilities": [
        "run_tests",
        "run_coverage",
        "run_watch",
        "test_file",
        "test_pattern"
      ],
      "config": {
        "config_path": "${workspaceFolder}/jest.config.js",
        "coverage_threshold": 80,
        "max_workers": 4
      }
    },
    
    "api_integration": {
      "command": "mcp-server-http",
      "args": [],
      "description": "HTTP API integration for external services",
      "capabilities": [
        "http_request",
        "rest_api",
        "graphql"
      ],
      "config": {
        "allowed_domains": [
          "api.github.com",
          "api.stripe.com",
          "api.sendgrid.com"
        ],
        "timeout": 30000,
        "retry_attempts": 3,
        "retry_delay": 1000
      },
      "security": {
        "require_auth": true,
        "allowed_methods": [
          "GET",
          "POST",
          "PUT",
          "PATCH"
        ],
        "denied_methods": [
          "DELETE"
        ],
        "headers": {
          "User-Agent": "ClaudeCode/1.0",
          "Accept": "application/json"
        }
      }
    },
    
    "slack": {
      "command": "mcp-server-slack",
      "args": [
        "--token",
        "${env:SLACK_BOT_TOKEN}"
      ],
      "description": "Slack workspace integration",
      "capabilities": [
        "send_message",
        "list_channels",
        "list_users",
        "upload_file",
        "get_thread"
      ],
      "config": {
        "bot_token": "${env:SLACK_BOT_TOKEN}",
        "workspace": "mycompany",
        "default_channel": "#general"
      },
      "permissions": {
        "send_messages": true,
        "read_messages": true,
        "manage_channels": false
      }
    },
    
    "docker": {
      "command": "mcp-server-docker",
      "args": [],
      "description": "Docker container management",
      "capabilities": [
        "list_containers",
        "list_images",
        "container_logs",
        "container_stats",
        "build_image",
        "run_container"
      ],
      "config": {
        "docker_host": "unix:///var/run/docker.sock",
        "api_version": "1.41"
      },
      "permissions": {
        "read": true,
        "build": true,
        "run": true,
        "stop": true,
        "remove": false
      },
      "security": {
        "allowed_images": [
          "node:*",
          "python:*",
          "postgres:*"
        ],
        "resource_limits": {
          "memory": "2GB",
          "cpu": "2"
        }
      }
    },
    
    "cloud_storage": {
      "command": "mcp-server-s3",
      "args": [
        "--bucket",
        "${env:S3_BUCKET}"
      ],
      "description": "AWS S3 storage access",
      "capabilities": [
        "list_objects",
        "get_object",
        "put_object",
        "delete_object",
        "generate_presigned_url"
      ],
      "config": {
        "bucket": "${env:S3_BUCKET}",
        "region": "us-east-1",
        "access_key": "${env:AWS_ACCESS_KEY}",
        "secret_key": "${env:AWS_SECRET_KEY}"
      },
      "permissions": {
        "read": true,
        "write": true,
        "delete": false
      },
      "security": {
        "encryption": "AES256",
        "allowed_prefixes": [
          "uploads/",
          "documents/"
        ]
      }
    },
    
    "monitoring": {
      "command": "mcp-server-datadog",
      "args": [
        "--api-key",
        "${env:DATADOG_API_KEY}"
      ],
      "description": "Datadog monitoring and metrics",
      "capabilities": [
        "send_metric",
        "send_event",
        "query_metrics",
        "get_service_status"
      ],
      "config": {
        "api_key": "${env:DATADOG_API_KEY}",
        "app_key": "${env:DATADOG_APP_KEY}",
        "site": "datadoghq.com"
      }
    },
    
    "email": {
      "command": "mcp-server-sendgrid",
      "args": [
        "--api-key",
        "${env:SENDGRID_API_KEY}"
      ],
      "description": "SendGrid email service",
      "capabilities": [
        "send_email",
        "send_template",
        "get_stats"
      ],
      "config": {
        "api_key": "${env:SENDGRID_API_KEY}",
        "from_email": "noreply@mycompany.com",
        "from_name": "My Company"
      },
      "permissions": {
        "send": true,
        "templates": true,
        "stats": true
      },
      "security": {
        "rate_limit": {
          "max_emails": 100,
          "window": "1h"
        },
        "allowed_domains": [
          "mycompany.com"
        ]
      }
    }
  },
  
  "globalConfig": {
    "timeout": 30000,
    "retry": {
      "enabled": true,
      "max_attempts": 3,
      "backoff": "exponential",
      "initial_delay": 1000
    },
    
    "logging": {
      "enabled": true,
      "level": "info",
      "file": "${workspaceFolder}/.claude-code/mcp.log",
      "rotation": {
        "max_size": "10MB",
        "max_files": 5
      }
    },
    
    "security": {
      "audit_log": {
        "enabled": true,
        "file": "${workspaceFolder}/.claude-code/audit.log",
        "events": [
          "server_start",
          "server_stop",
          "capability_used",
          "permission_denied",
          "error"
        ]
      },
      
      "encryption": {
        "enabled": true,
        "algorithm": "AES-256-GCM"
      },
      
      "authentication": {
        "required": true,
        "method": "token"
      }
    },
    
    "performance": {
      "cache": {
        "enabled": true,
        "ttl": 300,
        "max_size": "100MB"
      },
      
      "connection_pool": {
        "min_connections": 2,
        "max_connections": 10,
        "idle_timeout": 30000
      }
    },
    
    "monitoring": {
      "health_check": {
        "enabled": true,
        "interval": 60000,
        "endpoint": "/health"
      },
      
      "metrics": {
        "enabled": true,
        "interval": 10000,
        "endpoint": "/metrics"
      }
    }
  },
  
  "environmentVariables": {
    "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb",
    "SLACK_BOT_TOKEN": "xoxb-your-token",
    "S3_BUCKET": "my-app-bucket",
    "AWS_ACCESS_KEY": "your-access-key",
    "AWS_SECRET_KEY": "your-secret-key",
    "DATADOG_API_KEY": "your-datadog-key",
    "DATADOG_APP_KEY": "your-app-key",
    "SENDGRID_API_KEY": "your-sendgrid-key"
  },
  
  "usage_examples": {
    "read_file": {
      "description": "Read a source file",
      "server": "filesystem",
      "capability": "read_file",
      "example": {
        "path": "src/index.js"
      }
    },
    
    "run_tests": {
      "description": "Run test suite",
      "server": "testing",
      "capability": "run_tests",
      "example": {
        "pattern": "src/**/*.test.js"
      }
    },
    
    "query_database": {
      "description": "Query database",
      "server": "database",
      "capability": "query",
      "example": {
        "sql": "SELECT * FROM users WHERE active = true LIMIT 10"
      }
    },
    
    "send_slack_message": {
      "description": "Send message to Slack",
      "server": "slack",
      "capability": "send_message",
      "example": {
        "channel": "#deployments",
        "text": "Deployment successful!"
      }
    }
  },
  
  "troubleshooting": {
    "connection_failed": {
      "issue": "Server failed to connect",
      "solutions": [
        "Check if server is installed: npm list -g mcp-server-*",
        "Verify configuration path is correct",
        "Check environment variables are set",
        "Review server logs in .claude-code/mcp.log"
      ]
    },
    
    "permission_denied": {
      "issue": "Operation not allowed",
      "solutions": [
        "Review permissions in server config",
        "Check if capability is enabled",
        "Verify security settings allow the operation",
        "Check audit log for details"
      ]
    },
    
    "timeout": {
      "issue": "Operation timed out",
      "solutions": [
        "Increase timeout value in config",
        "Check network connectivity",
        "Review server performance",
        "Reduce operation complexity"
      ]
    }
  }
}