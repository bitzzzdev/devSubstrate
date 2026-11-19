# OpenRouter Free Coding Models and Inference Providers

**Research snapshot: 2026-11-19**

This directory tracks free coding-capable models available through
[OpenRouter](https://openrouter.ai/), the model publishers behind them, and
the upstream inference providers that serve selected endpoints.

The terms **model publisher** and **inference provider** are different:
Cohere, NVIDIA, Recursive, and Baidu are model publishers; AtlasCloud,
Baidu Qianfan, and Ant Digital are examples of upstream providers named on
individual OpenRouter model pages. OpenRouter is the API gateway and router.
A model can have one or several serving endpoints, and endpoint availability
can change independently of the model publisher.

> This is a dated catalogue, not a guarantee of future availability. Free
> model IDs, quotas, endpoint providers, and tool support can change. Confirm
> the current model page and its `/endpoints` listing before wiring a coding
> agent to it.

## 1. Best candidates for coding agents

These are the strongest starting points because their model descriptions
explicitly target software engineering, coding agents, terminal tasks, or
long-horizon agentic coding.

| Publisher | OpenRouter model ID | Context | Max output | Tool calling | Intended use |
| --- | --- | ---: | ---: | --- | --- |
| Recursive | `recursive/flint-v1.0:free` | 262K | 235,929 | Yes | Codebase investigation, bug fixes, feature work, tests |
| Cohere | `cohere/north-mini-code:free` | 256K | 64K | Yes | Agentic software engineering, code generation, terminal tasks |
| Particle AI | `particle-ai/particle-1:free` | 1.05M | 131,072 | Yes | Terminal workflows, codebase changes, data engineering |
| Thinking Machines Lab | `thinkingmachines/inkling-2-small:free` | 1.05M | 131,072 | Yes | Long-horizon agentic coding and multi-step agent tasks |

### Recursive: Flint

- Model page: https://openrouter.ai/recursive/flint-v1.0:free
- Model ID: `recursive/flint-v1.0:free`
- OpenRouter lists it as free with a 262,144-token context.
- Its model description specifically targets coding agents, codebase
  investigation, bug fixing, feature implementation, and test writing.
- Tool calls are supported. JSON output is available through
  `response_format`, but the endpoint does not enforce JSON Schema.
- The free model page identifies Recursive as its serving provider.
- Best first test: ask it to inspect a small repository, identify a bug, make
  a minimal patch, and run the project's existing tests.

### Cohere: North Mini Code

- Model page: https://openrouter.ai/cohere/north-mini-code:free
- Model ID: `cohere/north-mini-code:free`
- 256,000-token context and up to 64,000 output tokens.
- Built for agentic coding, software engineering, and terminal tasks.
- OpenRouter lists tool calling support. Its model page says JSON-schema tool
  use is supported, but the chat response-format JSON mode is not listed as
  supported. Do not assume strict JSON output.
- Open weights are listed under Apache 2.0.
- This is a strong candidate for OpenCode, SWE-Agent, and similar coding
  harnesses.

### Particle AI: Particle-1

- Model page: https://openrouter.ai/particle-ai/particle-1:free
- Model ID: `particle-ai/particle-1:free`
- 1,048,576-token context and up to 131,072 output tokens.
- Explicitly aimed at software engineering tasks such as terminal use,
  codebase changes, and data engineering.
- Supports tool calls and structured outputs through JSON Schema.
- OpenRouter names Particle AI as the serving provider.
- A useful candidate for longer-context coding sessions. Its coding-agent
  positioning is more relevant than a generic Programming category tag.

### Thinking Machines: Inkling 2 Small

- Model page: https://openrouter.ai/thinkingmachines/inkling-2-small:free
- Model ID: `thinkingmachines/inkling-2-small:free`
- 1,048,576-token context and up to 131,072 output tokens.
- Trained with reinforcement learning on long-horizon coding tasks across
  agent harnesses; supports tool calling and variable reasoning effort.
- **Important restriction:** OpenRouter's model page says the free endpoint
  is only available for use with agentic harnesses.
- **Privacy warning:** prompts and outputs are logged and used to improve
  Thinking Machines Lab models and services. Do not send confidential code,
  secrets, credentials, customer data, or personal information.
- Treat it as a harness-specific experiment, not a general-purpose free API
  endpoint.

## 2. General models worth testing for coding

These are free and expose tool calling, but their model descriptions are
broader than dedicated code models. Test them against the target coding
harness before selecting them as an autonomous coding model.

| Publisher | OpenRouter model ID | Context | Tool calling | Best-fit role |
| --- | --- | ---: | --- | --- |
| Baidu | `baidu/ernie-5.5-flash-preview:free` | 1.024M | Yes | Coding, agentic reasoning, research |
| NVIDIA | `nvidia/nemotron-3-ultra-550b-a55b:free` | 1M | Yes | Planning, orchestration, long-context reasoning |
| NVIDIA | `nvidia/nemotron-3.5-super-vl:free` | 1M | Yes | Visual coding, screenshot/UI inspection, coding validation |
| NVIDIA | `nvidia/nemotron-3.5-lightning:free` | 1M | Yes | Fast agentic subtasks and code assistance |
| Google | `google/gemma-4-31b-it:free` | 262K | Yes | General coding and reasoning |
| Google | `google/gemma-4-26b-a4b-it:free` | 262K | Yes | Lower-active-parameter coding and multimodal tasks |
| Dots Studio | `dots-studio/dots-3-note-preview:free` | 512K | Yes | Coding, multimodal reasoning, multi-step workflows |
| inclusionAI | `inclusionai/ling-3.2-flash:free` | 1.05M | Yes | General reasoning, code review and subagent work |

### Provider notes

- **Baidu Qianfan:** ERNIE-5.5-Flash-Preview is listed as free, released
  November 10, 2026, and served by Baidu Qianfan. OpenRouter lists tool
  calling and structured outputs. Its description explicitly mentions
  coding and agentic capability.
- **NVIDIA:** Nemotron 3 Ultra, Nemotron 3.5 Super VL, and Nemotron 3.5
  Lightning are free variants. Ultra supports tools but does not list
  `response_format`; Super VL supports tools and structured outputs;
  Lightning supports tools but does not list `response_format`. Super VL
  also accepts images and video, which can help with UI and screenshot
  analysis.
- **Google:** both Gemma 4 free variants support native function calling.
  OpenRouter lists a 262K context. The JSON response format is available,
  but JSON Schema enforcement is not listed. They are general models, not
  dedicated coding agents.
- **Dots Studio:** Dots3-Note Preview supports tools, images, and structured
  outputs with a 512K context. OpenRouter currently marks this free variant
  as scheduled to go away on **December 31, 2026**. Do not build a long-term
  dependency on it.
- **inclusionAI:** Ling 3.2 Flash was listed as released November 13, 2026,
  with a 1M context, image input, tool calling, and structured outputs.
  OpenRouter names Ant Digital as its serving provider. It is a general
  reasoning model, not a code-specialist model.

## 3. Small or specialist subagent models

These may be useful for narrow tasks, but they should not be mistaken for
full repository coding models.

| Publisher | OpenRouter model ID | Context | Max output | Notes |
| --- | --- | ---: | ---: | --- |
| LiquidAI | `liquid/lfm-3-1.7b:free` | 262K | 8,192 | Small agent/tool model; not a code specialist |
| NVIDIA | `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` | 256K | 65,536 | Multimodal perception/context subagent |

LiquidAI states that prompts may be retained and used to train its models.
OpenRouter's recent page data also showed a low recent availability rate for
this endpoint, so verify live status before relying on it.

## 4. Retired or expiring entries

- **Poolside Laguna S 2.1 and Laguna XS 2.1:** their OpenRouter pages stated
  that the free variants were going away October 31, 2026. They are excluded
  from the active recommendation list as of this November 19 snapshot.
- **Dots3-Note Preview:** currently listed as free, but its page says it is
  going away December 31, 2026. Use only as a temporary option.

## 5. Free-tier limits and routing behavior

OpenRouter's free-model documentation currently describes these account
limits for `:free` variants:

- Unfunded accounts: up to 20 requests per minute and 50 requests per day.
- Accounts that have purchased at least $10 in credits: up to 1,000 free
  requests per day.
- Failed attempts count toward the daily limit.
- Individual model endpoints can impose additional limits or become
  unavailable.

The credit-purchase threshold is not a free signup benefit. Do not buy
credits solely for the higher request cap unless that trade-off is acceptable.

OpenRouter also provides the `openrouter/free` router. It selects from free
models and filters for requested capabilities such as tool calling, image
input, or structured outputs. It does **not** promise a particular coding
model. Use an explicit model ID when repeatability matters; use
`openrouter/free` only when automatic selection is acceptable.

Official routing documentation:
https://openrouter.ai/docs/guides/routing/provider-selection

Relevant routing fields include:

- `provider.require_parameters: true` to avoid endpoints that do not support
  all requested parameters.
- `provider.only` to restrict a request to named inference providers.
- `provider.order` to set a provider preference order.
- `provider.allow_fallbacks` to control fallback routing.

Do not assume that a model's publisher and its inference provider are the
same. For example, OpenRouter identifies AtlasCloud as the Dots3-Note
Preview provider, Baidu Qianfan for ERNIE, Ant Digital for Ling 3.2 Flash,
and Recursive for Flint. Confirm the current `/endpoints` response before
pinning a route.

## 6. OpenRouter API usage

OpenRouter exposes an OpenAI-compatible chat-completions endpoint:

- Base URL: `https://openrouter.ai/api/v1`
- Chat completions: `https://openrouter.ai/api/v1/chat/completions`
- Authentication: `Authorization: Bearer $OPENROUTER_API_KEY`

Example request with an explicit free coding model:

```bash
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "recursive/flint-v1.0:free",
    "messages": [
      {
        "role": "user",
        "content": "Inspect this code snippet, identify the bug, and propose a minimal patch."
      }
    ],
    "tools": []
  }'
```

For an agentic coding harness, the client must provide the actual tool
definitions and execute returned tool calls. An empty `tools` array above
only demonstrates the endpoint and does not enable file editing or shell
execution.

## 7. Recommended evaluation order

1. **Recursive Flint:** first trial for repository analysis, patch generation,
   and test-writing tasks.
2. **Cohere North Mini Code:** compare for terminal-oriented agent workflows.
3. **Particle-1:** test for long-context codebase work and tool-use efficiency.
4. **Gemma 4 31B:** use as a general-purpose comparison baseline.
5. **Nemotron 3.5 Super VL:** test when screenshot or UI understanding matters.
6. **ERNIE 5.5 Flash:** test for broad coding and agentic reasoning.
7. **Inkling 2 Small:** test only through an agentic harness and only with
   non-sensitive code because of its usage-data policy.

These are evaluation priorities based on model descriptions, advertised
features, and endpoint metadata. They are not results from a local benchmark.
No coding-agent integration test was run for this research.

## 8. Primary sources

- OpenRouter free-model collection:
  https://openrouter.ai/collections/free-models
- OpenRouter free-model router:
  https://openrouter.ai/openrouter/free
- OpenRouter provider routing:
  https://openrouter.ai/docs/guides/routing/provider-selection
- Baidu ERNIE 5.5 Flash:
  https://openrouter.ai/baidu/ernie-5.5-flash-preview:free
- NVIDIA Nemotron 3 Ultra:
  https://openrouter.ai/nvidia/nemotron-3-ultra-550b-a55b:free
- NVIDIA Nemotron 3.5 Super VL:
  https://openrouter.ai/nvidia/nemotron-3.5-super-vl:free
- NVIDIA Nemotron 3.5 Lightning:
  https://openrouter.ai/nvidia/nemotron-3.5-lightning:free
- Cohere North Mini Code:
  https://openrouter.ai/cohere/north-mini-code:free
- Recursive Flint:
  https://openrouter.ai/recursive/flint-v1.0:free
- Particle-1:
  https://openrouter.ai/particle-ai/particle-1:free
- Thinking Machines Inkling 2 Small:
  https://openrouter.ai/thinkingmachines/inkling-2-small:free
- Dots3-Note Preview:
  https://openrouter.ai/dots-studio/dots-3-note-preview:free
- inclusionAI Ling 3.2 Flash:
  https://openrouter.ai/inclusionai/ling-3.2-flash:free
- Google Gemma 4 31B:
  https://openrouter.ai/google/gemma-4-31b-it:free
- Google Gemma 4 26B A4B:
  https://openrouter.ai/google/gemma-4-26b-a4b-it:free
- LiquidAI LFM3-1.7B:
  https://openrouter.ai/liquid/lfm-3-1.7b:free
