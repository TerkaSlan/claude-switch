# Claude.ai vs. Anthropic Console & Claude Code Configuration Guide

## 1. Claude.ai Subscription vs. Anthropic Console API

| Feature | Claude.ai Subscription (Pro / Max) | Anthropic Console (API) |
| :--- | :--- | :--- |
| **Primary Purpose** | Web/app chat interface & Claude Code CLI access | Developer platform for custom API key generation |
| **Billing Model** | Fixed monthly subscription | Pay-as-you-go per token |
| **Generates API Key?** | **No** | **Yes** |
| **URL** | `claude.ai` | `console.anthropic.com` |

---

## 2. Using Claude Code with Your `Claude.ai` Subscription

You **do not need an API key** to use Claude Code if you have a `Claude.ai` subscription.

### Basic Setup
1. **Install Claude Code**:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```
2. **Authenticate**:
   ```bash
   claude
   ```
3. Select **Claude account with subscription** when prompted and log in via the browser.

### Scripting & Automation Mode
Run tasks non-interactively using the print flag (`-p`):
```bash
claude -p "Summarize src/index.ts"
```

---

## 3. Resolving Conflicts: API Keys vs. Web Subscriptions

### Issue
`⚠ claude.ai connectors are disabled because ANTHROPIC_API_KEY or another auth source is set...`

### Solution
Claude Code defaults to API pay-as-you-go mode when `ANTHROPIC_API_KEY` exists in your shell session. Clear the variable to restore subscription mode:

* **Mac / Linux**:
  ```bash
  unset ANTHROPIC_API_KEY
  ```
* **Windows (PowerShell)**:
  ```powershell
  Remove-Item Env:\ANTHROPIC_API_KEY
  ```

---

## 4. Multi-Profile & Multi-Provider Switching Setup

To switch quickly between standard Anthropic, different developer accounts, or alternative providers (OpenRouter, local LLMs, Bedrock), use isolated directories or shell aliases.

### Option A: Clean Profile Isolation (`CLAUDE_CONFIG_DIR`)

Maintain independent authentication states and settings:

```bash
# Work / API Profile
CLAUDE_CONFIG_DIR=~/.claude-work claude

# Personal Subscription Profile
CLAUDE_CONFIG_DIR=~/.claude-personal claude
```

### Option B: Quick Shell Aliases & Provider Routing

Add the following functions to your `~/.zshrc` or `~/.bashrc`:

```bash
# 1. Official Claude (Subscription Mode)
claude-sub() {
  unset ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_MODEL
  CLAUDE_CONFIG_DIR=~/.claude-personal claude "$@"
}

# 2. Official Anthropic API Key Mode
claude-api() {
  export ANTHROPIC_API_KEY="sk-ant-your-api-key"
  unset ANTHROPIC_BASE_URL ANTHROPIC_MODEL
  claude "$@"
}

# 3. OpenRouter Gateway (Access DeepSeek, GPT-4, etc.)
claude-openrouter() {
  export ANTHROPIC_BASE_URL="https://openrouter.ai/api/v1"
  export ANTHROPIC_API_KEY="sk-or-v1-your-openrouter-key"
  export ANTHROPIC_MODEL="anthropic/claude-3.7-sonnet"
  claude "$@"
}

# 4. Local LLM / Ollama Proxy
claude-local() {
  export ANTHROPIC_BASE_URL="http://localhost:11434/v1"
  export ANTHROPIC_API_KEY="local-key"
  export ANTHROPIC_MODEL="qwen2.5-coder:32b"
  claude "$@"
}
```

---

## 5. Helpful Commands

* **Check Current Auth Status**:
  ```bash
  claude doctor
  ```
* **Reset / Switch Account**:
  ```bash
  claude setup
  ```