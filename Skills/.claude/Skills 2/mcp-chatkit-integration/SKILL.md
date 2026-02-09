---
name: mcp-chatkit-integration
description: |
  Build MCP (Model Context Protocol) servers and integrate them with OpenAI ChatKit and Agents SDK.
  Use this skill when Claude needs to:
  (1) Create an MCP server using FastMCP with Streamable HTTP transport
  (2) Define MCP tools for agents to call
  (3) Integrate MCP servers with OpenAI Agents SDK using MCPServerStreamableHttp
  (4) Build ChatKit server backends that use MCP tools
  (5) Handle multi-tenant user context injection for MCP tools
  (6) Debug MCP connection timeouts or tool execution issues
  (7) Deploy MCP servers in Docker/Kubernetes environments
---

# MCP + ChatKit Integration

Build MCP servers and integrate them with OpenAI ChatKit for conversational AI applications.

## Architecture Overview

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────┐
│   ChatKit   │────▶│  Dispatcher     │────▶│ MCP Server  │
│   Frontend  │     │  Agent (SDK)    │     │  (FastMCP)  │
└─────────────┘     └─────────────────┘     └─────────────┘
                           │                       │
                           ▼                       ▼
                    MCPServerStreamableHttp    Database/APIs
```

## Quick Start

### 1. MCP Server (FastMCP)

```python
from fastmcp import FastMCP
from fastapi import FastAPI

mcp = FastMCP("My Tools")

@mcp.tool()
async def my_tool(user_id: str, param: str) -> dict:
    """Tool description for the agent."""
    return {"result": f"Processed {param} for {user_id}"}

# Mount as FastAPI app
mcp_asgi = mcp.http_app(transport="streamable-http", path="/")
app = FastAPI(lifespan=mcp_asgi.lifespan)
app.mount("/mcp", mcp_asgi)
```

### 2. Agent with MCP (OpenAI Agents SDK)

```python
from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp

mcp_server = MCPServerStreamableHttp(
    name="My MCP",
    params={"url": "http://localhost:8001/mcp", "timeout": 60},
    client_session_timeout_seconds=30,
    cache_tools_list=True,
)

async with mcp_server:
    agent = Agent(
        name="Assistant",
        instructions=dynamic_instructions,  # Function for user_id injection
        model="gpt-4o",
        mcp_servers=[mcp_server],
    )
    result = await Runner.run(agent, "Hello", context=my_context)
```

### 3. ChatKit Server

```python
from chatkit.server import ChatKitServer
from chatkit.agents import stream_agent_response

class MyChatKitServer(ChatKitServer[dict]):
    async def respond(self, thread, input, context):
        result = Runner.run_streamed(agent, input, context=agent_ctx)
        async for event in stream_agent_response(agent_ctx, result):
            yield event
```

## Key Patterns

### User ID Injection (Multi-Tenant)

MCP tools need user_id for data isolation. Use dynamic instructions:

```python
def get_dynamic_instructions(context_wrapper, agent) -> str:
    user_id = "anonymous"
    ctx = context_wrapper.context

    if hasattr(ctx, "user_id"):
        user_id = ctx.user_id
    elif hasattr(ctx, "request_context"):
        user_id = ctx.request_context.get("user_id", "anonymous")

    return BASE_PROMPT.format(user_id=user_id)
```

### Timeout Configuration

Default MCP timeout is 5 seconds - increase for database operations:

```python
MCPServerStreamableHttp(
    params={"url": url, "timeout": 60},
    client_session_timeout_seconds=30,  # MCP session read timeout
)
```

### Error Handling in ChatKit

```python
from chatkit.types import ThreadItemAddedEvent, AssistantMessageItem

except Exception as e:
    error_item = AssistantMessageItem(
        id=store.generate_item_id("message", thread, context),
        content=[AssistantMessageContent(type="output_text", text="Error occurred")],
    )
    yield ThreadItemAddedEvent(type="item.added", item=error_item)
```

## Reference Files

- **[references/mcp-server.md](references/mcp-server.md)**: Complete MCP server patterns with FastMCP
- **[references/agent-integration.md](references/agent-integration.md)**: OpenAI Agents SDK + MCP integration
- **[references/chatkit-server.md](references/chatkit-server.md)**: ChatKit server implementation patterns
- **[references/deployment.md](references/deployment.md)**: Docker/Kubernetes deployment configuration

## Common Issues

| Issue | Solution |
|-------|----------|
| Timeout after 5s | Increase `client_session_timeout_seconds` |
| Tools not discovered | Check MCP URL (no trailing slash) |
| user_id not passed | Use dynamic instructions pattern |
| Closure bug in tool wrappers | Use SDK's built-in `mcp_servers` parameter |
| ThreadItemCreatedEvent not found | Use `ThreadItemAddedEvent` instead |

## Environment Variables

```bash
MCP_SERVER_URL=http://localhost:8001/mcp  # No trailing slash
OPENAI_API_KEY=your_key
```
