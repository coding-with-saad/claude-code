# Creating Skills in Claude Code

## Overview

Skills are reusable, composable capabilities that extend Claude Code's functionality. They allow you to codify workflows, domain knowledge, and best practices into shareable components.

## Table of Contents
- [What are Skills?](#what-are-skills)
- [Skill Anatomy](#skill-anatomy)
- [Creating Your First Skill](#creating-your-first-skill)
- [Skill Types](#skill-types)
- [Advanced Patterns](#advanced-patterns)
- [Best Practices](#best-practices)
- [Skill Examples](#skill-examples)
- [Publishing Skills](#publishing-skills)

## What are Skills?

### Definition

A **skill** is a packaged capability that combines:
- **Instructions**: How to perform a specific task
- **Tools**: What tools are available
- **Knowledge**: Domain-specific information
- **Examples**: Reference implementations
- **Validation**: Success criteria

### Why Use Skills?

```
Without Skills:                With Skills:
┌──────────────────┐          ┌──────────────────┐
│ Every time you   │          │ Define once,     │
│ need to:         │          │ use everywhere:  │
│                  │          │                  │
│ • Explain task   │          │ claude-code      │
│ • Provide context│          │   --skill        │
│ • Specify format │          │   code-review    │
│ • Give examples  │          │                  │
│                  │          │ Done! ✓          │
└──────────────────┘          └──────────────────┘
   Manual, repetitive            Automated, consistent
```

### Benefits

1. **Reusability** - Define once, use many times
2. **Consistency** - Same quality every time
3. **Shareability** - Team/community sharing
4. **Composability** - Combine multiple skills
5. **Maintainability** - Update in one place
6. **Scalability** - Build libraries of capabilities

## Skill Anatomy

### Basic Structure

```javascript
// skills/my-skill/skill.json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "Brief description of what this skill does",
  
  "prompt": "skills/my-skill/prompt.md",
  "tools": ["tool1", "tool2"],
  "examples": "skills/my-skill/examples/",
  "knowledge": "skills/my-skill/knowledge.md",
  
  "config": {
    "model": "claude-sonnet-4",
    "temperature": 0.3,
    "max_tokens": 4000
  },
  
  "metadata": {
    "author": "Your Name",
    "tags": ["category", "type"],
    "license": "MIT"
  }
}
```

### File Structure

```
skills/
└── my-skill/
    ├── skill.json          # Skill configuration
    ├── prompt.md           # Main instructions
    ├── knowledge.md        # Domain knowledge
    ├── examples/           # Example usage
    │   ├── example1.md
    │   └── example2.md
    ├── tools/              # Custom tools (optional)
    │   └── custom-tool.js
    └── tests/              # Skill tests (optional)
        └── test-skill.js
```

### Components Explained

**1. skill.json** - Metadata and configuration
```json
{
  "name": "code-reviewer",
  "version": "1.0.0",
  "description": "Reviews code for bugs, security issues, and best practices",
  "prompt": "prompt.md",
  "tools": ["file_read", "file_write", "run_tests"],
  "config": {
    "model": "claude-sonnet-4"
  }
}
```

**2. prompt.md** - Core instructions
```markdown
# Code Review Skill

You are an expert code reviewer. When reviewing code:

1. Check for bugs and logic errors
2. Identify security vulnerabilities
3. Ensure code follows best practices
4. Verify proper error handling
5. Check for performance issues

Output format:
- List of issues found
- Severity (Critical/High/Medium/Low)
- Suggested fixes
- Overall assessment
```

**3. knowledge.md** - Domain expertise
```markdown
# Code Review Knowledge Base

## Common Patterns to Flag

### SQL Injection
Look for direct string concatenation in SQL queries:
```javascript
// ❌ Vulnerable
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ Safe
const query = 'SELECT * FROM users WHERE id = ?';
```

### XSS Vulnerabilities
Check for unescaped user input in HTML...
```

**4. examples/** - Reference implementations
```markdown
# Example 1: Basic Function Review

Input:
```javascript
function calculateTotal(items) {
  let total = 0;
  for (let i = 0; i < items.length; i++) {
    total += items[i].price;
  }
  return total;
}
```

Expected Output:
✓ Logic is correct
⚠ Missing null/undefined check for items
⚠ Missing type validation for price
✓ Good variable naming
```

## Creating Your First Skill

### Step 1: Initialize

```bash
# Create new skill
claude-code skill create my-first-skill

# This creates the structure
skills/my-first-skill/
  ├── skill.json
  ├── prompt.md
  └── knowledge.md
```

### Step 2: Define the Skill

**skill.json**
```json
{
  "name": "api-endpoint-generator",
  "version": "1.0.0",
  "description": "Generates RESTful API endpoints with validation, error handling, and tests",
  "prompt": "prompt.md",
  "tools": ["file_write", "run_command"],
  "examples": "examples/",
  "config": {
    "model": "claude-sonnet-4",
    "temperature": 0.3
  }
}
```

**prompt.md**
```markdown
# API Endpoint Generator

You are an expert at creating RESTful API endpoints. When asked to create an endpoint:

## Steps:
1. Analyze the request requirements
2. Design the endpoint structure (route, method, parameters)
3. Implement request validation using joi
4. Add proper error handling
5. Create response formatting
6. Write unit tests
7. Update API documentation

## Requirements:
- Follow REST conventions (GET, POST, PUT, DELETE)
- Use appropriate HTTP status codes
- Implement input validation
- Add comprehensive error handling
- Include request/response examples in docs
- Write tests covering happy path and error cases

## Code Style:
- Use async/await for asynchronous operations
- Consistent naming conventions
- Clear error messages
- Proper logging

## Output:
1. Endpoint implementation file
2. Validation schema
3. Test file
4. Documentation update
```

### Step 3: Add Knowledge

**knowledge.md**
```markdown
# API Development Best Practices

## HTTP Status Codes
- 200 OK - Successful GET/PUT
- 201 Created - Successful POST
- 204 No Content - Successful DELETE
- 400 Bad Request - Invalid input
- 401 Unauthorized - Authentication required
- 403 Forbidden - No permission
- 404 Not Found - Resource doesn't exist
- 500 Internal Server Error - Server error

## Validation Patterns

### Using Joi
```javascript
const Joi = require('joi');

const userSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  name: Joi.string().min(2).max(50)
});
```

## Error Handling Pattern
```javascript
try {
  const result = await operation();
  res.json({ success: true, data: result });
} catch (error) {
  logger.error('Operation failed:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
}
```
```

### Step 4: Add Examples

**examples/get-endpoint.md**
```markdown
# Example: GET Endpoint

Request:
"Create a GET endpoint to fetch user by ID"

Implementation:
```javascript
// routes/users.js
router.get('/users/:id', async (req, res) => {
  const { id } = req.params;
  
  // Validate ID
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid user ID format'
    });
  }
  
  try {
    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error(`Error fetching user ${id}:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user'
    });
  }
});
```

Test:
```javascript
describe('GET /users/:id', () => {
  it('should return user when valid ID provided', async () => {
    const user = await createTestUser();
    const res = await request(app)
      .get(`/users/${user._id}`)
      .expect(200);
    
    expect(res.body.success).toBe(true);
    expect(res.body.data._id).toBe(user._id.toString());
  });
  
  it('should return 400 for invalid ID format', async () => {
    const res = await request(app)
      .get('/users/invalid-id')
      .expect(400);
    
    expect(res.body.success).toBe(false);
  });
});
```
```

### Step 5: Test the Skill

```bash
# Use the skill
claude-code --skill api-endpoint-generator "Create a POST endpoint for user registration"

# Test with different inputs
claude-code --skill api-endpoint-generator "Create a DELETE endpoint for removing posts"
```

### Step 6: Refine

Based on results:
1. Update prompt.md for clarity
2. Add more examples
3. Enhance knowledge base
4. Adjust configuration

## Skill Types

### 1. Code Generation Skills

**Purpose**: Generate boilerplate, components, or features

```json
{
  "name": "react-component-generator",
  "description": "Generates React components with TypeScript, tests, and stories",
  "tools": ["file_write"],
  "outputs": [
    "Component.tsx",
    "Component.test.tsx",
    "Component.stories.tsx"
  ]
}
```

### 2. Analysis Skills

**Purpose**: Review, audit, or analyze code

```json
{
  "name": "security-auditor",
  "description": "Analyzes code for security vulnerabilities",
  "tools": ["file_read", "pattern_match"],
  "outputs": [
    "security-report.md"
  ]
}
```

### 3. Transformation Skills

**Purpose**: Refactor, migrate, or convert code

```json
{
  "name": "class-to-functional-converter",
  "description": "Converts React class components to functional components with hooks",
  "tools": ["file_read", "file_write"],
  "validates": "Tests still pass"
}
```

### 4. Documentation Skills

**Purpose**: Generate or update documentation

```json
{
  "name": "api-doc-generator",
  "description": "Generates OpenAPI/Swagger documentation from code",
  "tools": ["file_read", "file_write"],
  "outputs": [
    "openapi.yaml"
  ]
}
```

### 5. Testing Skills

**Purpose**: Create or improve tests

```json
{
  "name": "test-generator",
  "description": "Generates comprehensive unit tests",
  "tools": ["file_read", "file_write", "run_tests"],
  "coverage_target": "80%"
}
```

### 6. Workflow Skills

**Purpose**: Execute multi-step processes

```json
{
  "name": "feature-complete",
  "description": "Implements feature from spec to deployment",
  "sub_skills": [
    "design-system",
    "implement-code",
    "write-tests",
    "update-docs",
    "create-pr"
  ]
}
```

## Advanced Patterns

### 1. Skill Composition

Combine multiple skills:

```json
{
  "name": "full-feature-pipeline",
  "type": "composite",
  "skills": [
    {
      "name": "architect",
      "skill": "system-designer"
    },
    {
      "name": "implement",
      "skill": "code-generator",
      "depends_on": ["architect"]
    },
    {
      "name": "test",
      "skill": "test-generator",
      "depends_on": ["implement"]
    },
    {
      "name": "document",
      "skill": "doc-generator",
      "depends_on": ["implement"]
    }
  ]
}
```

### 2. Conditional Execution

Skills that adapt based on context:

```javascript
// In prompt.md
If the project uses TypeScript:
  - Generate .tsx files
  - Add type definitions
  - Use TypeScript testing patterns

If the project uses JavaScript:
  - Generate .jsx files
  - Use JSDoc comments
  - Use JavaScript testing patterns
```

### 3. Template-Based Skills

Use templates for consistency:

```
skills/component-generator/
  ├── skill.json
  ├── prompt.md
  └── templates/
      ├── component.template.tsx
      ├── test.template.tsx
      └── story.template.tsx
```

```javascript
// component.template.tsx
import React from 'react';

interface {{ComponentName}}Props {
  {{#each props}}
  {{name}}: {{type}};
  {{/each}}
}

export const {{ComponentName}}: React.FC<{{ComponentName}}Props> = ({
  {{#each props}}
  {{name}},
  {{/each}}
}) => {
  return (
    <div className="{{kebabCase componentName}}">
      {/* Component implementation */}
    </div>
  );
};
```

### 4. Interactive Skills

Skills that prompt for input:

```markdown
# Interactive Configuration

Before starting, gather:
1. Feature name: [prompt user]
2. Database tables needed: [prompt user]
3. API endpoints required: [prompt user]
4. Authentication type: [prompt user with options]

Then proceed with implementation using gathered info.
```

### 5. Context-Aware Skills

Skills that adapt to project:

```markdown
# Context Analysis

First, analyze the project:
- What framework is used? (React/Vue/Angular)
- What testing library? (Jest/Vitest/Mocha)
- What styling approach? (CSS/SCSS/Tailwind/Styled-components)
- What state management? (Redux/Zustand/Context)

Then generate code matching the existing patterns.
```

## Best Practices

### 1. Clear Naming
```bash
# ✅ Good - descriptive, specific
api-endpoint-generator
react-component-creator
security-vulnerability-scanner

# ❌ Bad - vague, generic
helper
tool
utility
```

### 2. Single Responsibility
```bash
# ✅ Good - one clear purpose
database-migration-creator
unit-test-generator
api-documentation-updater

# ❌ Bad - too broad
full-stack-developer
everything-doer
```

### 3. Detailed Prompts
```markdown
# ✅ Good - specific instructions
When creating a React component:
1. Use functional components with hooks
2. Implement TypeScript interfaces for props
3. Add PropTypes for runtime validation
4. Include comprehensive JSDoc comments
5. Create stories for Storybook
6. Write unit tests with React Testing Library
7. Ensure accessibility (ARIA labels, keyboard navigation)

# ❌ Bad - vague
Create a React component with best practices.
```

### 4. Comprehensive Examples
```markdown
# Include multiple examples showing:
- Basic usage
- Edge cases
- Error scenarios
- Integration patterns
- Real-world applications
```

### 5. Validation Criteria
```json
{
  "validation": {
    "required_files": ["component.tsx", "component.test.tsx"],
    "tests_must_pass": true,
    "linting_must_pass": true,
    "coverage_minimum": 80
  }
}
```

### 6. Version Control
```json
{
  "version": "1.2.0",
  "changelog": {
    "1.2.0": "Added TypeScript support",
    "1.1.0": "Improved error handling",
    "1.0.0": "Initial release"
  }
}
```

## Skill Examples

### Example 1: Database Migration Skill

```javascript
// skills/db-migration/skill.json
{
  "name": "database-migration",
  "version": "1.0.0",
  "description": "Creates database migrations with rollback support",
  "prompt": "prompt.md",
  "tools": ["file_write", "run_command"],
  "config": {
    "model": "claude-sonnet-4"
  }
}
```

```markdown
<!-- skills/db-migration/prompt.md -->
# Database Migration Generator

When creating a database migration:

1. **Analyze Requirements**
   - What tables/columns are being modified?
   - What data type changes are needed?
   - Are there foreign key relationships?

2. **Create Migration File**
   - Timestamp-based filename
   - Clear up() and down() functions
   - Proper data type definitions
   - Index creation where appropriate

3. **Add Validation**
   - Check for existing columns before adding
   - Verify foreign key constraints
   - Handle existing data appropriately

4. **Create Rollback**
   - down() function reverses all changes
   - Data preservation strategy
   - Clear rollback instructions

## Template

```javascript
// migrations/YYYYMMDD_HHMMSS_description.js
exports.up = async (knex) => {
  // Forward migration
};

exports.down = async (knex) => {
  // Rollback migration
};
```
```

### Example 2: Code Review Skill

```json
{
  "name": "code-review-expert",
  "version": "2.0.0",
  "description": "Comprehensive code review with company standards",
  "prompt": "prompt.md",
  "knowledge": "knowledge.md",
  "tools": ["file_read", "pattern_match"],
  "config": {
    "model": "claude-sonnet-4",
    "temperature": 0.2
  }
}
```

### Example 3: Test Generator Skill

```json
{
  "name": "comprehensive-test-generator",
  "version": "1.5.0",
  "description": "Generates unit, integration, and e2e tests",
  "prompt": "prompt.md",
  "tools": ["file_read", "file_write", "run_tests"],
  "examples": "examples/",
  "config": {
    "coverage_target": 90
  }
}
```

## Publishing Skills

### 1. Package Your Skill

```bash
# Create distributable package
claude-code skill package my-skill

# Creates: my-skill-1.0.0.tgz
```

### 2. Share with Team

```bash
# Add to team registry
claude-code skill publish my-skill --registry company-registry

# Install from registry
claude-code skill install my-skill --registry company-registry
```

### 3. Public Registry

```bash
# Publish to public registry
claude-code skill publish my-skill --public

# Others can install
claude-code skill install @username/my-skill
```

### 4. GitHub Distribution

```bash
# Install from GitHub
claude-code skill install github:username/skill-repo

# With specific version/branch
claude-code skill install github:username/skill-repo#v1.0.0
```

## Conclusion

Skills are powerful tools for:
- **Codifying expertise** into reusable components
- **Ensuring consistency** across projects and teams
- **Accelerating development** through automation
- **Sharing knowledge** within and across organizations

Start simple, iterate based on usage, and build a library of skills that match your workflow.

---

**Next Steps:**
- [View Skill Examples →](../examples/skills/)
- [Learn about MCP Integration →](model-context-protocol.md)
- [Explore Agent Factory →](what-is-agent-factory.md)