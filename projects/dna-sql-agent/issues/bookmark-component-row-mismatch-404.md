---
type: troubleshooting
project: dna-sql-agent
date: 2026-09-22
resolved: true
root-cause: "답변 컴포넌트는 도구 호출 행마다 나뉘어 저장되는데, 웹은 여러 행을 한 메시지로 합치며 첫 행 id만 남겨 북마크 요청에 사용"
related: [dna-sql-agent-web]
tags: [bookmark, save-components, message-id, 404]
---

# 차트 북마크 등록 404 — 컴포넌트 저장 행과 메시지 id 불일치

## 증상

```
POST /api/v1/bookmarks  {"message_id": 2061755, "component_id": "39b30d6e-…"}
→ 404 {"detail": "Component not found"}
```

도구를 거친 답변(데이터 조회 → 차트)의 차트를 북마크하면 실패. 특히 대화를 다시 연 뒤에 재현.

## 환경

- **런타임:** FastAPI + asyncpg, Next.js 웹
- **관련 코드:** `dna.middlewares.save_components_middleware`, `dna.bookmarks.routes.create_bookmark`, 웹 `hooks/use-conversations.ts`(행 병합), `components/chat-message.tsx`(북마크 요청)
- **재현 조건:** 한 답변에 assistant 행이 여러 개이고 첫 행에도 컴포넌트가 붙은 경우

## 시도한 것들

1. ❌ "최근 슬래시 커맨드 작업이 저장 방식을 바꿨다"는 가설 — 행별 분배는 8/18 `d953036`, 8/21 `747afba`부터 있었음.
2. ❌ SSE `done`의 `message_id`로 해결 — 답변당 하나이고 "마지막으로 컴포넌트를 저장한 행"이라, 선행 그룹이 첫 행에 붙으면 첫 행 id가 됨. 차트 행과 일치 보장 없음.
3. ✅ 서버 행 보정 + 웹 단계별 행 id.

## 근본 원인

- 한 답변은 도구 호출마다 assistant 행으로 저장(`2061755` 도입 문장+`run_sql`, `2061757` `visualize_data`, `2061759` 최종 답변). 컴포넌트 저장 미들웨어는 도구 호출 행마다 컴포넌트를 나눠 붙여 차트는 `2061757`에 있음.
- 웹은 대화를 불러올 때 같은 답변의 행을 첫 메시지에 합치면서 `backendMessageId`를 옮기지 않아 첫 행 id만 남음.
- 예전에는 앞 행이 내용·컴포넌트 없이 비어 병합 시 건너뛰어져, 합친 메시지의 id가 곧 컴포넌트가 몰린 마지막 행이었다. 과거 북마크 63건이 모두 마지막 행을 가리킨 것이 근거.
- 서버는 요청한 행의 컴포넌트에서만 찾으므로 404.

## 해결 방법

```python
# 서버: 요청 행에 없으면 같은 대화에서 컴포넌트를 담은 행을 찾아 그 행으로 저장
owner = await conn.fetchrow(
    """SELECT id, components, created_at FROM messages
       WHERE conversation_id = $1 AND role = 'assistant' AND components @> $2::jsonb
       ORDER BY id ASC LIMIT 1""",
    row["conversation_id"], json.dumps([{"id": req.component_id}]),
)
```

```ts
// 웹: 행에서 만든 단계에 그 행 id를 붙이고, 북마크는 단계의 행 id를 우선 사용
steps: result.steps.map(step => ({ ...step, sourceMessageId: m.id })),
const backendMessageId = step.sourceMessageId ?? messageBackendId
```

- 컴포넌트 id(UUID)는 전체 DB에서 두 행 이상에 나타나는 경우 0건. `conversation_id` 인덱스로 한 대화 안에서만 찾아 비용이 작음.
- 스트리밍 직후 단계는 행 id를 몰라 서버 보정이 필요.

## 예방책

- 저장 단위(행)와 표시 단위(합친 메시지)가 다르면, 개별 항목에 대한 동작은 표시 단위 id가 아니라 항목 id나 항목의 원래 행 id로 식별.
- 목록·대시보드처럼 저장된 id로 다시 읽는 경로가 있으면 저장 시점에 실제 행으로 맞춘다.

## 관련 페이지

- [[knowledge/troubleshooting/merged-rows-single-id-loses-child-location]]
- [[sessions/2026-09-22-bookmark-row-fix-and-pending-remove]]
- PR: 백엔드 #163, 웹 #94
