# Model Context Protocol (MCP) vs Agent Skills

## Overview

Understanding the difference between Model Context Protocol (MCP) and Agent Skills is essential for building effective AI agent systems. While both extend agent capabilities, they serve different purposes and operate at different levels.

## Table of Contents
- [Quick Comparison](#quick-comparison)
- [What is MCP?](#what-is-mcp)
- [What are Agent Skills?](#what-are-agent-skills)
- [Key Differences](#key-differences)
- [When to Use Each](#when-to-use-each)
- [Integration Patterns](#integration-patterns)
- [Implementation Examples](#implementation-examples)
- [Best Practices](#best-practices)

## Quick Comparison

| Aspect | MCP (Model Context Protocol) | Agent Skills |
|--------|------------------------------|--------------|
| **Level** | Infrastructure/Protocol | Application/Workflow |
| **Purpose** | Connect to data sources & tools | Define task execution patterns |
| **Scope** | System-wide capabilities | Task-specific behaviors |
| **Reusability** | Across all agents | Per agent or shared |
| **Configuration** | Server-based | Prompt/config-based |
| **Examples** | File access, DB queries, APIs | Code review, test generation |
| **Analogy** | Operating system drivers | Application software |
| **Standardization** | Protocol standard | Custom implementation |
| **Complexity** | Higher (server setup) | Lower (config files) |
| **Flexibility** | Limited by protocol | Highly customizable |

## What is MCP?

### Definition

**Model Context Protocol (MCP)** is a standardized protocol that allows AI models to connect to external data sources, tools, and services in a secure and controlled manner.

### Core Concept

MCP acts as a **universal connector** between AI models and the outside world, similar to how USB provides a standard interface for hardware devices.

```
┌──────────────┐
│   AI Model   │
│   (Claude)   │
└──────┬───────┘
       │
       │ MCP Protocol
       │
┌──────▼───────────────────────────────┐
│        MCP Server Layer              │
├──────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐       │
│  │ File │  │  DB  │  │ API  │  ...  │
│  │Server│  │Server│  │Server│       │
│  └──────┘  └──────┘  └──────┘       │
└──────┬───────┬───────┬───────────────┘
       │       │       │
┌──────▼──┐ ┌──▼──┐ ┌─▼────┐
│   Files │ │ DB  │ │ APIs │
└─────────┘ └─────┘ └──────┘
```

### Key Features

**1. Standardized Interface**
- Uniform way to access different resources
- Consistent API across all MCP servers
- Language and platform agnostic

**2. Security & Permissions**
- Fine-grained access control
- Sandboxed execution
- Audit logging

**3. Resource Discovery**
- Models can discover available tools
- Automatic capability detection
- Dynamic resource listing

**4. Stateful Connections**
- Maintain context across requests
- Session management
- Transaction support

### MCP Server Examples

**File System Server**
```json
{
  "name": "filesystem",
  "version": "1.0.0",
  "capabilities": [
    "read_file",
    "write_file",
    "list_directory",
    "search_files"
  ],
  "config": {
    "root_path": "/workspace",
    "allowed_extensions": [".js", ".ts", ".py", ".md"],
    "max_file_size": "10MB"
  }
}
```

**Database Server**
```json
{
  "name": "postgresql",
  "version": "1.0.0",
  "capabilities": [
    "query",
    "execute",
    "schema_info"
  ],
  "config": {
    "host": "localhost",
    "database": "myapp",
    "read_only": false
  }
}
```

**API Integration Server**
```json
{
  "name": "slack-api",
  "version": "1.0.0",
  "capabilities": [
    "send_message",
    "list_channels",
    "upload_file"
  ],
  "config": {
    "workspace": "mycompany",
    "bot_token": "xoxb-..."
  }
}
```

### How MCP Works

```
┌─────────────────────────────────────────┐
│ User: "Analyze sales data from Q4"      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ AI Model (Claude)                       │
│ 1. Understands task needs data          │
│ 2. Discovers available MCP servers      │
│ 3. Requests database server capability  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ MCP Database Server                     │
│ 1. Receives query request               │
│ 2. Validates permissions                │
│ 3. Executes query                       │
│ 4. Returns results                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ AI Model                                │
│ 1. Receives data                        │
│ 2. Analyzes Q4 sales                    │
│ 3. Generates insights                   │
└──────────────┬──────────────────────────┘
               │
               ▼
         Report to User
```

## What are Agent Skills?

### Definition

**Agent Skills** are pre-configured workflows or behavioral patterns that define how an agent should approach specific types of tasks.

### Core Concept

Skills are **behavioral templates** that encode domain expertise, best practices, and task-specific instructions.

```
┌──────────────────────────────────────┐
│         AI Agent                     │
│                                      │
│  ┌─────────────────────────────┐    │
│  │ Skill: Code Review          │    │
│  │ - Check for bugs            │    │
│  │ - Verify best practices     │    │
│  │ - Security analysis         │    │
│  │ - Performance review        │    │
│  └─────────────────────────────┘    │
│                                      │
│  ┌─────────────────────────────┐    │
│  │ Skill: Test Generation      │    │
│  │ - Analyze function          │    │
│  │ - Create test cases         │    │
│  │ - Add edge cases            │    │
│  │ - Verify coverage           │    │
│  └─────────────────────────────┘    │
└──────────────────────────────────────┘
```

### Key Features

**1. Task-Specific Behavior**
- Tailored approach for specific tasks
- Domain knowledge embedded
- Best practices codified

**2. Reusable Workflows**
- Save and share patterns
- Consistent execution
- Team standardization

**3. Composability**
- Combine multiple skills
- Chain skills together
- Build complex workflows

**4. Customization**
- Project-specific adaptations
- Company standards
- Personal preferences

### Agent Skill Examples

**Code Review Skill**
```yaml
name: code-review-expert
description: Comprehensive code review with best practices

prompt: |
  You are an expert code reviewer. For each file:
  
  1. Check for bugs and logic errors
  2. Identify security vulnerabilities
  3. Verify error handling
  4. Check performance issues
  5. Ensure code readability
  6. Verify test coverage
  
  Output:
  - Issue severity (Critical/High/Medium/Low)
  - Specific line numbers
  - Explanation of issue
  - Suggested fix
  - Overall assessment

tools:
  - file_read
  - pattern_match
  - run_tests

knowledge_base: |
  Common vulnerabilities:
  - SQL injection
  - XSS attacks
  - CSRF
  - Insecure authentication
```

**API Endpoint Generator Skill**
```yaml
name: api-endpoint-generator
description: Creates RESTful API endpoints with validation and tests

prompt: |
  Create a complete API endpoint including:
  
  1. Route handler with proper HTTP method
  2. Input validation using Joi
  3. Error handling
  4. Response formatting
  5. Unit tests
  6. API documentation
  
  Follow REST conventions:
  - GET for retrieval
  - POST for creation
  - PUT for updates
  - DELETE for removal
  
  Use proper status codes:
  - 200 OK
  - 201 Created
  - 400 Bad Request
  - 404 Not Found
  - 500 Server Error

examples:
  - example1.md
  - example2.md
```

## Key Differences

### 1. Purpose & Scope

**MCP (Infrastructure):**
```
Purpose: Provide ACCESS to resources
Scope: System-wide tool connectivity

Example:
- Connect to file system
- Query database
- Call external API
- Access environment variables
```

**Agent Skills (Application):**
```
Purpose: Define HOW to use resources
Scope: Task-specific workflows

Example:
- How to review code
- How to generate tests
- How to refactor
- How to document
```

### 2. Level of Abstraction

```
High Level (Application)
    │
    ├─── Agent Skills
    │    └─ "Review this code for security issues"
    │
    ├─── Agent Logic
    │    └─ Decides what to check
    │
    ├─── MCP Protocol
    │    └─ Provides file access
    │
    ├─── MCP Servers
    │    └─ Read files, execute commands
    │
Low Level (Infrastructure)
```

### 3. Configuration vs Programming

**MCP: Configuration**
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["--root", "/workspace"]
    },
    "database": {
      "command": "mcp-server-postgres",
      "args": ["--connection", "postgresql://..."]
    }
  }
}
```

**Skills: Behavioral Programming**
```markdown
# Skill Prompt
When reviewing code:
1. First, understand the context
2. Then, analyze each function
3. Check for common patterns
4. Suggest improvements
5. Provide examples
```

### 4. Usage Pattern

**Using MCP:**
```
Agent needs to read a file
    ↓
Calls MCP filesystem server
    ↓
MCP server reads file
    ↓
Returns content to agent
    ↓
Agent processes content
```

**Using Skills:**
```
User requests code review
    ↓
Agent loads code-review skill
    ↓
Follows skill's workflow
    ↓
Uses MCP to access files (if needed)
    ↓
Applies skill's review patterns
    ↓
Returns formatted review
```

## When to Use Each

### Use MCP When You Need To:

✅ **Access External Resources**
- Read/write files
- Query databases
- Call APIs
- Execute system commands

✅ **Standardize Tool Access**
- Multiple agents need same tools
- Consistent security model
- Centralized configuration

✅ **Build Infrastructure**
- Platform-level capabilities
- Cross-project functionality
- Reusable connectors

### Use Agent Skills When You Need To:

✅ **Define Workflows**
- How to review code
- How to generate tests
- How to document APIs

✅ **Encode Expertise**
- Domain knowledge
- Best practices
- Company standards

✅ **Create Reusable Behaviors**
- Consistent task execution
- Shareable patterns
- Team standardization

### Use Both Together:

✅ **Complete Agent Systems**
- MCP provides the "what" (capabilities)
- Skills provide the "how" (workflows)

```
Example: Code Review System

MCP Provides:
├─ File system access
├─ Git operations
├─ Test execution
└─ Linting tools

Skills Define:
├─ Review workflow
├─ Quality criteria
├─ Output format
└─ Best practices
```

## Integration Patterns

### Pattern 1: Skills Using MCP

Skills leverage MCP servers for resource access:

```javascript
// Code Review Skill
{
  "name": "code-review",
  "uses_mcp": [
    "filesystem",  // Read code files
    "git",         // Get file history
    "testing"      // Run tests
  ],
  "workflow": [
    "1. Use filesystem MCP to read changed files",
    "2. Use git MCP to see file history",
    "3. Analyze code against patterns",
    "4. Use testing MCP to verify tests exist",
    "5. Generate review report"
  ]
}
```

### Pattern 2: MCP-Agnostic Skills

Skills that work without MCP:

```javascript
// Pure Logic Skill
{
  "name": "algorithm-optimizer",
  "uses_mcp": [],
  "workflow": [
    "1. Analyze algorithm complexity",
    "2. Suggest optimizations",
    "3. Provide alternative approaches"
  ]
}
```

### Pattern 3: Skill Orchestration

Skills that coordinate MCP usage:

```javascript
// Deployment Skill
{
  "name": "deploy-to-production",
  "uses_mcp": [
    "filesystem",
    "docker",
    "kubernetes",
    "slack"
  ],
  "workflow": [
    "1. Use filesystem to build app",
    "2. Use docker MCP to create image",
    "3. Use kubernetes MCP to deploy",
    "4. Use slack MCP to notify team"
  ]
}
```

### Pattern 4: Layered Architecture

```
┌────────────────────────────────┐
│      User Interface            │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│    Agent Skills Layer          │
│  (What workflow to follow)     │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│    Agent Logic Layer           │
│  (Decision making)             │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│    MCP Protocol Layer          │
│  (Standardized access)         │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│    MCP Servers                 │
│  (Actual tool execution)       │
└───────────┬────────────────────┘
            │
┌───────────▼────────────────────┐
│    External Resources          │
│  (Files, DBs, APIs, etc)       │
└────────────────────────────────┘
```

## Implementation Examples

### Example 1: Building a Code Review System

**Step 1: Set up MCP Servers**

```json
// .claude-code/mcp-config.json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["--root", "./src"]
    },
    "git": {
      "command": "mcp-server-git"
    },
    "testing": {
      "command": "mcp-server-jest"
    }
  }
}
```

**Step 2: Create Code Review Skill**

```yaml
# skills/code-review/skill.yaml
name: comprehensive-code-review
version: 1.0.0

mcp_dependencies:
  - filesystem
  - git
  - testing

prompt: |
  Comprehensive code review process:
  
  1. Use filesystem MCP to read all changed files
  2. Use git MCP to understand the context of changes
  3. Analyze each file for:
     - Logic errors
     - Security vulnerabilities
     - Performance issues
     - Code style
     - Test coverage
  4. Use testing MCP to run tests
  5. Generate detailed review report
  
  For each issue found:
  - Severity level
  - File and line number
  - Description
  - Suggested fix
  - Code example

output_format: |
  # Code Review Report
  
  ## Summary
  - Files reviewed: X
  - Issues found: Y
  - Critical: N
  - Tests passing: Yes/No
  
  ## Detailed Findings
  [List of issues with severity and fixes]
  
  ## Recommendations
  [Overall suggestions]
```

**Step 3: Use the System**

```bash
# Run code review
claude-code --skill comprehensive-code-review

# The agent:
# 1. Loads the skill
# 2. Uses MCP filesystem to read files
# 3. Uses MCP git to get changes
# 4. Applies skill's review logic
# 5. Uses MCP testing to run tests
# 6. Generates report per skill format
```

### Example 2: Database Migration System

**MCP Setup:**
```json
{
  "mcpServers": {
    "database": {
      "command": "mcp-server-postgres",
      "args": ["--connection", "postgresql://localhost/mydb"]
    },
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["--root", "./migrations"]
    }
  }
}
```

**Migration Skill:**
```yaml
name: database-migration-creator
version: 1.0.0

mcp_dependencies:
  - database
  - filesystem

workflow: |
  1. Use database MCP to analyze current schema
  2. Understand the requested changes
  3. Generate migration file
  4. Use filesystem MCP to save migration
  5. Create rollback migration
  6. Generate migration documentation

validation: |
  - Migration has both up() and down()
  - Changes are reversible
  - No data loss in down()
  - Follows naming convention
```

## Best Practices

### For MCP

**1. Security First**
```json
{
  "filesystem": {
    "allowed_paths": ["/workspace/src"],
    "forbidden_paths": ["/workspace/.env"],
    "read_only": false
  }
}
```

**2. Resource Limits**
```json
{
  "database": {
    "max_query_time": "30s",
    "max_results": 1000,
    "connection_pool": 5
  }
}
```

**3. Error Handling**
```javascript
// MCP Server should handle errors gracefully
try {
  const result = await executeQuery(query);
  return { success: true, data: result };
} catch (error) {
  return {
    success: false,
    error: error.message,
    code: "QUERY_FAILED"
  };
}
```

### For Agent Skills

**1. Clear Instructions**
```markdown
# Good
"Check each function for null pointer errors"

# Bad
"Review the code"
```

**2. Modular Skills**
```yaml
# Good - focused skill
name: sql-injection-checker

# Bad - too broad
name: check-everything
```

**3. Composable Design**
```yaml
# Skills can be combined
workflow:
  - skill: code-review
  - skill: security-audit
  - skill: performance-analysis
```

**4. Examples and Knowledge**
```yaml
examples:
  - good_pattern_1.md
  - bad_pattern_1.md
  - edge_case_1.md

knowledge_base: |
  Common vulnerabilities:
  [Detailed explanations]
```

## Common Patterns

### Pattern 1: Read-Analyze-Report

```
Skill defines: What to analyze and how to report
MCP provides: Access to read resources

Flow:
User Request → Skill → MCP (read) → Skill (analyze) → Report
```

### Pattern 2: Generate-Validate-Save

```
Skill defines: What to generate and validation rules
MCP provides: Save capability

Flow:
User Request → Skill (generate) → Skill (validate) → MCP (save)
```

### Pattern 3: Multi-Step Workflow

```
Skill defines: Complete workflow
MCP provides: Tools for each step

Flow:
Skill Step 1 → MCP Tool A →
Skill Step 2 → MCP Tool B →
Skill Step 3 → MCP Tool C → Result
```

## Conclusion

### Key Takeaways

**MCP:**
- Infrastructure layer
- Provides capabilities
- Standardized access
- Platform-level

**Agent Skills:**
- Application layer
- Defines workflows
- Task-specific
- Behavioral patterns

**Together:**
- MCP = The tools
- Skills = How to use the tools
- Complete agent system

### Choosing Your Approach

| Need | Use MCP | Use Skills | Use Both |
|------|---------|------------|----------|
| Access files | ✅ | - | - |
| Define workflow | - | ✅ | - |
| Complete automation | - | - | ✅ |
| Standardize tools | ✅ | - | - |
| Encode expertise | - | ✅ | - |
| Build agent system | - | - | ✅ |

### The Future

Modern AI agent systems increasingly use both:
- **MCP** for standardized, secure tool access
- **Skills** for domain expertise and workflows
- **Integration** creates powerful, capable agents

Build your agent systems with this layered approach for maximum flexibility and capability.

---

**Next Steps:**
- [Learn about Manual Prompting vs Agent Skills →](prompting-approaches.md)
- [Explore LLM Router →](../guides/using-llm-router.md)
- [View Implementation Examples →](../examples/)