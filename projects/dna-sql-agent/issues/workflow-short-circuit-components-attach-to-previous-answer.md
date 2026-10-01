---
type: troubleshooting
project: dna-sql-agent
date: 2026-09-22
resolved: true
root-cause: "LLM을 건너뛴 워크플로 응답은 사용자 메시지를 저장하지 않아, 컴포넌트 저장 미들웨어가 직전 턴의 assistant 행에 컴포넌트를 붙임"
related: [dna-sql-agent-web]
tags: [workflow-handler, save-components, conversation-history, slash-command]
---

# LLM을 건너뛴 커맨드 응답의 컴포넌트가 직전 답변에 붙음

## 증상

기존 대화에서 `/status` 같은 builtin 커맨드를 실행하면 화면에서는 정상으로 보이지만, 새로고침하면 커맨드 결과(상태 카드 등)가 **직전 질문의 답변 아래**에 붙어 나온다. 커맨드와 그 사용자 메시지는 이력에서 사라진다.

## 환경

- **OS:** macOS (로컬 개발)
- **런타임:** Python 3.10, FastAPI SSE, Next.js 웹
- **관련 패키지:** `dadap.core.agent.agent`, `dna.middlewares.save_components_middleware`, `dna.hooks.chat_save_hook`
- **재현 조건:** 답변이 하나 이상 있는 대화에서 워크플로 핸들러가 `should_skip_llm=True`로 처리하는 메시지를 보낸다.

## 시도한 것들

1. ❌ 코드만 읽고 커맨드가 이력에 안 남는 것만 인지 — 컴포넌트가 다른 행에 붙는 것은 저장 쿼리를 읽고서야 드러남
2. ✅ 커맨드 턴도 사용자 메시지·assistant 메시지로 저장하고, 사용자 행을 스트림 종료 전에 기록

## 근본 원인

- 에이전트의 워크플로 단락 경로는 사용자 메시지를 대화에 추가하지 않고, `after_message` 훅(대화 저장 `ChatSaveHook`)도 실행하지 않은 채 `return`한다.
- 컴포넌트 저장 미들웨어는 SSE가 끝나면 "마지막 **사용자** 메시지 id 이후의 assistant 행"을 찾아 컴포넌트를 덧붙인다.
- 커맨드의 사용자 행이 없으니 "마지막 사용자 메시지"는 직전 질문이 되고, 커맨드의 `status_card`·`status_bar_update`·`chat_input_update` 컴포넌트가 직전 답변 행에 합쳐진다.

## 해결 방법

```python
# WorkflowResult 에 history_response 가 있으면 턴을 기록하고 저장 훅 실행
if workflow_result.history_response is not None:
    conversation.add_message(Message(role="user", content=message, metadata=...))
    conversation.add_message(Message(role="assistant", content=workflow_result.history_response))
    await self._run_after_message_hooks(conversation)   # 스트림 종료 전
```

- 텍스트 컴포넌트는 저장 대상 타입이 아니므로 assistant 본문에 텍스트를 넣고, 카드 등은 미들웨어가 붙이게 둔다.
- 텍스트 없이 컴포넌트만 있는 응답은 본문을 비워 새로고침 때 문장이 중복으로 나오지 않게 한다.
- 저장이 실패해도 워크플로 `except` 가 메시지를 LLM으로 넘기지 않도록 저장은 별도 `try` 로 감싼다.

## 예방책

- 워크플로·단락 경로를 새로 만들 때는 "대화 저장이 어느 훅에 걸려 있는가"를 먼저 확인한다.
- 컴포넌트를 행에 붙이는 로직이 "마지막 사용자 메시지"를 기준으로 삼는다면, 모든 응답 경로가 사용자 행을 먼저 남기는지 점검한다.

## 관련 페이지

- [[decisions/042-skill-turn-snapshot-and-llm-expansion]]
- [[sessions/2026-09-22-slash-command-db-registry]]
