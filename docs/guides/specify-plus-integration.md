# Specify Plus Integration Guide

## Overview

Specify Plus is an advanced specification and design tool that integrates with Claude Code to enable spec-driven AI development. This guide covers how to use Specify Plus to create detailed specifications that Claude Code can implement.

## Table of Contents
- [What is Specify Plus?](#what-is-specify-plus)
- [Why Use Specify Plus?](#why-use-specify-plus)
- [Getting Started](#getting-started)
- [Creating Specifications](#creating-specifications)
- [Integration with Claude Code](#integration-with-claude-code)
- [Workflow Examples](#workflow-examples)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)

## What is Specify Plus?

### Definition

**Specify Plus** is a specification platform that allows you to create detailed, structured specifications for software projects that AI agents can understand and implement.

### Core Capabilities

```
Specify Plus Features:
┌─────────────────────────────────────┐
│ 1. Visual Design Tools              │
│    • UI mockups                     │
│    • Architecture diagrams          │
│    • Data flow diagrams             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 2. Structured Specifications        │
│    • API contracts                  │
│    • Database schemas               │
│    • Business logic rules           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 3. AI-Readable Format               │
│    • Standardized structure         │
│    • Clear requirements             │
│    • Validation rules               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 4. Claude Code Integration          │
│    • Direct import to Claude Code   │
│    • Automatic code generation      │
│    • Spec validation                │
└─────────────────────────────────────┘
```

### Architecture

```
┌─────────────────────────────────────┐
│      Specify Plus Editor            │
│   (Create Specifications)           │
└──────────────┬──────────────────────┘
               │
               │ Export Spec
               ▼
┌─────────────────────────────────────┐
│   Specification File (.spec.json)   │
└──────────────┬──────────────────────┘
               │
               │ Import
               ▼
┌─────────────────────────────────────┐
│         Claude Code                 │
│    (Implement from Spec)            │
└──────────────┬──────────────────────┘
               │
               │ Generate
               ▼
┌─────────────────────────────────────┐
│      Implementation Code            │
└─────────────────────────────────────┘
```

## Why Use Specify Plus?

### Traditional Approach vs Specify Plus

**Without Specify Plus:**
```
Developer's Mind
    │
    ├─ Verbal description to AI
    │  "Build a user management system..."
    │
    ▼
Vague Requirements
    │
    ├─ AI guesses implementation
    │
    ▼
Multiple Iterations
    │
    └─ "No, that's not what I meant..."
```

**With Specify Plus:**
```
Visual Design + Structured Spec
    │
    ├─ Complete, unambiguous specification
    │
    ▼
AI Understands Exactly
    │
    ├─ Implements precisely as specified
    │
    ▼
Correct Implementation
    │
    └─ First time, minimal revisions
```

### Benefits

**1. Clarity**
```
Traditional: "Build a login system"

Specify Plus:
├─ UI: Login form with email/password fields
├─ Validation: Email format, min 8 chars password
├─ API: POST /auth/login endpoint
├─ Response: JWT token with 24hr expiry
├─ Error Handling: 401 for invalid, 429 for rate limit
└─ Security: bcrypt hashing, HTTPS only
```

**2. Consistency**
- Same spec = same implementation
- Team alignment on requirements
- No ambiguity in features

**3. Efficiency**
- Less back-and-forth with AI
- Faster development cycles
- Reduced rework

**4. Documentation**
- Spec becomes living documentation
- Always up-to-date
- Easy to onboard new team members

## Getting Started

### Installation

```bash
# Install Specify Plus CLI
npm install -g @specify/cli

# Or use the web interface
# Visit: https://specify.plus
```

### Initial Setup

```bash
# Initialize a new project
specify init my-project

# Created structure:
my-project/
├── .specify/
│   └── config.json
├── specs/
│   ├── api/
│   ├── ui/
│   └── data/
└── README.md
```

### Configuration

```json
// .specify/config.json
{
  "project": {
    "name": "my-project",
    "version": "1.0.0",
    "type": "web-application"
  },
  
  "integration": {
    "claudeCode": {
      "enabled": true,
      "autoSync": true,
      "outputPath": "./generated"
    }
  },
  
  "validation": {
    "strict": true,
    "requireExamples": true,
    "enforceTypes": true
  },
  
  "templates": {
    "api": "rest-api",
    "ui": "react",
    "database": "postgresql"
  }
}
```

## Creating Specifications

### Specification Structure

```json
// specs/user-management.spec.json
{
  "specification": {
    "id": "user-management-001",
    "name": "User Management System",
    "version": "1.0.0",
    "description": "Complete user CRUD operations with authentication"
  },
  
  "features": [
    {
      "id": "user-registration",
      "name": "User Registration",
      "priority": "high",
      "components": ["ui", "api", "database"]
    }
  ],
  
  "ui": {
    "pages": [...],
    "components": [...],
    "flows": [...]
  },
  
  "api": {
    "endpoints": [...],
    "authentication": {...},
    "validation": [...]
  },
  
  "data": {
    "models": [...],
    "relationships": [...],
    "migrations": [...]
  },
  
  "business_logic": {
    "rules": [...],
    "workflows": [...],
    "validations": [...]
  }
}
```

### Example: User Registration Spec

```json
{
  "feature": {
    "id": "user-registration",
    "name": "User Registration",
    
    "ui": {
      "page": {
        "route": "/register",
        "title": "Create Account",
        
        "form": {
          "fields": [
            {
              "name": "email",
              "type": "email",
              "label": "Email Address",
              "required": true,
              "validation": {
                "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
                "errorMessage": "Please enter a valid email address"
              },
              "placeholder": "your@email.com"
            },
            {
              "name": "password",
              "type": "password",
              "label": "Password",
              "required": true,
              "validation": {
                "minLength": 8,
                "pattern": "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]",
                "errorMessage": "Password must be at least 8 characters with uppercase, lowercase, number, and special character"
              },
              "showStrengthMeter": true
            },
            {
              "name": "confirmPassword",
              "type": "password",
              "label": "Confirm Password",
              "required": true,
              "validation": {
                "mustMatch": "password",
                "errorMessage": "Passwords must match"
              }
            },
            {
              "name": "name",
              "type": "text",
              "label": "Full Name",
              "required": true,
              "validation": {
                "minLength": 2,
                "maxLength": 50
              }
            }
          ],
          
          "submitButton": {
            "text": "Create Account",
            "loadingText": "Creating account...",
            "style": "primary"
          },
          
          "links": [
            {
              "text": "Already have an account? Sign in",
              "href": "/login"
            }
          ]
        }
      }
    },
    
    "api": {
      "endpoint": {
        "path": "/api/auth/register",
        "method": "POST",
        
        "request": {
          "body": {
            "type": "object",
            "properties": {
              "email": {
                "type": "string",
                "format": "email",
                "required": true
              },
              "password": {
                "type": "string",
                "minLength": 8,
                "required": true
              },
              "name": {
                "type": "string",
                "minLength": 2,
                "maxLength": 50,
                "required": true
              }
            }
          },
          
          "validation": {
            "library": "joi",
            "strictMode": true
          }
        },
        
        "response": {
          "success": {
            "status": 201,
            "body": {
              "type": "object",
              "properties": {
                "userId": {
                  "type": "string",
                  "format": "uuid"
                },
                "token": {
                  "type": "string",
                  "description": "JWT authentication token"
                },
                "expiresIn": {
                  "type": "number",
                  "description": "Token expiration in seconds"
                }
              }
            }
          },
          
          "errors": [
            {
              "status": 400,
              "code": "INVALID_INPUT",
              "message": "Validation failed",
              "body": {
                "errors": "array of validation errors"
              }
            },
            {
              "status": 409,
              "code": "EMAIL_EXISTS",
              "message": "Email already registered"
            },
            {
              "status": 500,
              "code": "SERVER_ERROR",
              "message": "Internal server error"
            }
          ]
        },
        
        "businessLogic": [
          "Check if email already exists in database",
          "Hash password using bcrypt with 10 rounds",
          "Create user record in database",
          "Generate JWT token with 24-hour expiry",
          "Send welcome email (async)",
          "Return user ID and token"
        ],
        
        "security": {
          "rateLimit": {
            "max": 5,
            "window": "15 minutes",
            "message": "Too many registration attempts"
          },
          "passwordHashing": "bcrypt",
          "tokenType": "JWT",
          "tokenExpiry": "24h"
        }
      }
    },
    
    "data": {
      "model": {
        "name": "User",
        "table": "users",
        
        "schema": {
          "id": {
            "type": "uuid",
            "primary": true,
            "default": "uuid_generate_v4()"
          },
          "email": {
            "type": "string",
            "unique": true,
            "index": true,
            "nullable": false
          },
          "passwordHash": {
            "type": "string",
            "nullable": false
          },
          "name": {
            "type": "string",
            "nullable": false
          },
          "createdAt": {
            "type": "timestamp",
            "default": "now()"
          },
          "updatedAt": {
            "type": "timestamp",
            "default": "now()",
            "onUpdate": "now()"
          },
          "lastLoginAt": {
            "type": "timestamp",
            "nullable": true
          },
          "isActive": {
            "type": "boolean",
            "default": true
          }
        },
        
        "indexes": [
          {
            "name": "idx_users_email",
            "columns": ["email"],
            "unique": true
          },
          {
            "name": "idx_users_created_at",
            "columns": ["createdAt"]
          }
        ]
      }
    },
    
    "tests": {
      "unit": [
        {
          "description": "should validate email format",
          "input": { "email": "invalid-email" },
          "expect": "validation error"
        },
        {
          "description": "should reject weak password",
          "input": { "password": "weak" },
          "expect": "validation error"
        }
      ],
      
      "integration": [
        {
          "description": "should create user successfully",
          "steps": [
            "POST /api/auth/register with valid data",
            "Expect 201 status",
            "Expect userId and token in response",
            "Verify user exists in database"
          ]
        },
        {
          "description": "should reject duplicate email",
          "steps": [
            "Create user with email test@example.com",
            "Attempt to create another user with same email",
            "Expect 409 status"
          ]
        }
      ]
    }
  }
}
```

### Visual Specifications

**UI Mockup Format:**
```json
{
  "ui": {
    "mockup": {
      "type": "wireframe",
      "tool": "figma",
      "url": "https://figma.com/...",
      
      "components": [
        {
          "type": "form",
          "layout": "vertical",
          "width": "400px",
          "padding": "24px",
          
          "elements": [
            {
              "type": "heading",
              "text": "Create Account",
              "level": 1
            },
            {
              "type": "input",
              "name": "email",
              "label": "Email",
              "placeholder": "your@email.com"
            },
            // ... more elements
          ]
        }
      ]
    }
  }
}
```

## Integration with Claude Code

### Basic Integration

```bash
# Export specification from Specify Plus
specify export user-management.spec.json

# Import into Claude Code
claude-code import user-management.spec.json

# Generate implementation
claude-code generate --from-spec user-management.spec.json
```

### Automatic Workflow

```yaml
# .claude-code/workflow.yml
name: spec-driven-development

trigger:
  - spec_updated

steps:
  - name: import-spec
    tool: specify-plus
    action: sync
    
  - name: generate-code
    tool: claude-code
    config:
      spec: ${spec_file}
      output: ./src
      
  - name: generate-tests
    tool: claude-code
    config:
      spec: ${spec_file}
      output: ./tests
      
  - name: validate
    tool: claude-code
    action: validate-against-spec
```

### CLI Integration

```bash
# Complete workflow
claude-code --specify user-management.spec.json \
  --output ./src \
  --tests \
  --validate

# What happens:
# 1. Reads specification
# 2. Analyzes requirements
# 3. Generates implementation
# 4. Creates tests
# 5. Validates against spec
# 6. Reports any discrepancies
```

### Programmatic Integration

```javascript
const { SpecifyPlus } = require('@specify/sdk');
const { ClaudeCode } = require('claude-code');

async function implementFromSpec(specFile) {
  // Load specification
  const spec = await SpecifyPlus.load(specFile);
  
  // Initialize Claude Code
  const claude = new ClaudeCode({
    model: 'claude-sonnet-4',
    spec: spec
  });
  
  // Generate implementation
  const implementation = await claude.generate({
    features: spec.features,
    outputPath: './src',
    includeTests: true
  });
  
  // Validate against spec
  const validation = await claude.validate(implementation, spec);
  
  if (!validation.passed) {
    console.log('Validation issues:', validation.issues);
    // Fix issues
    await claude.fix(validation.issues);
  }
  
  return implementation;
}
```

## Workflow Examples

### Example 1: Full-Stack Feature

**Step 1: Create Specification**
```bash
specify create feature user-dashboard

# Opens interactive editor
# Define:
# - UI components
# - API endpoints
# - Data models
# - Business logic
```

**Step 2: Review & Refine**
```bash
# Preview specification
specify preview user-dashboard.spec.json

# Validate completeness
specify validate user-dashboard.spec.json
```

**Step 3: Generate with Claude Code**
```bash
# Generate complete implementation
claude-code --specify user-dashboard.spec.json \
  --output ./src \
  --framework react \
  --backend express \
  --database postgresql
```

**Output Structure:**
```
src/
├── frontend/
│   ├── components/
│   │   └── UserDashboard.jsx
│   ├── hooks/
│   │   └── useUserData.js
│   └── api/
│       └── userApi.js
├── backend/
│   ├── routes/
│   │   └── dashboard.js
│   ├── controllers/
│   │   └── dashboardController.js
│   └── models/
│       └── User.js
└── database/
    └── migrations/
        └── 001_create_dashboard_tables.sql
```

### Example 2: API-First Development

**Specification:**
```json
{
  "api": {
    "name": "Product API",
    "version": "1.0.0",
    "baseUrl": "/api/v1",
    
    "endpoints": [
      {
        "path": "/products",
        "method": "GET",
        "description": "List all products",
        "pagination": true,
        "filters": ["category", "price_min", "price_max"],
        "sorting": ["name", "price", "created_at"],
        "response": {
          "type": "array",
          "items": { "$ref": "#/models/Product" }
        }
      },
      {
        "path": "/products/:id",
        "method": "GET",
        "description": "Get product by ID",
        "parameters": {
          "id": {
            "type": "uuid",
            "required": true
          }
        }
      }
      // ... more endpoints
    ],
    
    "models": {
      "Product": {
        "id": "uuid",
        "name": "string",
        "description": "string",
        "price": "decimal",
        "category": "string",
        "inStock": "boolean",
        "createdAt": "timestamp"
      }
    }
  }
}
```

**Generate:**
```bash
claude-code --specify product-api.spec.json \
  --type api-only \
  --generate-docs \
  --generate-tests
```

### Example 3: Database Schema Migration

**Specification:**
```json
{
  "migration": {
    "from": "v1.0.0",
    "to": "v2.0.0",
    
    "changes": [
      {
        "type": "add_column",
        "table": "users",
        "column": {
          "name": "phoneNumber",
          "type": "string",
          "nullable": true
        }
      },
      {
        "type": "create_table",
        "name": "user_preferences",
        "columns": {
          "id": "uuid primary key",
          "userId": "uuid references users(id)",
          "theme": "string",
          "notifications": "boolean"
        }
      }
    ],
    
    "dataTransformation": [
      {
        "description": "Migrate existing user settings",
        "sql": "INSERT INTO user_preferences..."
      }
    ],
    
    "rollback": {
      "enabled": true,
      "steps": [...]
    }
  }
}
```

**Generate Migration:**
```bash
claude-code --specify migration-v2.spec.json \
  --generate-migration \
  --with-rollback \
  --dry-run  # Preview changes first
```

## Advanced Features

### 1. Spec Templates

```bash
# Use pre-built templates
specify create --template crud-api product-api

# Creates spec with:
# - GET /items (list)
# - GET /items/:id (get one)
# - POST /items (create)
# - PUT /items/:id (update)
# - DELETE /items/:id (delete)
```

### 2. Spec Composition

```json
{
  "specification": {
    "compose": [
      { "$ref": "./specs/authentication.spec.json" },
      { "$ref": "./specs/user-management.spec.json" },
      { "$ref": "./specs/permissions.spec.json" }
    ],
    
    "overrides": {
      "api.baseUrl": "/api/v2"
    }
  }
}
```

### 3. Validation Rules

```json
{
  "validation": {
    "rules": [
      {
        "rule": "all-endpoints-have-tests",
        "severity": "error"
      },
      {
        "rule": "all-models-have-migrations",
        "severity": "error"
      },
      {
        "rule": "api-versioned",
        "severity": "warning"
      }
    ]
  }
}
```

### 4. Change Tracking

```bash
# Track specification changes
specify diff v1.0.0 v2.0.0

# Output:
# + Added endpoint: POST /products/:id/review
# ~ Modified model: Product (added field 'rating')
# - Removed endpoint: GET /legacy/products
```

## Best Practices

### 1. Start Detailed, Stay Detailed

```
❌ Bad Spec:
"Create a user system with authentication"

✅ Good Spec:
- UI: Registration form with email/password
- Validation: Email format, password strength
- API: POST /auth/register endpoint
- Security: bcrypt hashing, JWT tokens
- Database: users table with specified schema
- Tests: Unit and integration test cases
```

### 2. Include Examples

```json
{
  "endpoint": "/api/products",
  
  "examples": {
    "request": {
      "query": "?category=electronics&price_max=1000"
    },
    "response": {
      "status": 200,
      "body": {
        "products": [
          {
            "id": "123",
            "name": "Laptop",
            "price": 999.99
          }
        ]
      }
    }
  }
}
```

### 3. Version Your Specs

```json
{
  "specification": {
    "version": "2.1.0",
    "changelog": {
      "2.1.0": "Added product reviews",
      "2.0.0": "Redesigned API structure",
      "1.0.0": "Initial release"
    }
  }
}
```

### 4. Use Type Definitions

```json
{
  "types": {
    "Email": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    },
    "Price": {
      "type": "number",
      "minimum": 0,
      "decimalPlaces": 2
    }
  },
  
  "usage": {
    "field": "email",
    "type": { "$ref": "#/types/Email" }
  }
}
```

### 5. Document Business Logic

```json
{
  "businessLogic": {
    "userRegistration": {
      "steps": [
        "1. Validate input data",
        "2. Check if email exists",
        "3. Hash password (bcrypt, 10 rounds)",
        "4. Create user record",
        "5. Generate JWT token (24hr expiry)",
        "6. Send welcome email (async)",
        "7. Return user ID and token"
      ],
      
      "rules": [
        "Emails must be unique (case-insensitive)",
        "Passwords must meet complexity requirements",
        "New users are active by default",
        "Welcome email sent in background"
      ]
    }
  }
}
```

## Conclusion

Specify Plus transforms the way you work with AI by providing:

**Clear Communication**
- No ambiguity in requirements
- AI understands exactly what to build
- Reduced iterations and rework

**Better Quality**
- Comprehensive specifications
- Validated implementations
- Consistent results

**Faster Development**
- Spec once, implement correctly
- Automated code generation
- Built-in validation

**Team Alignment**
- Single source of truth
- Living documentation
- Easy onboarding

### Getting Started Checklist

- [ ] Install Specify Plus
- [ ] Create your first specification
- [ ] Integrate with Claude Code
- [ ] Generate implementation
- [ ] Validate results
- [ ] Iterate and improve

Start with simple specifications and gradually increase complexity as you become comfortable with the workflow.

---

**Next Steps:**
- [View Specify Plus Examples →](../examples/specify-plus/)
- [Learn Claude Code Basics →](what-is-claude-code.md)
- [Explore Spec-Driven Development →](../comparisons/development-paradigms.md)