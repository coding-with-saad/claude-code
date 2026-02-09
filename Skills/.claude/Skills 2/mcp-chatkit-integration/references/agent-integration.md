# OpenAI Agents SDK + MCP Integration

## Table of Contents
- [Basic Integration](#basic-integration)
- [MCPServerStreamableHttp Configuration](#mcpserverstreamablehttp-configuration)
- [Dynamic Instructions for User Context](#dynamic-instructions-for-user-context)
- [Agent Context Management](#agent-context-management)
- [Streaming Responses](#streaming-responses)
- [Error Handling](#error-handling)

## Basic Integration

### Simple Agent with MCP Server

```python
import asyncio
from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp

async def main():
    async with MCPServerStreamableHttp(
        name="My MCP Server",
        params={"url": "http://localhost:8001/mcp"},
    ) as server:
        agent = Agent(
            name="Assistant",
            instructions="You are a helpful assistant.",
            model="gpt-4o",
            mcp_servers=[server],
        )
        result = await Runner.run(agent, "What tools do you have?")
        print(result.final_output)

asyncio.run(main())
```

## MCPServerStreamableHttp Configuration

### Full Configuration Options

```python
from agents.mcp import MCPServerStreamableHttp

mcp_server = MCPServerStreamableHttp(
    name="Service MCP",
    params={
        "url": "http://localhost:8001/mcp",  # No trailing slash
        "timeout": 60,  # HTTP transport timeout in seconds
        "headers": {  # Optional custom headers
            "Authorization": "Bearer token",
            "X-Custom-Header": "value"
        },
    },
    cache_tools_list=True,  # Cache tool discovery (recommended)
    client_session_timeout_seconds=30,  # MCP session read timeout (default: 5)
    max_retry_attempts=3,  # Retry failed requests
    retry_backoff_seconds_base=1.0,  # Base backoff time for retries
)
```

### Critical: Timeout Configuration

The default MCP session timeout is **5 seconds**, which is too short for database operations:

```python
# BAD: Will timeout on slow database queries
MCPServerStreamableHttp(params={"url": url})

# GOOD: Increased timeouts for reliability
MCPServerStreamableHttp(
    params={"url": url, "timeout": 60},
    client_session_timeout_seconds=30,
)
```

## Dynamic Instructions for User Context

### Why Dynamic Instructions?

MCP tools often need `user_id` for multi-tenant data isolation. The agent must know the user_id to pass it when calling tools. Dynamic instructions inject this at runtime.

### Implementation Pattern

```python
from dataclasses import dataclass
from typing import Any
from agents import Agent, Runner, RunContextWrapper

@dataclass
class AgentContext:
    """Context passed to the agent during execution."""
    user_id: str
    session_id: str
    thread_id: str | None = None
    request_context: Any = None

BASE_PROMPT = """You are a helpful assistant.

## User Context
The current user's ID is: "{user_id}"
ALWAYS include this user_id when calling any tool.

## Available Tools
- list_tasks: List the user's tasks
- create_task: Create a new task
- update_task: Update an existing task
- delete_task: Delete a task
"""

def get_dynamic_instructions(
    context_wrapper: RunContextWrapper[AgentContext],
    agent: Agent[AgentContext]
) -> str:
    """Generate instructions with user_id injected."""
    user_id = "anonymous"

    try:
        ctx = context_wrapper.context

        # Handle our AgentContext dataclass
        if hasattr(ctx, "user_id") and ctx.user_id:
            user_id = ctx.user_id

        # Handle ChatKit AgentContext (has request_context dict)
        elif hasattr(ctx, "request_context") and ctx.request_context:
            if isinstance(ctx.request_context, dict):
                user_id = ctx.request_context.get("user_id", "anonymous")

        # Handle plain dict context
        elif isinstance(ctx, dict):
            user_id = ctx.get("user_id", "anonymous")

    except Exception as e:
        logger.error(f"Error extracting user_id: {e}")

    return BASE_PROMPT.format(user_id=user_id)

# Create agent with dynamic instructions
agent = Agent[AgentContext](
    name="Assistant",
    instructions=get_dynamic_instructions,  # Function, not string
    model="gpt-4o",
    mcp_servers=[mcp_server],
)
```

## Agent Context Management

### Singleton Pattern with Lifecycle Management

```python
import os
import asyncio
import logging
from typing import Optional

logger = logging.getLogger(__name__)

class DispatcherAgent:
    """Agent with managed MCP server lifecycle."""

    def __init__(self, model: str = "gpt-4o"):
        self.model = model
        self.mcp_url = os.getenv("MCP_SERVER_URL", "http://localhost:8001/mcp")
        self._agent: Optional[Agent] = None
        self._mcp_server: Optional[MCPServerStreamableHttp] = None
        self._initialization_lock = asyncio.Lock()
        self._is_initialized = False

    async def ensure_initialized(self):
        """Initialize MCP connection and agent (thread-safe)."""
        if self._is_initialized and self._agent:
            return

        async with self._initialization_lock:
            if self._is_initialized and self._agent:
                return

            logger.info(f"Connecting to MCP Server at {self.mcp_url}")

            try:
                self._mcp_server = MCPServerStreamableHttp(
                    name="MCP Server",
                    params={"url": self.mcp_url, "timeout": 60},
                    client_session_timeout_seconds=30,
                    cache_tools_list=True,
                )

                await self._mcp_server.__aenter__()

                tools = await self._mcp_server.list_tools()
                logger.info(f"Discovered {len(tools)} tools")

                self._agent = Agent[AgentContext](
                    name="Assistant",
                    instructions=get_dynamic_instructions,
                    model=self.model,
                    mcp_servers=[self._mcp_server],
                )

                self._is_initialized = True

            except Exception as e:
                logger.error(f"MCP connection failed: {e}")
                # Fallback: Create agent without MCP tools
                self._agent = Agent[AgentContext](
                    name="Assistant",
                    instructions="MCP tools unavailable. Inform the user.",
                    model=self.model,
                    tools=[],
                )
                self._is_initialized = True

    async def shutdown(self):
        """Gracefully shutdown MCP connection."""
        if self._mcp_server:
            await self._mcp_server.__aexit__(None, None, None)
            self._mcp_server = None
            self._is_initialized = False

    @property
    def agent(self) -> Agent[AgentContext]:
        return self._agent

    async def run(self, message: str, context: AgentContext) -> str:
        await self.ensure_initialized()
        result = await Runner.run(self.agent, input=message, context=context)
        return str(result.final_output)

    async def run_streamed(self, message: str, context: AgentContext):
        await self.ensure_initialized()
        return Runner.run_streamed(self.agent, input=message, context=context)

# Singleton instance
_dispatcher: DispatcherAgent | None = None

def get_dispatcher() -> DispatcherAgent:
    global _dispatcher
    if _dispatcher is None:
        _dispatcher = DispatcherAgent()
    return _dispatcher
```

## Streaming Responses

### Basic Streaming

```python
result = Runner.run_streamed(agent, "Create a task", context=ctx)

async for event in result.stream_events():
    if event.type == "run_item_stream_event":
        print(f"Event: {event.item}")

print(f"Final: {result.final_output}")
```

### With ChatKit Integration

```python
from chatkit.agents import stream_agent_response, AgentContext

async def stream_response(message, user_id):
    agent_ctx = AgentContext(
        thread=thread,
        store=store,
        request_context={"user_id": user_id},
    )

    result = Runner.run_streamed(
        dispatcher.agent,
        input=message,
        context=agent_ctx,
    )

    async for event in stream_agent_response(agent_ctx, result):
        yield event
```

## Error Handling

### Agent Exception Handling

```python
from agents.exceptions import AgentsException

async def run_with_error_handling(message: str, context: AgentContext):
    try:
        result = await Runner.run(agent, message, context=context)
        return result.final_output

    except AgentsException as e:
        logger.error(f"Agent error: {e}")
        return "I encountered an error. Please try again."

    except TimeoutError:
        logger.error("MCP request timed out")
        return "The request timed out. Please try again."

    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return "An unexpected error occurred."
```

### Common Error Patterns

| Error | Cause | Solution |
|-------|-------|----------|
| `McpError: Timed out` | Default 5s timeout | Increase `client_session_timeout_seconds` |
| `AgentsException: Error invoking MCP tool` | Tool execution failed | Check MCP server logs |
| Tools not called | Agent doesn't know user_id | Use dynamic instructions |
| Connection refused | MCP server not running | Start MCP server first |
