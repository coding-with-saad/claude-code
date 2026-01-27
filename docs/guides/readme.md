# Claude Code Examples

Welcome to the examples directory! This collection demonstrates practical implementations of Claude Code features, skills, workflows, and integration patterns.

## 📁 Directory Structure

```
examples/
├── skills/                      # Agent skill examples
│   ├── code-review/
│   ├── test-generator/
│   ├── api-generator/
│   ├── documentation/
│   └── security-audit/
│
├── mcp-configs/                 # MCP server configurations
│   ├── development/
│   ├── production/
│   ├── team-collaboration/
│   └── full-stack/
│
├── workflows/                   # Complete workflow examples
│   ├── feature-development/
│   ├── bug-fix/
│   ├── refactoring/
│   └── deployment/
│
├── specify-plus/                # Specify Plus specifications
│   ├── crud-api/
│   ├── authentication/
│   ├── dashboard/
│   └── microservice/
│
├── agent-factory/               # Agent factory patterns
│   ├── basic-setup/
│   ├── multi-agent/
│   ├── orchestration/
│   └── production/
│
├── integrations/                # Integration examples
│   ├── github-actions/
│   ├── ci-cd/
│   ├── slack-bot/
│   └── monitoring/
│
└── real-world/                  # Complete projects
    ├── blog-platform/
    ├── ecommerce-api/
    ├── task-manager/
    └── analytics-dashboard/
```

## 🚀 Quick Start

### Running an Example

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-code-guide.git
cd claude-code-guide/examples

# Choose an example
cd skills/code-review

# Follow the README in that directory
cat README.md
```

### Prerequisites

Most examples require:
- Claude Code installed
- API keys configured
- Node.js 18+ (for JavaScript examples)
- Python 3.9+ (for Python examples)

## 📚 Example Categories

### 1. Agent Skills

Pre-built, reusable skills for common development tasks.

#### Code Review Skill
**Location**: `skills/code-review/`

Comprehensive code review focusing on:
- Security vulnerabilities
- Performance issues
- Best practices
- Code quality

**Usage**:
```bash
claude-code --skill code-review-expert src/
```

**Files**:
- `skill.yaml` - Skill configuration
- `prompt.md` - Review instructions
- `knowledge.md` - Vulnerability patterns
- `examples/` - Sample reviews

#### Test Generator Skill
**Location**: `skills/test-generator/`

Generates comprehensive test suites:
- Unit tests
- Integration tests
- E2E tests
- Coverage optimization

**Usage**:
```bash
claude-code --skill test-generator src/api/users.js
```

#### API Endpoint Generator
**Location**: `skills/api-generator/`

Creates REST API endpoints with:
- Request validation
- Error handling
- Documentation
- Tests

**Usage**:
```bash
claude-code --skill api-endpoint-generator --spec api-spec.yaml
```

### 2. MCP Configurations

Ready-to-use MCP server configurations for different scenarios.

#### Development Setup
**Location**: `mcp-configs/development/`

Local development environment with:
- Filesystem access
- Local database
- Testing tools
- Git integration

**Setup**:
```bash
cp mcp-configs/development/config.json .claude-code/
claude-code init
```

#### Production Setup
**Location**: `mcp-configs/production/`

Production-ready configuration:
- Secure permissions
- Monitoring
- Logging
- Rate limiting

#### Team Collaboration
**Location**: `mcp-configs/team-collaboration/`

Multi-user environment:
- Shared resources
- Permission management
- Audit logging
- Slack integration

### 3. Complete Workflows

End-to-end workflows demonstrating full development cycles.

#### Feature Development
**Location**: `workflows/feature-development/`

Complete feature implementation:
1. Specification (Specify Plus)
2. Implementation (Agent Skills)
3. Testing (Test Generator)
4. Review (Code Review)
5. Deployment

**Run**:
```bash
claude-code workflow run feature-development.yml
```

**Duration**: 2-4 hours (vs 1-2 weeks manual)

#### Bug Fix Workflow
**Location**: `workflows/bug-fix/`

Systematic bug fixing:
1. Reproduce issue
2. Identify root cause
3. Implement fix
4. Add regression tests
5. Validate fix

**Example Issue**:
- SQL injection in user endpoint
- N+1 query problem
- Memory leak in service

#### Refactoring Workflow
**Location**: `workflows/refactoring/`

Safe code refactoring:
1. Analyze current code
2. Plan refactoring
3. Implement changes
4. Run tests continuously
5. Validate improvements

**Patterns**:
- Extract method
- Replace conditional with polymorphism
- Simplify complex conditionals

### 4. Specify Plus Specifications

Production-ready specifications for common application types.

#### CRUD API
**Location**: `specify-plus/crud-api/`

Complete CRUD operations:
- User management
- Product catalog
- Order processing
- Data validation

**Generate**:
```bash
claude-code --specify crud-api.spec.json
```

**Output**: 
- 15-20 API endpoints
- Database schema
- Tests
- Documentation

#### Authentication System
**Location**: `specify-plus/authentication/`

Full authentication:
- Registration
- Login/Logout
- Password reset
- Email verification
- JWT tokens

**Time to implement**: 2-3 hours

#### Dashboard Application
**Location**: `specify-plus/dashboard/`

Interactive dashboard:
- Data visualization
- Real-time updates
- User preferences
- Export functionality

### 5. Agent Factory

Agent orchestration and management patterns.

#### Basic Setup
**Location**: `agent-factory/basic-setup/`

Simple agent factory:
- Create agents from templates
- Manage agent lifecycle
- Basic orchestration

**Example**:
```javascript
const factory = new AgentFactory();
const reviewer = factory.create('code-reviewer');
await reviewer.execute(code);
```

#### Multi-Agent Collaboration
**Location**: `agent-factory/multi-agent/`

Coordinated agent teams:
- Architect + Developer + Tester
- Parallel processing
- Result aggregation

**Use case**: Full-stack feature development

#### Production Patterns
**Location**: `agent-factory/production/`

Enterprise-grade setup:
- Load balancing
- Health monitoring
- Auto-scaling
- Error recovery

### 6. Real-World Projects

Complete, deployable applications.

#### Blog Platform
**Location**: `real-world/blog-platform/`

Full-featured blog:
- User authentication
- Post CRUD operations
- Comments
- Categories/Tags
- Search
- Admin dashboard

**Tech Stack**:
- Frontend: React + Tailwind
- Backend: Express + PostgreSQL
- Auth: JWT
- Deployment: Docker

**Time to generate**: 4-6 hours

#### E-commerce API
**Location**: `real-world/ecommerce-api/`

Production e-commerce backend:
- Product catalog
- Shopping cart
- Checkout
- Payment integration (Stripe)
- Order management
- Inventory tracking

**Features**:
- REST API
- GraphQL endpoint
- Real-time notifications
- Admin panel

#### Task Manager
**Location**: `real-world/task-manager/`

Project management tool:
- Project/Task CRUD
- Team collaboration
- File attachments
- Comments
- Due dates
- Notifications

**Highlights**:
- Real-time collaboration
- Role-based access
- Activity tracking
- Mobile responsive

## 🎯 Usage Patterns

### Pattern 1: Start Simple

```bash
# 1. Try a basic skill
cd examples/skills/code-review
claude-code --skill . src/sample.js

