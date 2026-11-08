# Groq LPU Inference Architecture and Integration

Author: Dev Borah (bitzzdev)  
Date: November 2026  
Status: Evaluated

## Abstract

This paper analyzes Groq's Language Processing Unit (LPU) architecture for serving open-weight large language models. The evaluation focuses on latency characteristics, token generation throughput, API compatibility, and constraints observed during interactive use.

## 1. Architecture Overview

Groq departs from traditional GPU cluster designs that rely on high-bandwidth memory (HBM) and dynamic cache allocation. Instead, its Tensor Streaming Processor (TSP) architecture uses static compilation and deterministic instruction scheduling.

Key architectural factors:
- On-chip SRAM: Memory bandwidth reaches up to 80 TB/s per chip because weights and intermediate activations reside directly in SRAM rather than off-chip HBM.
- Deterministic execution: Execution timing is planned at compile time, eliminating dynamic cache misses and non-deterministic kernel scheduling.
- Sequential generation speed: Per-token latency remains consistently between 8ms and 15ms for 70B parameter models, yielding 250 to 300+ tokens per second on Llama 3.3 70B.

## 2. API Interface and Compatibility

Groq exposes an OpenAI-compatible wire protocol at `https://api.groq.com/openai/v1`. This allows existing client tooling (OpenAI Python SDK, LangChain, LiteLLM) to function by changing the base URL and API key.

Authentication header:
```http
Authorization: Bearer gsk_...
```

Endpoint for chat completion:
```http
POST /openai/v1/chat/completions HTTP/1.1
Host: api.groq.com
Content-Type: application/json
```

Payload structure:
```json
{
  "model": "llama-3.3-70b-versatile",
  "messages": [
    {"role": "system", "content": "You are a precise technical assistant."},
    {"role": "user", "content": "Explain page cache dirty ratio limits."}
  ],
  "temperature": 0.2,
  "max_tokens": 1024
}
```

## 3. Operational Observations and Limits

Free-tier developer accounts provide usable throughput for personal tooling and CLI integrations, subject to explicit rate limits:
- Requests per minute (RPM): Typically 30 RPM on tier 1.
- Tokens per minute (TPM): Approximately 6,000 to 30,000 TPM depending on the model chosen.
- Failure mode: Rate limit violations return HTTP 429 with a `retry-after` header in seconds.

## 4. Verdict

Groq is currently the best target when building CLI agents, real-time code completion, or automated bash helpers where time-to-first-token directly impacts user interaction. It is less suited for massive batch jobs that exceed developer rate windows without a commercial enterprise contract.
