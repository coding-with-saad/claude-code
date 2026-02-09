# ChatKit Server Implementation

## Table of Contents
- [Basic ChatKit Server](#basic-chatkit-server)
- [Respond Method Implementation](#respond-method-implementation)
- [History Management](#history-management)
- [Error Handling](#error-handling)
- [FastAPI Integration](#fastapi-integration)
- [Store Implementation](#store-implementation)

## Basic ChatKit Server

### Minimal Implementation

```python
from typing import Any, AsyncIterator
from chatkit.server import ChatKitServer, StreamingResult, ThreadStreamEvent
from chatkit.types import ThreadMetadata, UserMessageItem
from chatkit.agents import AgentContext, stream_agent_response
from agents import Runner

class MyChatKitServer(ChatKitServer[dict]):
    """ChatKit server with agent integration."""

    def __init__(self, store, dispatcher):
        super().__init__(store)
        self._dispatcher = dispatcher

    async def respond(
        self,
        thread: ThreadMetadata,
        input: UserMessageItem | None,
        context: Any,
    ) -> AsyncIterator[ThreadStreamEvent]:
        """Process user message and stream agent response."""
        if input is None:
            return

        await self._dispatcher.ensure_initialized()

        # Create agent context
        agent_ctx = AgentContext(
            thread=thread,
            store=self.store,
            request_context=context,
        )

        # Run agent with streaming
        result = Runner.run_streamed(
            self._dispatcher.agent,
            input=await self._get_input(input),
            context=agent_ctx,
        )

        async for event in stream_agent_response(agent_ctx, result):
            yield event
```

## Respond Method Implementation

### Complete Implementation with History

```python
import logging
from chatkit.types import (
    ThreadMetadata,
    UserMessageItem,
    AssistantMessageItem,
    AssistantMessageContent,
)
from chatkit.agents import (
    AgentContext,
    stream_agent_response,
    simple_to_agent_input,
)

logger = logging.getLogger(__name__)

class ChatKitServer(ChatKitServer[dict]):

    async def respond(
        self,
        thread: ThreadMetadata,
        input: UserMessageItem | None,
        context: Any,
    ) -> AsyncIterator[ThreadStreamEvent]:
        if input is None:
            return

        await self._dispatcher.ensure_initialized()

        user_id = context.get("user_id", "anonymous")

        # Extract message text for logging
        message_text = self._extract_text(input)
        logger.info(f"Message from {user_id}: {message_text[:50]}...")

        # Load thread with latest data
        loaded_thread = await self.store.load_thread(thread.id, context)

        # Update title on first message
        if message_text and not loaded_thread.title:
            await self._update_title(thread.id, message_text, context)

        # Create agent context
        agent_ctx = AgentContext(
            thread=loaded_thread,
            store=self.store,
            request_context=context,
        )

        # Build full input with history
        full_input = await self._build_input_with_history(
            thread.id, input, context
        )

        # Stream response
        try:
            result = Runner.run_streamed(
                self._dispatcher.agent,
                input=full_input,
                context=agent_ctx,
            )

            async for event in stream_agent_response(agent_ctx, result):
                yield event

        except Exception as e:
            logger.error(f"Chat error: {e}")
            yield self._create_error_event(thread, context, str(e))

    def _extract_text(self, input: UserMessageItem) -> str:
        """Extract text content from user message."""
        if hasattr(input, "content"):
            for content in input.content:
                if hasattr(content, "text"):
                    return content.text
        return ""

    async def _update_title(self, thread_id: str, text: str, context: dict):
        """Update thread title from first message."""
        try:
            new_title = text[:50].strip()
            if len(text) > 50:
                new_title += "..."
            await self.store.rename_thread(thread_id, new_title, context)
        except Exception as e:
            logger.warning(f"Failed to update title: {e}")
```

## History Management

### Loading Conversation History

```python
async def _build_input_with_history(
    self,
    thread_id: str,
    current_input: UserMessageItem,
    context: dict,
) -> list:
    """Build input with conversation history."""
    try:
        # Fetch recent history
        history_page = await self.store.load_thread_items(
            thread_id=thread_id,
            after=None,
            limit=10,  # Last 10 messages for context
            order="desc",
            context=context,
        )

        # Convert to chronological order
        history_items = history_page.data[::-1] if history_page.data else []

        # Build message list
        history_messages = []
        for item in history_items:
            # Skip current input to avoid duplication
            if item.id == current_input.id:
                continue

            role = "user" if isinstance(item, UserMessageItem) else "assistant"
            content = self._extract_content(item)

            if content:
                history_messages.append({"role": role, "content": content})

        # Add current input
        current = await simple_to_agent_input(current_input)

        return history_messages + current

    except Exception as e:
        logger.error(f"Error fetching history: {e}")
        # Fallback to just current input
        return await simple_to_agent_input(current_input)

def _extract_content(self, item) -> str:
    """Extract text content from thread item."""
    content = ""
    if hasattr(item, "content") and item.content:
        for c in item.content:
            if hasattr(c, "text"):
                content += c.text
            elif isinstance(c, dict) and c.get("type") in ("input_text", "output_text"):
                content += c.get("text", "")
    return content
```

## Error Handling

### Creating Error Events

```python
from chatkit.types import ThreadItemAddedEvent, AssistantMessageItem, AssistantMessageContent

def _create_error_event(
    self,
    thread: ThreadMetadata,
    context: dict,
    error_message: str
) -> ThreadItemAddedEvent:
    """Create error event for ChatKit stream."""
    # User-friendly error message
    user_message = "I encountered an error processing your request. Please try again."

    error_item = AssistantMessageItem(
        id=self.store.generate_item_id("message", thread, context),
        content=[
            AssistantMessageContent(
                type="output_text",
                text=user_message
            )
        ],
    )

    return ThreadItemAddedEvent(type="item.added", item=error_item)
```

### Available Event Types

```python
from chatkit.types import (
    ThreadItemAddedEvent,      # New item added to thread
    ThreadItemDoneEvent,       # Item processing complete
    ThreadItemUpdatedEvent,    # Item was updated
    ThreadItemRemovedEvent,    # Item was removed
    ThreadUpdatedEvent,        # Thread metadata changed
    ErrorEvent,                # Error occurred
)

# NOTE: ThreadItemCreatedEvent does NOT exist - use ThreadItemAddedEvent
```

## FastAPI Integration

### Complete Endpoint Setup

```python
from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response, StreamingResponse

router = APIRouter(tags=["Chat"])

# Global instances
_store = get_store()
_chatkit_server = MyChatKitServer(_store, get_dispatcher())

@router.post("/chatkit")
async def chatkit_endpoint(
    request: Request,
    user = Depends(get_current_user),
) -> Response:
    """Main ChatKit endpoint."""
    payload = await request.body()

    context = {
        "user_id": user.id,
        "request": request,
    }

    result = await _chatkit_server.process(payload, context)

    if isinstance(result, StreamingResult):
        return StreamingResponse(result, media_type="text/event-stream")

    if hasattr(result, "json"):
        return Response(content=result.json, media_type="application/json")

    from fastapi.responses import JSONResponse
    return JSONResponse(result)

@router.get("/chat/health")
async def chat_health():
    return {"status": "healthy", "service": "chat"}
```

## Store Implementation

### PostgreSQL Store Example

```python
from chatkit.store import Store
from chatkit.types import ThreadMetadata, ThreadItem

class PostgresStore(Store):
    """PostgreSQL-backed ChatKit store."""

    def __init__(self, session_factory):
        self._session_factory = session_factory

    async def create_thread(self, context: dict) -> ThreadMetadata:
        async with self._session_factory() as session:
            thread = Thread(user_id=context["user_id"])
            session.add(thread)
            await session.commit()
            return ThreadMetadata(id=str(thread.id), title=thread.title)

    async def load_thread(self, thread_id: str, context: dict) -> ThreadMetadata:
        async with self._session_factory() as session:
            thread = await session.get(Thread, thread_id)
            return ThreadMetadata(id=str(thread.id), title=thread.title)

    async def save_thread_item(
        self,
        thread_id: str,
        item: ThreadItem,
        context: dict
    ) -> None:
        async with self._session_factory() as session:
            db_item = ThreadItemModel(
                thread_id=thread_id,
                item_id=item.id,
                item_type=type(item).__name__,
                content=item.model_dump_json(),
            )
            session.add(db_item)
            await session.commit()

    def generate_item_id(
        self,
        prefix: str,
        thread: ThreadMetadata,
        context: dict
    ) -> str:
        import uuid
        return f"{prefix}_{uuid.uuid4().hex[:8]}"
```

### Memory Store (Development)

```python
from chatkit.store import MemoryStore

# Simple in-memory store for development
store = MemoryStore()
```
