# Free AI API Providers: Flash Frontier Models & OpenCode Integration Guide

A technical benchmark and directory of AI inference providers offering **free tiers, permanent zero-cost models, or recurring free credits** for high-velocity "Flash" frontier models (such as Zhipu GLM-4.7-Flash, Google Gemini 2.0 Flash, Cloudflare Workers AI, Groq, and Kilo Gateway). This guide includes ready-to-use configuration templates for [OpenCode](https://opencode.ai/), [Kilo CLI](https://kilo.ai/cli), [Aider](https://aider.chat/), [Continue.dev](https://www.continue.dev/), [Roo Code](https://github.com/RooVetGit/Roo-Code), and the OpenAI SDK.

> Research snapshot supplied on 2026-11-15. Provider availability, model IDs, quotas, context limits, pricing, and compatibility can change. Treat the figures below as leads to verify against each provider's current official documentation before relying on them. This resource has been added without independently validating every listed claim.

## 1. Executive Summary & Provider Matrix

Modern frontier model developers have shifted from costly, heavyweight monoliths toward specialized, high-throughput **"Flash" models** (e.g., GLM-4.7-Flash, Gemini 2.0 Flash, Llama 3.3 70B, Qwen 2.5 Coder). Several major cloud providers and inference engines host these models completely free of charge or with generous daily free allowances, standardizing on **OpenAI-compatible REST endpoints** that plug directly into open coding agents.

### Quick Comparison Matrix

| Provider | Featured Flash / Frontier Models | Free Quota & Billing Model | Context Window | Base URL (`baseURL`) | Credit Card Required? |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [**Zhipu AI BigModel**](https://open.bigmodel.cn/) | `glm-4.7-flash`, `glm-4-flash`, `glm-4.6v-flash` | **100% Permanently Free** (¥0 / $0 token cost) | **200K in / 128K out** | `https://open.bigmodel.cn/api/paas/v4` | No |
| [**Google AI Studio**](https://aistudio.google.com/) | `gemini-2.0-flash`, `gemini-1.5-flash`, `gemini-2.0-flash-lite` | **15 RPM / 1,500 RPD / 1M TPM** (Daily renewal) | **1M tokens** | `https://generativelanguage.googleapis.com/v1beta/openai/` | No |
| [**Cloudflare Workers AI**](https://developers.cloudflare.com/workers-ai/) | `@cf/meta/llama-3.3-70b-instruct`, `@cf/deepseek-ai/deepseek-r1-distill-qwen-32b`, `@cf/cloudflare/clef-flash` | **10,000 Neurons / day** (~millions of tokens daily) | **8K-128K** | `https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/v1` | No |
| [**GroqCloud**](https://console.groq.com/) | `llama-3.3-70b-versatile`, `llama-3.1-8b-instant`, `deepseek-r1-distill-llama-70b` | **30 RPM / 14,400 RPD / up to 30K TPM** | **128K** | `https://api.groq.com/openai/v1` | No |
| [**Kilo Gateway**](https://models.opencode.ai/providers/kilo) | `kilo-auto/free`, `nvidia/nemotron-3.5-lightning:free`, `cohere/north-mini-code:free` | **$0.00 / token** via Auto Free & `:free` gateway models | **256K-1M** | `https://api.kilo.ai/api/gateway` | No |
| [**OpenRouter**](https://openrouter.ai/) | `google/gemini-2.0-flash-exp:free`, `meta-llama/llama-3.3-70b-instruct:free`, `qwen/qwen-2.5-coder-32b-instruct:free` | **20-50 requests / day** on `:free` endpoints | **32K-1M** | `https://openrouter.ai/api/v1` | No |
| [**SiliconFlow**](https://siliconflow.cn/) | `Qwen/Qwen2.5-Coder-7B-Instruct`, `deepseek-ai/DeepSeek-V3` (free tier) + 20M tokens | **Permanent free models** + 20 Million signup tokens | **32K-64K** | `https://api.siliconflow.cn/v1` | No |
| [**Cerebras Cloud**](https://cloud.cerebras.ai/) | `llama3.3-70b`, `llama3.1-8b` | **1,000,000 tokens / day** (30 RPM, 60K TPM) | **8K-128K** | `https://api.cerebras.ai/v1` | No |
| [**SambaNova Cloud**](https://cloud.sambanova.ai/) | `Meta-Llama-3.3-70B-Instruct`, `Qwen2.5-Coder-32B-Instruct` | **20 RPM / 200,000 tokens / day** | **8K-64K** | `https://api.sambanova.ai/v1` | No |
| [**Mistral La Plateforme**](https://console.mistral.ai/) | `codestral-latest`, `mistral-small-latest`, `ministral-8b-latest` | **Free Experimentation Tier** (1 RPS rate limit) | **32K-256K** | `https://api.mistral.ai/v1` | No |

## 2. In-Depth Provider Profiles

### 1. Zhipu AI (BigModel.cn): The Premier Free Frontier Flash

* **Official Portal**: [open.bigmodel.cn](https://open.bigmodel.cn/)
* **Pricing & Quota**: **Permanently ¥0.00 / token** for the Flash tier. No credit card, no expiration date, no hidden token drain.
* **Top Flash Models**:
  * `glm-4.7-flash` (Frontier 30B MoE with ~3B active parameters, optimized for agentic workflows and coding).
  * `glm-4-flash` (Original ultra-fast text model).
  * `glm-4.6v-flash` (Multimodal vision Flash model).
* **Specifications**:
  * **Context Length**: 200,000 input tokens.
  * **Max Output**: Up to 128,000 generation tokens in a single request (eliminates "continue" interruptions).
  * **Architecture**: Multi-Head Latent Attention (MLA) for minimal KV-cache memory overhead.
* **OpenAI-Compatible Endpoint**:

  ```text
  Base URL: https://open.bigmodel.cn/api/paas/v4
  Chat Completions: https://open.bigmodel.cn/api/paas/v4/chat/completions
  API Key Format: {id}.{secret} (issued in the BigModel developer console)
  ```

* **Developer Consideration**: Avoid models ending in `x` (like `glm-4-flashx`), which route to paid enterprise acceleration nodes.

### 2. Cloudflare Workers AI

* **Official Portal**: [developers.cloudflare.com/workers-ai](https://developers.cloudflare.com/workers-ai/)
* **Pricing & Quota**: **10,000 Neurons per day for free** across all accounts. Refreshes every 24 hours at 00:00 UTC.
* **Top Flash Models**:
  * `@cf/meta/llama-3.3-70b-instruct`
  * `@cf/deepseek-ai/deepseek-r1-distill-qwen-32b`
  * `@cf/qwen/qwen2.5-coder-32b-instruct`
  * `@cf/cloudflare/clef-flash`
* **OpenAI-Compatible Endpoint**:

  ```text
  Base URL: https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/v1
  Authorization: Bearer <CLOUDFLARE_API_TOKEN>
  ```

* **Developer Consideration**: You need your Cloudflare **Account ID** (found in the Cloudflare Dashboard URL or sidebar) and an API Token with `Workers AI: Read/Write` permissions.

### 3. Google AI Studio (Gemini Flash)

* **Official Portal**: [aistudio.google.com](https://aistudio.google.com/)
* **Pricing & Quota**: Free tier available immediately without a payment card:
  * **15 Requests Per Minute (RPM)**
  * **1,500 Requests Per Day (RPD)**
  * **1,000,000 Tokens Per Minute (TPM)**
* **Top Flash Models**:
  * `gemini-2.0-flash` (Real-time speed, multimodal, enhanced coding benchmarks).
  * `gemini-1.5-flash` (Industry-leading 1M token context).
  * `gemini-2.0-flash-lite` (Lightweight high-throughput model).
* **OpenAI-Compatible Endpoint**:

  ```text
  Base URL: https://generativelanguage.googleapis.com/v1beta/openai/
  Chat Completions: https://generativelanguage.googleapis.com/v1beta/openai/chat/completions
  Authorization: Bearer <GEMINI_API_KEY>
  ```

* **Developer Consideration**: Google natively supports OpenAI request structures. Just pass `gemini-2.0-flash` as the model parameter.

### 4. GroqCloud

* **Official Portal**: [console.groq.com](https://console.groq.com/)
* **Hardware & Speed**: Custom LPU (Language Processing Unit) chips running open weights at **300 to 800+ tokens per second**.
* **Pricing & Quota**: Free tier refreshed every minute/day:
  * **30 RPM** and **14,400 RPD** for standard models.
  * Model-specific TPM (up to 30,000 TPM for Llama 3.3 70B; 30,000-70,000 TPM for Llama 3.1 8B).
* **Top Flash Models**:
  * `llama-3.3-70b-versatile`
  * `llama-3.1-8b-instant`
  * `deepseek-r1-distill-llama-70b`
* **OpenAI-Compatible Endpoint**:

  ```text
  Base URL: https://api.groq.com/openai/v1
  Authorization: Bearer <GROQ_API_KEY>
  ```

### 5. OpenRouter Free Tier

* **Official Portal**: [openrouter.ai](https://openrouter.ai/)
* **Pricing & Quota**: Offers a rotating catalog of free models tagged with `:free`. Unfunded accounts receive 20-50 requests/day; any one-time credit purchase unlocks up to 1,000 free requests/day.
* **Top Flash Models**:
  * `google/gemini-2.0-flash-exp:free`
  * `meta-llama/llama-3.3-70b-instruct:free`
  * `qwen/qwen-2.5-coder-32b-instruct:free`
  * `deepseek/deepseek-r1:free`
* **OpenAI-Compatible Endpoint**:

  ```text
  Base URL: https://openrouter.ai/api/v1
  Authorization: Bearer <OPENROUTER_API_KEY>
  ```

### 6. Cerebras Cloud & SambaNova Cloud

* **Cerebras**: [cloud.cerebras.ai](https://cloud.cerebras.ai/)
  * Free quota: **1 Million tokens per day** at 1,000+ tokens/second.
  * Base URL: `https://api.cerebras.ai/v1`
  * Key Models: `llama3.3-70b`, `llama3.1-8b`.
* **SambaNova**: [cloud.sambanova.ai](https://cloud.sambanova.ai/)
  * Free quota: **20 RPM, 200,000 tokens/day**.
  * Base URL: `https://api.sambanova.ai/v1`
  * Key Models: `Meta-Llama-3.3-70B-Instruct`, `Qwen2.5-Coder-32B-Instruct`.

### 7. Kilo Gateway (Kilo Code): No-Card Auto Free Routing

* **Official Portal & Docs**: [kilo.ai](https://kilo.ai/) | [Using Kilo for Free](https://kilo.ai/docs/getting-started/using-kilo-for-free) | [Kilo Gateway API Docs](https://models.opencode.ai/providers/kilo)
* **Pricing & Quota**: **$0.00 / $0.00** on `kilo-auto/free` and `:free`-tagged models. No credit card required; pairs with a standard Google sign-in when using the CLI or plugins. Served independently of OpenRouter credits.
* **Top Free Models on Kilo Gateway**:
  * `kilo-auto/free` (**Auto Free**: 256K context, 32K output; automatically routes across zero-cost coding models currently available on the gateway).
  * `nvidia/nemotron-3.5-lightning:free` (1M context, 65K output).
  * `nvidia/nemotron-3.5-super-vl:free` (1M context, 131K output).
  * `nvidia/nemotron-3-ultra-550b-a55b:free` (1M context, 65K output).
  * `cohere/north-mini-code:free` (256K context, 64K output).
  * `dots-studio/dots-3-note-preview:free` (512K context, 460K output).
* **OpenAI-Compatible Endpoint**:

  ```text
  Base URL: https://api.kilo.ai/api/gateway
  Package: @ai-sdk/openai-compatible
  ```

* **Developer Consideration**: Free endpoints on Kilo Gateway may log prompts for service operation and model routing, so avoid sending proprietary or sensitive codebases through `:free` routes ([OpenRouter + Kilo guide](https://openrouter.ai/blog/tutorials/kilo-code-openrouter/)). Also note that Kilo's `Auto Small` background-task model consumes credits unless switched to a free model in settings.

## 3. Configuring OpenCode and Open-Source Coding Tools

Most open-source coding agents conform to the OpenAI protocol. You can configure any of the above providers by setting `baseURL`, `apiKey`, and `model`.

### A. OpenCode CLI Configuration

OpenCode supports custom OpenAI-compatible providers either globally in `~/.config/opencode/opencode.json` or locally in your project root `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zhipu-glm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Zhipu BigModel (GLM-4.7-Flash)",
      "options": {
        "baseURL": "https://open.bigmodel.cn/api/paas/v4"
      },
      "models": {
        "glm-4.7-flash": {
          "name": "GLM-4.7-Flash (Free)"
        },
        "glm-4-flash": {
          "name": "GLM-4-Flash (Free)"
        }
      }
    },
    "google-gemini": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Google AI Studio",
      "options": {
        "baseURL": "https://generativelanguage.googleapis.com/v1beta/openai"
      },
      "models": {
        "gemini-2.0-flash": {
          "name": "Gemini 2.0 Flash (Free)"
        }
      }
    },
    "cloudflare-ai": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Cloudflare Workers AI",
      "options": {
        "baseURL": "https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/ai/v1"
      },
      "models": {
        "@cf/meta/llama-3.3-70b-instruct": {
          "name": "Llama 3.3 70B Instruct"
        }
      }
    },
    "groq": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "GroqCloud",
      "options": {
        "baseURL": "https://api.groq.com/openai/v1"
      },
      "models": {
        "llama-3.3-70b-versatile": {
          "name": "Llama 3.3 70B (Fast)"
        }
      }
    }
  }
}
```

Then connect keys via the terminal:

```bash
# Add keys interactively in OpenCode TUI:
opencode
/connect
# Select the provider and paste the corresponding API key.
```

### A.1. Step-by-Step: Hooking Kilo's Free Models into OpenCode

To use Kilo Gateway's card-free, zero-cost models inside OpenCode, you can either install an OpenCode bridge plugin, append Kilo as a custom provider alongside your existing OpenRouter presets, or run the first-party Kilo CLI.

#### Option 1: Bridge Plugin (`openkilo` or `opencode-kilo-auth`)

1. **Install the bridge plugin globally via npm**:

   ```bash
   npm install -g openkilo
   ```

2. **Add the plugin hook to `~/.config/opencode/opencode.json`**:
   * For zero-config free model access via [`openkilo`](https://github.com/AnganSamadder/openkilo):

     ```json
     {
       "plugin": ["openkilo"]
     }
     ```

   * Or for full Kilo Gateway auth via [`opencode-kilo-auth`](https://github.com/JungHoonGhae/opencode-kilo-auth):

     ```json
     {
       "plugin": ["opencode-kilo-auth@latest"]
     }
     ```

3. **Select the Auto Free route**:
   Restart OpenCode (run `/kilo_refresh` if models do not appear immediately) and set your active model to `kilo-auto/free` (or select it under the Kilo/OpenKilo provider). This routes requests across whichever zero-cost models are currently active on Kilo Gateway.

#### Option 2: Direct Provider Block in `~/.config/opencode/opencode.json` (Merged with OpenRouter Presets)

If you already use OpenRouter `:free` presets in `~/.config/opencode/opencode.json`, you can append `kilo` directly using the verified Kilo Gateway endpoint (`https://api.kilo.ai/api/gateway`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "kilo/kilo-auto/free",
  "provider": {
    "openrouter": {
      "models": {
        "@preset/free-coding": {
          "name": "Free Coding Stack (Auto-Fallback)"
        },
        "nvidia/nemotron-3-ultra-550b-a55b:free": {
          "name": "Nemotron 3 Ultra 550B (Free)"
        },
        "nvidia/nemotron-3.5-super-vl:free": {
          "name": "Nemotron 3.5 Super VL 120B (Free)"
        },
        "nvidia/nemotron-3.5-lightning:free": {
          "name": "Nemotron 3.5 Lightning 30B (Free)"
        }
      }
    },
    "kilo": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Kilo Gateway",
      "options": {
        "baseURL": "https://api.kilo.ai/api/gateway"
      },
      "models": {
        "kilo-auto/free": {
          "name": "Kilo Auto Free (No-Card Gateway)"
        }
      }
    }
  }
}
```

#### Option 3: First-Party Kilo CLI (`@kilocode/cli`)

Because the [Kilo CLI](https://kilo.ai/docs/code-with-ai/platforms/cli) is an official fork of OpenCode supporting the same configuration options, you can use it directly without manual plugin wiring:

1. **Install Kilo CLI globally**:

   ```bash
   npm install -g @kilocode/cli
   ```

2. **Launch the terminal interface**:

   ```bash
   kilo
   ```

3. **Select Auto Free**: Type `/models`, search for `free`, and select **Auto Free** (`kilo-auto/free`). Sign in with a standard Google account (no payment details requested).

### B. Continue.dev Configuration (`~/.continue/config.json`)

```json
{
  "models": [
    {
      "title": "GLM-4.7-Flash (Free)",
      "provider": "openai",
      "model": "glm-4.7-flash",
      "apiBase": "https://open.bigmodel.cn/api/paas/v4",
      "apiKey": "YOUR_ZHIPU_API_KEY"
    },
    {
      "title": "Gemini 2.0 Flash (Free)",
      "provider": "openai",
      "model": "gemini-2.0-flash",
      "apiBase": "https://generativelanguage.googleapis.com/v1beta/openai/",
      "apiKey": "YOUR_GEMINI_API_KEY"
    },
    {
      "title": "Groq Llama 3.3 70B (Free)",
      "provider": "openai",
      "model": "llama-3.3-70b-versatile",
      "apiBase": "https://api.groq.com/openai/v1",
      "apiKey": "YOUR_GROQ_API_KEY"
    }
  ]
}
```

### C. Aider (`~/.aider.conf.yml` or CLI)

```bash
# Run Aider with Zhipu GLM-4.7-Flash:
export OPENAI_API_BASE="https://open.bigmodel.cn/api/paas/v4"
export OPENAI_API_KEY="your_zhipu_api_key"
aider --model openai/glm-4.7-flash

# Run Aider with Google Gemini 2.0 Flash:
export OPENAI_API_BASE="https://generativelanguage.googleapis.com/v1beta/openai"
export OPENAI_API_KEY="your_gemini_api_key"
aider --model openai/gemini-2.0-flash

# Run Aider with Groq Llama 3.3 70B:
export OPENAI_API_BASE="https://api.groq.com/openai/v1"
export OPENAI_API_KEY="your_groq_api_key"
aider --model openai/llama-3.3-70b-versatile
```

### D. Direct Python OpenAI SDK Client Example

```python
from openai import OpenAI

# 1. Zhipu GLM-4.7-Flash
glm_client = OpenAI(
    base_url="https://open.bigmodel.cn/api/paas/v4",
    api_key="YOUR_ZHIPU_KEY"
)
response = glm_client.chat.completions.create(
    model="glm-4.7-flash",
    messages=[{"role": "user", "content": "Write a Python script for file deduplication."}],
    temperature=0.2
)
print("GLM Response:", response.choices[0].message.content)

# 2. Google Gemini 2.0 Flash
gemini_client = OpenAI(
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
    api_key="YOUR_GEMINI_API_KEY"
)
res_gemini = gemini_client.chat.completions.create(
    model="gemini-2.0-flash",
    messages=[{"role": "user", "content": "Explain async/await in Rust."}],
)
print("Gemini Response:", res_gemini.choices[0].message.content)
```

## 4. Best Practices & Pro Tips for Free Tier Operation

1. **Fallback Routing (Cascade Strategy)**:
   * Point your primary code assistant to **GLM-4.7-Flash**, **Gemini 2.0 Flash**, or **Kilo Auto Free** (`kilo-auto/free`) for heavy context and multi-turn refactoring.
   * Configure **Groq** (`llama-3.3-70b-versatile`) as the sub-second speed fallback when editing single functions or small files.
2. **Context Window Management**:
   * While GLM-4.7-Flash supports 200K context and Gemini supports 1M context, sending entire codebases on every prompt will hit per-minute token limits (TPM). Keep system prompts modular and send relevant module slices.
3. **Preventing Accidental Charges**:
   * In Zhipu AI, never use model IDs ending in `x` (e.g. `glm-4-flashx`).
   * In Cloudflare, keep tracking neuron usage under 10,000/day in the dashboard to remain strictly inside the free tier.
   * In Google AI Studio, ensure your project is set to "Free Tier (no billing account linked)" to ensure requests return HTTP 429 rather than incurring charges.
