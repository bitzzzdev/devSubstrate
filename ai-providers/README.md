# AI API Providers and Inference Platforms

Direct reference for accessible AI model APIs, free key tiers, fast inference engines, and API gateway proxies.

## Quick Index

| Provider | Access Model | Primary Use Case | Docs / Portal |
| --- | --- | --- | --- |
| Groq | Free tier with rate limits | Fast LLM inference (Llama, Mixtral, Gemma) | [console.groq.com](https://console.groq.com/) |
| Cerebras | Free developer tier | High-speed inference on Wafer-Scale Engine | [cloud.cerebras.ai](https://cloud.cerebras.ai/) |
| Google AI Studio | Free tier with Google account | Gemini API keys, prompt prototyping, multi-modal | [aistudio.google.com](https://aistudio.google.com/) |
| APInex | Free and multi-model gateway | Multi-provider API proxy (DeepSeek, GLM, Qwen) | [apinex.bond](https://apinex.bond/) |
| Flash and free-tier provider guide | Free tiers and no-cost model routes, subject to provider limits | Zhipu, Gemini, Cloudflare, Groq, Kilo, OpenRouter, SiliconFlow, Cerebras, SambaNova, Mistral | [OpenCode and coding-agent integration guide](free-ai-api-providers-opencode-guide.md) |

> Free-tier quotas, model identifiers, context windows, and billing rules are time-sensitive. Verify current terms with the provider before use. The linked Flash provider guide is a research snapshot, not a live quota guarantee.

---

## 1. Groq Cloud

Groq runs open-source models on its custom LPU (Language Processing Unit) hardware. It focuses on low latency token generation.

### Key Details
- **Base URL:** `https://api.groq.com/openai/v1`
- **Supported Models:** Llama 3.x, Mixtral 8x7B, Gemma 2, Whisper.
- **Protocol:** Standard OpenAI-compatible format.
- **Free Access:** Free tier keys are available via the web console with per-minute and per-day rate limits.

### Setup and Usage

Generate an API key in the Groq console, then export it:

```bash
export GROQ_API_KEY="gsk_..."
```

Example request using curl:

```bash
curl https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.3-70b-versatile",
    "messages": [{"role": "user", "content": "Write a 3-line bash healthcheck function."}]
  }'
```

---

## 2. Cerebras Inference

Cerebras hosts large language models on its Wafer-Scale Engine chips, delivering high output tokens per second.

### Key Details
- **Base URL:** `https://api.cerebras.ai/v1`
- **Supported Models:** Llama 3.1 8B, Llama 3.1 70B, Llama 3.3 70B.
- **Protocol:** OpenAI API compatible.
- **Portal:** Sign in at [cloud.cerebras.ai](https://cloud.cerebras.ai/) to generate API keys.

### Usage Example

```bash
export CEREBRAS_API_KEY="csk-..."

curl https://api.cerebras.ai/v1/chat/completions \
  -H "Authorization: Bearer $CEREBRAS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.1-70b",
    "messages": [{"role": "user", "content": "Explain zero-copy socket reads in Linux in 2 sentences."}]
  }'
```

---

## 3. Google AI Studio

Google AI Studio is the web-based prototyping environment for Gemini models. It lets you create API keys directly with your Google account without immediate Cloud billing setup for the free tier.

### Key Details
- **Portal:** [aistudio.google.com](https://aistudio.google.com/)
- **Supported Models:** Gemini 2.5 Pro, Gemini 2.5 Flash, Gemini 1.5 Pro, Gemini 1.5 Flash.
- **Capabilities:** Long context windows, audio, video, image, document understanding, and function calling.
- **Free Tier:** Generous free rate limits per minute and per day, with prompt data used to train Google products under the free terms.

### Usage via REST API

Export your key from AI Studio:

```bash
export GEMINI_API_KEY="..."

curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{"text": "Summarize the purpose of an initramfs."}]
    }]
  }'
```

---

## 4. APInex Gateway

APInex (`https://apinex.bond/`) operates as a third-party unified API proxy. It routes requests across multiple upstream models like DeepSeek, Qwen, and GLM while maintaining an OpenAI-compatible interface.

### Key Details
- **Base URL:** `https://api.apinex.bond/v1`
- **Dashboard:** [apinex.bond](https://apinex.bond/) (requires Google sign-in to create an API key).
- **Format:** OpenAI bearer token auth (`sk-...`).

### Usage Example

```bash
export APINEX_API_KEY="sk-..."

curl https://api.apinex.bond/v1/chat/completions \
  -H "Authorization: Bearer $APINEX_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-chat",
    "messages": [{"role": "user", "content": "Ping"}]
  }'
```

Note: Because this is an external proxy service, avoid sending confidential tokens, production customer data, or secrets through third-party gateways.
