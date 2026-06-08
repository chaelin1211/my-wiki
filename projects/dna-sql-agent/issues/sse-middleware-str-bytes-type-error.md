---
type: troubleshooting
project: dna-sql-agent
date: 2026-05-26
resolved: true
root-cause: "Starlette BaseHTTPMiddleware body_iterator에서 str yield 시 TypeError"
related: [sse-analysis, save_components_middleware]
tags: [sse, middleware, starlette, bytes, encoding]
---

# Starlette SSE 미들웨어 — str yield 시 TypeError

## 증상

```
TypeError: sequence item 1: expected a bytes-like object, str found
  File ".../starlette/middleware/base.py", line 238, in __call__
    await send({"type": "http.response.body", "body": chunk, "more_body": True})
```

`SaveComponentsMiddleware`에서 SSE chunk를 직접 yield하는 코드에서 발생.

## 환경

- **런타임:** Python 3.10, Starlette (FastAPI), uvicorn
- **재현 조건:** `BaseHTTPMiddleware`의 `body_iterator`에서 `str` 타입으로 yield

## 시도한 것들

1. ❌ `yield f"data: {payload}\n\n"` — str yield → TypeError
2. ✅ `yield f"data: {payload}\n\n".encode("utf-8")` — bytes yield → 정상

## 근본 원인

Starlette의 `BaseHTTPMiddleware`는 `body_iterator`에서 `bytes`를 기대한다.
기존 코드에서 원본 chunk를 그대로 yield할 때는 이미 bytes였으나, 새로 생성한 이벤트 문자열을 인코딩 없이 yield하면 TypeError 발생.

## 해결 방법

```python
done_payload = json.dumps({"type": "done", "message_id": message_id, "conversation_id": conversation_id})
yield f"data: {done_payload}\n\n".encode("utf-8")
```

## 예방책

`BaseHTTPMiddleware`에서 새 chunk를 생성해 yield할 때는 항상 `.encode("utf-8")` 적용.

## 관련 페이지

- [[knowledge/troubleshooting/sse-post-completion-patch]]
