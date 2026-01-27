# Using the LLM Router in Claude Code

## Overview

The LLM Router in Claude Code allows you to use multiple AI models from different providers, automatically selecting the best model for each task based on your configuration and requirements.

## Table of Contents
- [What is the LLM Router?](#what-is-the-llm-router)
- [Supported Providers](#supported-providers)
- [Configuration](#configuration)
- [Routing Strategies](#routing-strategies)
- [Usage Examples](#usage-examples)
- [Cost Optimization](#cost-optimization)
- [Performance Tuning](#performance-tuning)
- [Best Practices](#best-practices)

## What is the LLM Router?

### Definition

The **LLM Router** is a intelligent routing layer that:
- Manages multiple LLM providers
- Selects optimal models for tasks
- Handles failover and retries
- Optimizes for cost and performance
- Provides unified interface

### Architecture

```
┌──────────────────────────────────────┐
│         Claude Code CLI              │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│         LLM Router                   │
│  ┌────────────────────────────┐     │
│  │  Route Selection Logic     │     │
│  │  • Task analysis           │     │
│  │  • Model capabilities      │     │
│  │  • Cost consideration      │     │
│  │  • Performance metrics     │     │
│  └────────────────────────────┘     │
└──────────────┬───────────────────────┘
               │
    ┌──────────┼──────────┬──────────┐
    │          │          │          │
┌───▼────┐ ┌──▼────┐ ┌──▼────┐ ┌───▼────┐
│Claude  │ │ GPT-4 │ │Gemini │ │ Local  │
│(Anthro │ │(OpenAI│ │(Google│ │ Models │
│pic)    │ │)      │ │)      │ │        │
└────────┘ └───────┘ └───────┘ └────────┘
```

### Key Benefits

**1. Flexibility**
- Switch models without code changes
- Use best model for each task
- Experiment with different providers

**2. Cost Optimization**
- Use cheaper models for simple tasks
- Reserve powerful models for complex work
- Track and optimize spending

**3. Reliability**
- Automatic failover to backup models
- Retry logic for transient failures
- No single point of failure

**4. Performance**
- Route tasks to fastest models
- Parallel processing when possible
- Intelligent caching

## Supported Providers

### 1. Anthropic (Claude)

**Models:**
- `claude-opus-4` - Most capable, best for complex reasoning
- `claude-sonnet-4` - Balanced performance and cost
- `claude-haiku-4` - Fast and economical

**Best For:**
- Complex reasoning tasks
- Long context understanding
- Code generation and analysis
- Creative writing

**Configuration:**
```json
{
  "anthropic": {
    "api_key": "sk-ant-...",
    "models": {
      "opus": "claude-opus-4-20250514",
      "sonnet": "claude-sonnet-4-20250514",
      "haiku": "claude-haiku-4-20250514"
    },
    "default": "sonnet"
  }
}
```

### 2. OpenAI (GPT)

**Models:**
- `gpt-4-turbo` - Most capable GPT model
- `gpt-4` - Reliable and powerful
- `gpt-3.5-turbo` - Fast and cost-effective

**Best For:**
- Structured outputs
- Function calling
- Quick responses
- JSON generation

**Configuration:**
```json
{
  "openai": {
    "api_key": "sk-...",
    "models": {
      "gpt4": "gpt-4-turbo-preview",
      "gpt35": "gpt-3.5-turbo"
    },
    "default": "gpt4"
  }
}
```

### 3. Google (Gemini)

**Models:**
- `gemini-pro` - Multimodal capabilities
- `gemini-ultra` - Most advanced (when available)

**Best For:**
- Multimodal tasks
- Large context windows
- Google integration

**Configuration:**
```json
{
  "google": {
    "api_key": "AIza...",
    "models": {
      "pro": "gemini-pro",
      "ultra": "gemini-ultra"
    },
    "default": "pro"
  }
}
```

### 4. Local Models

**Models:**
- Ollama models
- Custom fine-tuned models
- Self-hosted LLMs

**Best For:**
- Privacy-sensitive tasks
- Cost control
- Offline operation

**Configuration:**
```json
{
  "local": {
    "endpoint": "http://localhost:11434",
    "models": {
      "codellama": "codellama:13b",
      "mistral": "mistral:7b"
    },
    "default": "codellama"
  }
}
```

## Configuration

### Basic Configuration

```yaml
# .claude-code/router-config.yml

# Enable router
router:
  enabled: true
  
# Provider configurations
providers:
  anthropic:
    api_key: ${ANTHROPIC_API_KEY}
    models:
      - claude-sonnet-4
      - claude-haiku-4
    default: claude-sonnet-4
    
  openai:
    api_key: ${OPENAI_API_KEY}
    models:
      - gpt-4-turbo
      - gpt-3.5-turbo
    default: gpt-4-turbo
    
  google:
    api_key: ${GOOGLE_API_KEY}
    models:
      - gemini-pro
    default: gemini-pro

# Default routing strategy
routing:
  strategy: best_for_task
  fallback_order:
    - anthropic
    - openai
    - google
```

### Advanced Configuration

```yaml
# .claude-code/router-config.yml

router:
  enabled: true
  
  # Cost tracking
  cost_tracking:
    enabled: true
    budget_daily: 50.00
    alert_threshold: 80
  
  # Performance monitoring
  monitoring:
    enabled: true
    track_latency: true
    track_token_usage: true
  
  # Retry configuration
  retry:
    max_attempts: 3
    backoff: exponential
    timeout: 30s

providers:
  anthropic:
    api_key: ${ANTHROPIC_API_KEY}
    rate_limit: 50/minute
    timeout: 60s
    models:
      opus:
        name: claude-opus-4-20250514
        cost_per_1k_tokens:
          input: 0.015
          output: 0.075
        max_tokens: 200000
        
      sonnet:
        name: claude-sonnet-4-20250514
        cost_per_1k_tokens:
          input: 0.003
          output: 0.015
        max_tokens: 200000
        
      haiku:
        name: claude-haiku-4-20250514
        cost_per_1k_tokens:
          input: 0.00025
          output: 0.00125
        max_tokens: 200000
    
  openai:
    api_key: ${OPENAI_API_KEY}
    rate_limit: 60/minute
    models:
      gpt4:
        name: gpt-4-turbo-preview
        cost_per_1k_tokens:
          input: 0.01
          output: 0.03
        max_tokens: 128000
        
      gpt35:
        name: gpt-3.5-turbo
        cost_per_1k_tokens:
          input: 0.0005
          output: 0.0015
        max_tokens: 16000

routing:
  strategy: intelligent
  
  # Task-based routing rules
  rules:
    - task_type: code_generation
      prefer: anthropic.sonnet
      fallback: openai.gpt4
      
    - task_type: simple_query
      prefer: anthropic.haiku
      fallback: openai.gpt35
      
    - task_type: complex_reasoning
      prefer: anthropic.opus
      fallback: openai.gpt4
      
    - task_type: json_output
      prefer: openai.gpt4
      fallback: anthropic.sonnet
  
  # Cost optimization
  cost_optimization:
    enabled: true
    max_cost_per_request: 0.50
    prefer_cheaper_when_quality_acceptable: true
    
  # Performance optimization
  performance:
    cache_responses: true
    cache_ttl: 3600
    parallel_requests: 3
```

### Environment Variables

```bash
# .env file

# API Keys
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=AIza...

# Router settings
CLAUDE_CODE_ROUTER_ENABLED=true
CLAUDE_CODE_ROUTER_STRATEGY=best_for_task
CLAUDE_CODE_DEFAULT_MODEL=claude-sonnet-4

# Cost limits
CLAUDE_CODE_DAILY_BUDGET=50.00
CLAUDE_CODE_COST_ALERT_THRESHOLD=0.80
```

## Routing Strategies

### 1. Manual Selection

Explicitly choose which model to use:

```bash
# Use specific model
claude-code --model claude-opus-4 "Complex task"
claude-code --model gpt-4 "JSON generation task"
claude-code --model claude-haiku-4 "Simple query"

# Use specific provider's default
claude-code --provider openai "Task for GPT"
```

### 2. Best for Task (Intelligent)

Router analyzes task and selects optimal model:

```yaml
routing:
  strategy: best_for_task
  
  # Router considers:
  # - Task complexity
  # - Required context length
  # - Output format requirements
  # - Model capabilities
  # - Current performance metrics
```

**Example:**
```bash
# Router automatically selects:
# - Claude Opus for complex code refactoring
# - Claude Haiku for simple file operations
# - GPT-4 for JSON schema generation
# - Gemini for image analysis

claude-code "Refactor this legacy codebase"
# → Routes to Claude Opus (complex reasoning)

claude-code "List all Python files"
# → Routes to Claude Haiku (simple task)

claude-code "Generate OpenAPI spec"
# → Routes to GPT-4 (structured output)
```

### 3. Cost Optimized

Minimize costs while maintaining quality:

```yaml
routing:
  strategy: cost_optimized
  
  optimization:
    # Use cheapest model that can handle task
    prefer_cheaper: true
    
    # Maximum cost per request
    max_cost: 0.50
    
    # Acceptable quality threshold
    min_quality_score: 0.8
```

**Example:**
```bash
# Simple tasks → Claude Haiku ($0.00025/1k input tokens)
# Medium tasks → Claude Sonnet ($0.003/1k input tokens)
# Complex tasks → Claude Opus ($0.015/1k input tokens)

claude-code "Fix typo in README"
# → Routes to Haiku (cheap, sufficient)

claude-code "Implement new feature with tests"
# → Routes to Sonnet (balanced)

claude-code "Design distributed system architecture"
# → Routes to Opus (complex, worth the cost)
```

### 4. Performance Optimized

Prioritize speed and responsiveness:

```yaml
routing:
  strategy: performance_optimized
  
  optimization:
    # Prefer faster models
    prefer_faster: true
    
    # Maximum acceptable latency
    max_latency: 5s
    
    # Enable parallel processing
    parallel_requests: 5
```

### 5. Fallback Chain

Define explicit fallback order:

```yaml
routing:
  strategy: fallback_chain
  
  chains:
    primary:
      - anthropic.sonnet
      - openai.gpt4
      - google.gemini-pro
      
    budget:
      - anthropic.haiku
      - openai.gpt35
      - local.mistral
```

### 6. Round Robin

Distribute load across providers:

```yaml
routing:
  strategy: round_robin
  
  providers:
    - anthropic
    - openai
    - google
  
  # Good for:
  # - Load balancing
  # - Avoiding rate limits
  # - Testing multiple providers
```

### 7. Custom Rules

Define your own routing logic:

```yaml
routing:
  strategy: custom_rules
  
  rules:
    # Code-related tasks
    - pattern: ".*\.(js|ts|py|go).*"
      model: anthropic.sonnet
      
    # Documentation
    - pattern: ".*documentation.*"
      model: anthropic.sonnet
      
    # Quick queries
    - pattern: "^(what|how|why|when).*"
      model: anthropic.haiku
      
    # Data analysis
    - pattern: ".*analyze.*data.*"
      model: openai.gpt4
      
    # Default
    - default: anthropic.sonnet
```

## Usage Examples

### Example 1: Development Workflow

```bash
# Quick file listing (Haiku - fast & cheap)
claude-code --strategy cost_optimized "List all TypeScript files"

# Code review (Sonnet - balanced)
claude-code --strategy best_for_task "Review this pull request"

# Architecture design (Opus - complex reasoning)
claude-code --strategy performance_optimized "Design microservices architecture"
```

### Example 2: Cost-Conscious Development

```yaml
# router-config.yml
routing:
  strategy: cost_optimized
  
  budget:
    daily: 20.00
    per_request: 0.10
  
  rules:
    # Use Haiku for >80% of tasks
    - task_complexity: low
      model: anthropic.haiku
      
    # Use Sonnet for medium complexity
    - task_complexity: medium
      model: anthropic.sonnet
      
    # Only use Opus when necessary
    - task_complexity: high
      model: anthropic.opus
      max_daily_uses: 10
```

### Example 3: Multi-Provider Setup

```bash
# Primary: Claude for code
# Fallback: GPT for structured data
# Tertiary: Gemini for multimodal

claude-code --provider-chain "anthropic,openai,google" "Build user dashboard"

# If Claude is down → GPT-4
# If GPT is down → Gemini
# All automatic
```

### Example 4: Model-Specific Tasks

```bash
# Force specific models for specific strengths

# Claude Opus: Complex refactoring
claude-code --model claude-opus-4 "Refactor monolith to microservices"

# GPT-4: JSON generation
claude-code --model gpt-4 "Generate OpenAPI spec from these endpoints"

# Claude Haiku: Quick operations
claude-code --model claude-haiku-4 "Format this JSON file"

# Gemini: Image analysis (if supported)
claude-code --model gemini-pro "Analyze this architecture diagram"
```

### Example 5: Dynamic Routing

```javascript
// .claude-code/router.js
module.exports = {
  async selectModel(task, context) {
    // Analyze task
    const complexity = analyzeComplexity(task);
    const estimatedTokens = estimateTokens(task);
    const budget = context.remainingBudget;
    
    // Custom logic
    if (complexity === 'high' && budget > 5.00) {
      return 'claude-opus-4';
    }
    
    if (estimatedTokens > 100000) {
      return 'claude-sonnet-4'; // Large context
    }
    
    if (task.includes('json') || task.includes('schema')) {
      return 'gpt-4'; // Structured output
    }
    
    // Default to cost-effective
    return 'claude-haiku-4';
  }
};
```

## Cost Optimization

### Track Spending

```bash
# View cost dashboard
claude-code costs show

# Output:
# Today's Usage:
# ├─ Anthropic Claude: $12.34
# │  ├─ Opus:   $8.50  (15 requests)
# │  ├─ Sonnet: $3.20  (45 requests)
# │  └─ Haiku:  $0.64  (200 requests)
# ├─ OpenAI GPT: $5.67
# │  ├─ GPT-4:  $4.50  (20 requests)
# │  └─ GPT-3.5: $1.17 (80 requests)
# └─ Total: $18.01 / $50.00 daily budget
```

### Cost-Saving Strategies

**1. Use Task Complexity Detection**
```yaml
auto_detect_complexity: true

# Automatically use:
# - Haiku for simple tasks (80% of requests)
# - Sonnet for medium tasks (15% of requests)
# - Opus for complex tasks (5% of requests)
```

**2. Set Budget Alerts**
```yaml
budget:
  daily: 50.00
  alerts:
    - threshold: 50%
      action: notify
    - threshold: 80%
      action: switch_to_cheaper
    - threshold: 95%
      action: block_expensive_models
```

**3. Cache Responses**
```yaml
caching:
  enabled: true
  ttl: 3600 # 1 hour
  
  # Cache identical requests
  # Save money on repeated queries
```

**4. Batch Operations**
```bash
# Instead of multiple requests
claude-code "Fix bug in file1.js"
claude-code "Fix bug in file2.js"
claude-code "Fix bug in file3.js"

# Batch them
claude-code "Fix bugs in file1.js, file2.js, file3.js"
# Single request = lower cost
```

### Cost Comparison

```
Task: "Review 500-line JavaScript file"

Using Claude Opus:
  Input:  500 lines ≈ 2k tokens × $0.015 = $0.030
  Output: Review ≈ 1k tokens × $0.075 = $0.075
  Total:  $0.105 per review

Using Claude Sonnet:
  Input:  2k tokens × $0.003 = $0.006
  Output: 1k tokens × $0.015 = $0.015
  Total:  $0.021 per review
  
Using Claude Haiku:
  Input:  2k tokens × $0.00025 = $0.0005
  Output: 1k tokens × $0.00125 = $0.00125
  Total:  $0.00175 per review

Savings: Haiku is 60x cheaper than Opus!
         (if quality is acceptable)
```

## Performance Tuning

### Latency Optimization

**1. Parallel Requests**
```yaml
performance:
  parallel_requests: 5
  
# Process multiple files simultaneously
claude-code --parallel "Review all Python files in src/"
```

**2. Streaming Responses**
```yaml
streaming:
  enabled: true
  
# Get partial results immediately
# Don't wait for complete response
```

**3. Model Selection**
```yaml
# Fastest models first
routing:
  prefer_faster: true
  
speed_priority:
  - claude-haiku-4    # Fastest
  - gpt-3.5-turbo     # Fast
  - claude-sonnet-4   # Balanced
```

### Throughput Optimization

```yaml
throughput:
  # Maximize requests per minute
  connection_pool: 10
  keep_alive: true
  
  # Rate limiting
  max_rpm:
    anthropic: 50
    openai: 60
    google: 40
```

### Quality vs Speed Trade-offs

```yaml
# High quality, slower
quality_mode:
  model: claude-opus-4
  temperature: 0.3
  top_p: 0.9

# Balanced
balanced_mode:
  model: claude-sonnet-4
  temperature: 0.5
  top_p: 0.95

# Fast, good enough
speed_mode:
  model: claude-haiku-4
  temperature: 0.7
  top_p: 1.0
```

## Best Practices

### 1. Start with Defaults

```yaml
# Begin with sensible defaults
router:
  enabled: true
  strategy: best_for_task
  default_model: claude-sonnet-4
```

### 2. Monitor and Adjust

```bash
# Regular monitoring
claude-code stats show --weekly

# Adjust based on:
# - Cost patterns
# - Quality metrics
# - Performance data
```

### 3. Use Right Model for Right Job

```
Simple tasks → Haiku
  - File operations
  - Simple queries
  - Quick edits

Medium tasks → Sonnet
  - Code generation
  - Code review
  - Documentation

Complex tasks → Opus
  - Architecture design
  - Complex refactoring
  - System analysis
```

### 4. Set Budgets

```yaml
budget:
  daily: 50.00
  monthly: 1000.00
  
  per_user:
    enabled: true
    default: 10.00
```

### 5. Implement Fallbacks

```yaml
fallback:
  enabled: true
  chain:
    - primary: anthropic.sonnet
    - secondary: openai.gpt4
    - tertiary: google.gemini
  
  max_retries: 3
```

### 6. Test Different Providers

```bash
# A/B testing
claude-code --compare "anthropic,openai" "Generate user service"

# Compare:
# - Quality of output
# - Speed
# - Cost
```

## Conclusion

The LLM Router in Claude Code provides:
- **Flexibility**: Use multiple providers seamlessly
- **Optimization**: Choose best model for each task
- **Reliability**: Automatic failover and retries
- **Cost Control**: Optimize spending automatically
- **Performance**: Route for speed when needed

Start simple with defaults, monitor usage, and optimize based on your specific needs and patterns.

---

**Next Steps:**
- [Learn About Agent Factory →](what-is-agent-factory.md)
- [Explore Skills Creation →](creating-skills.md)
- [View Cost Optimization Examples →](../examples/cost-optimization/)