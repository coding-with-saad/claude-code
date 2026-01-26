
# Free Claude Code Setup with OpenRouter (Free Models)

A complete step-by-step guide to run **Claude Code for FREE** using **OpenRouter** and **free LLM models** via `claude-code` and `claude-code-router`.

---

## 1. Prerequisites

### Verify Node.js Installation

Open PowerShell and run:

```powershell
node --version
```

- Node.js **18.x or higher** is required
- Download LTS from: https://nodejs.org

---

## 2. Create OpenRouter Account & API Key

1. Visit https://openrouter.ai  
2. Sign up / Login  
3. Go to **API Keys**  
4. Click **Create Key**  
5. Copy your API key:

```text
sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 3. Check Free Models on OpenRouter

Recommended free models:
- mistralai/devstral-2512:free
- qwen/qwen-2.5-coder-32b-instruct:free
- nousresearch/hermes-3-llama-3.1-405b:free

https://openrouter.ai/models?pricing=free

---

## 4. Install Required CLI Tools

```powershell
npm install -g @anthropic-ai/claude-code @musistudio/claude-code-router
```

---

## 5. Create Required Directories

```powershell
mkdir $HOME/.claude-code-router
mkdir $HOME/.claude
```

---

## 6. Create Router Configuration File

```powershell
notepad $HOME/.claude-code-router/config.json
```

Paste:

```json
{
  "LOG": true,
  "LOG_LEVEL": "info",
  "HOST": "127.0.0.1",
  "PORT": 3456,
  "API_TIMEOUT_MS": 600000,

  "Providers": [
    {
      "name": "openrouter",
      "api_base_url": "https://openrouter.ai/api/v1/chat/completions",
      "api_key": "$OPENROUTER_API_KEY",
      "models": [
        "mistralai/devstral-2512:free"
      ],
      "transformer": {
        "use": ["openrouter"]
      }
    }
  ],

  "Router": {
    "default": "openrouter,mistralai/devstral-2512:free",
    "background": "openrouter,mistralai/devstral-2512:free",
    "think": "openrouter,mistralai/devstral-2512:free",
    "longContext": "openrouter,mistralai/devstral-2512:free",
    "longContextThreshold": 60000
  }
}
```

---

## 7. Set Environment Variable

```powershell
[System.Environment]::SetEnvironmentVariable(
  'OPENROUTER_API_KEY',
  'YOUR_API_KEY_HERE',
  'User'
)
```

Verify:

```powershell
echo $env:OPENROUTER_API_KEY
```

---

## 8. Start Router

```powershell
ccr start
```

---

## 9. Use Claude Code

```powershell
cd your-project-folder
ccr code
```

Type:

```text
hi
```

🎉 Claude Code + OpenRouter is working!