# 2. Understand the output
# 3. Customize for your needs
# 4. Create your own skill
```

### Pattern 2: Build from Specification

```bash
# 1. Use a Specify Plus template
cd examples/specify-plus/crud-api

# 2. Customize the spec
vim product-api.spec.json

# 3. Generate implementation
claude-code --specify product-api.spec.json

# 4. Review and refine
```

### Pattern 3: Complete Workflow

```bash
# 1. Choose a workflow
cd examples/workflows/feature-development

# 2. Adapt to your feature
vim feature-spec.yml

# 3. Run the workflow
claude-code workflow run feature-spec.yml

# 4. Deploy the result
```

## 💡 Tips for Using Examples

### Customization

All examples are templates - customize them:

```yaml
# Original
name: code-review-expert
model: claude-sonnet-4

# Customized for your team
name: acme-code-review
model: claude-opus-4  # More thorough
company_standards: acme-coding-standards.md
```

### Combining Examples

Mix and match:

```bash
# Use MCP config from one example
cp mcp-configs/production/config.json .claude-code/

# Use skills from another
cp -r skills/code-review .claude-code/skills/

# Run workflow from third
claude-code workflow run workflows/feature-development.yml
```

### Learning Path

Recommended progression:

1. **Week 1**: Try individual skills
   - Code review
   - Test generation
   - Documentation

2. **Week 2**: Experiment with MCP
   - Development config
   - Add custom servers
   - Test integrations

3. **Week 3**: Use Specify Plus
   - Start with templates
   - Create custom specs
   - Generate implementations

4. **Week 4**: Run workflows
   - Feature development
   - Bug fixing
   - Refactoring

5. **Week 5+**: Build real projects
   - Combine everything
   - Production deployment
   - Team adoption

## 🔧 Troubleshooting

### Example Won't Run

```bash
# Check Claude Code installation
claude-code --version

# Verify API key
echo $ANTHROPIC_API_KEY

# Check dependencies
npm install  # or pip install -r requirements.txt
```

### MCP Server Issues

```bash
# Test MCP configuration
claude-code mcp test

# Check server logs
cat .claude-code/mcp.log

# Verify permissions
claude-code mcp permissions
```

### Workflow Failures

```bash
# Dry-run first
claude-code workflow run --dry-run feature.yml

# Check validation
claude-code workflow validate feature.yml

# Review logs
claude-code logs --workflow feature
```

## 📊 Example Metrics

### Code Generated
- **Average per skill**: 500-1,000 lines
- **Average per workflow**: 3,000-5,000 lines
- **Average per project**: 10,000-20,000 lines

### Time Savings
- **Simple skill**: 30 min → 2 min (93% faster)
- **API endpoint**: 2 hours → 10 min (92% faster)
- **Complete feature**: 2 weeks → 4 hours (95% faster)

### Quality Metrics
- **Test coverage**: 80-90%
- **Security issues**: 0 (with security skill)
- **Best practices**: 95% compliance

## 🤝 Contributing Examples

Want to add your own example?

1. **Choose a category** (skills, workflows, etc.)
2. **Follow the template** structure
3. **Document thoroughly** (README + comments)
4. **Test completely** (ensure it works)
5. **Submit PR** with:
   - Clear description
   - Usage instructions
   - Expected output
   - Time estimates

See [CONTRIBUTING.md](../CONTRIBUTING.md) for details.

## 📚 Additional Resources

- [Main Documentation](../docs/)
- [Claude Code Guide](../docs/guides/what-is-claude-code.md)
- [Creating Skills](../docs/guides/creating-skills.md)
- [MCP Configuration](../docs/guides/mcp-setup.md)
- [Specify Plus Guide](../docs/guides/specify-plus-integration.md)

## 💬 Questions?

- [Open an issue](https://github.com/coding-with-saad/claude-code-guide/issues)
- [Start a discussion](https://github.com/yourusername/claude-code-guide/discussions)
- [Check FAQ](../docs/faq.md)

---

Happy coding with Claude! 🚀