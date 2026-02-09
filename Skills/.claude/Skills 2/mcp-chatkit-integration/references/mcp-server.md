# MCP Server Patterns with FastMCP

## Table of Contents
- [Basic Server Setup](#basic-server-setup)
- [Tool Definition Patterns](#tool-definition-patterns)
- [Database Integration](#database-integration)
- [Error Handling](#error-handling)
- [FastAPI Integration](#fastapi-integration)

## Basic Server Setup

### Minimal MCP Server

```python
from fastmcp import FastMCP

mcp = FastMCP("Service Name")

@mcp.tool()
async def hello(name: str) -> str:
    """Greet a user by name."""
    return f"Hello, {name}!"
```

### With FastAPI (Recommended for Production)

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastmcp import FastMCP

mcp = FastMCP("My Service")

# Create ASGI app with Streamable HTTP transport
mcp_asgi = mcp.http_app(transport="streamable-http", path="/")

# IMPORTANT: Pass MCP lifespan to FastAPI for proper initialization
app = FastAPI(
    title="MCP Server",
    lifespan=mcp_asgi.lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "healthy"}

# Mount MCP at /mcp endpoint
app.mount("/mcp", mcp_asgi)
```

## Tool Definition Patterns

### Basic Tool with Type Hints

```python
from typing import Dict, Any

@mcp.tool()
async def get_item(
    item_id: int,
    include_details: bool = False
) -> Dict[str, Any]:
    """Get an item by ID.

    Args:
        item_id: The unique identifier of the item.
        include_details: Whether to include extended details.
    """
    return {"id": item_id, "name": "Example"}
```

### Tool with User ID (Multi-Tenant)

```python
@mcp.tool()
async def list_tasks(
    user_id: str,
    status: str | None = None,
    limit: int = 50,
) -> Dict[str, Any]:
    """List tasks for the current user.

    Args:
        user_id: The ID of the user (injected by system).
        status: Filter by status (pending, completed).
        limit: Maximum number of tasks to return.
    """
    # user_id ensures data isolation between users
    tasks = await db.get_tasks(user_id=user_id, status=status, limit=limit)
    return {"count": len(tasks), "tasks": tasks}
```

### Tool with Complex Return Types

```python
from pydantic import BaseModel
from typing import List

class TaskResponse(BaseModel):
    id: int
    title: str
    completed: bool

@mcp.tool()
async def search_tasks(
    user_id: str,
    query: str
) -> Dict[str, Any]:
    """Search tasks by text query."""
    results = await service.search(user_id, query)
    return {
        "query": query,
        "count": len(results),
        "results": [
            {"id": t.id, "title": t.title, "completed": t.completed}
            for t in results
        ]
    }
```

## Database Integration

### With SQLAlchemy Async

```python
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

logger = logging.getLogger(__name__)

engine = create_async_engine(
    DATABASE_URL,
    echo=True,
    pool_pre_ping=True,
    poolclass=NullPool,  # Recommended for serverless
)

@asynccontextmanager
async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSession(engine) as session:
        yield session

@mcp.tool()
async def create_task(
    user_id: str,
    title: str,
    priority: str = "medium",
) -> Dict[str, Any]:
    """Create a new task."""
    logger.info(f"create_task called: user_id={user_id}, title={title}")
    try:
        async with get_session() as session:
            task = Task(user_id=user_id, title=title, priority=priority)
            session.add(task)
            await session.commit()
            await session.refresh(task)
            return {
                "action": "create",
                "status": "success",
                "task": {"id": task.id, "title": task.title}
            }
    except Exception as e:
        logger.error(f"Error creating task: {e}", exc_info=True)
        raise
```

### With Service Layer

```python
from contextlib import asynccontextmanager
from typing import AsyncGenerator

@asynccontextmanager
async def get_service(user_id: str) -> AsyncGenerator[TaskService, None]:
    """Provide service with database session."""
    async with AsyncSession(engine) as session:
        yield TaskService(session=session, user_id=user_id)

@mcp.tool()
async def update_task(
    user_id: str,
    task_id: int,
    title: str | None = None,
    priority: str | None = None,
) -> Dict[str, Any]:
    """Update an existing task."""
    async with get_service(user_id) as service:
        task = await service.update(task_id, title=title, priority=priority)
        return {"action": "update", "status": "success", "task_id": task.id}
```

## Error Handling

### Comprehensive Error Handling

```python
import logging

logger = logging.getLogger(__name__)

@mcp.tool()
async def delete_task(user_id: str, task_id: int) -> Dict[str, Any]:
    """Delete a task by ID."""
    logger.info(f"delete_task called: user_id={user_id}, task_id={task_id}")
    try:
        async with get_service(user_id) as service:
            await service.delete(task_id)
            logger.info(f"Task {task_id} deleted successfully")
            return {"action": "delete", "status": "success", "task_id": task_id}
    except TaskNotFoundError:
        logger.warning(f"Task {task_id} not found for user {user_id}")
        return {"action": "delete", "status": "error", "message": "Task not found"}
    except PermissionError:
        logger.warning(f"User {user_id} not authorized to delete task {task_id}")
        return {"action": "delete", "status": "error", "message": "Not authorized"}
    except Exception as e:
        logger.error(f"Error deleting task: {e}", exc_info=True)
        raise
```

## FastAPI Integration

### Complete Server Structure

```python
# src/mcp/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.mcp.server import mcp

mcp_asgi = mcp.http_app(transport="streamable-http", path="/")

app = FastAPI(
    title="MCP Server",
    description="MCP Server for Tools",
    lifespan=mcp_asgi.lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "mcp-server"}

app.mount("/mcp", mcp_asgi)
```

### Running the Server

```bash
# Development
uvicorn src.mcp.main:app --host 0.0.0.0 --port 8001 --reload

# Production
uvicorn src.mcp.main:app --host 0.0.0.0 --port 8001 --workers 4
```

### Verification Script

```python
import asyncio
from fastmcp import Client
from fastmcp.client.transports import StreamableHttpTransport

async def verify():
    url = "http://localhost:8001/mcp"
    transport = StreamableHttpTransport(url=url)
    client = Client(transport)

    async with client:
        tools = await client.list_tools()
        print(f"Found {len(tools)} tools:")
        for tool in tools:
            print(f"  - {tool.name}: {tool.description[:50]}...")

asyncio.run(verify())
```
