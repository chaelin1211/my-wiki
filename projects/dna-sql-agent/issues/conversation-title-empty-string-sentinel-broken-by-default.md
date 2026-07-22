---
type: issue
project: dna-sql-agent
date: 2026-07-06
status: resolved
tags: [chat, sentinel-value, regression]
---

# 새 대화 제목이 첫 메시지로 자동 갱신되지 않는 문제

## 증상

새 대화를 시작하면 제목이 항상 "새 대화"로 고정되고, 첫 사용자 메시지를 보낸 뒤에도 제목이 그 메시지 내용으로 바뀌지 않았다. 화면에는 "새 대화"라는 placeholder성 제목이 그대로 남는다.

## 근본 원인

`ChatSaveHook.after_message`는 대화 저장(upsert) 시 다음 SQL로 제목을 갱신한다:

```sql
title = CASE WHEN conversations.title = '' THEN EXCLUDED.title ELSE conversations.title END
```

즉 `title`이 **빈 문자열(`''`)**일 때만 첫 메시지로 덮어쓰는 "센티널 값" 패턴이다. 그런데:

1. 백엔드 `create_conversation` 핸들러가 `title`이 없을 때 기본값을 `""`이 아니라 `"새 대화"`로 저장하도록 바뀌어 있었다. → 센티널 조건(`title = ''`)이 절대 참이 될 수 없게 됨.
2. 프론트 `use-conversations.ts`의 `createConversation` 호출부도 명시적으로 `'새 대화'` 문자열을 title로 넘기고 있었다. → 백엔드 기본값과 무관하게 애초에 빈 문자열이 저장될 일이 없었음.

두 지점이 각각 별도 시점에 "새 대화라는 제목을 보여주자"는 의도로 수정되면서, 둘 다 센티널 값 자체를 오염시킨 것이 원인이다.

## 해결

- 백엔드: `create_conversation`에서 title이 없으면 `""`을 저장하도록 복원 (`src/dna/chat/routes.py`)
- 프론트: `createConversation(systemName)` 호출 시 title 인자를 아예 넘기지 않도록 수정 (`hooks/use-conversations.ts`)
- 화면에 "새 대화"라고 보여주는 것은 유지하되, 이는 클라이언트 로컬 상태의 placeholder(`title: '새 대화'`)로만 존재하고 실제 저장값과는 분리했다.

## 예방책

여러 곳(프론트/백엔드, 혹은 같은 레이어의 여러 함수)에서 "센티널 값"을 공유하는 패턴은, 센티널을 재정의하거나 기본값을 바꾸는 수정을 할 때 그 센티널을 실제로 소비(consume)하는 모든 지점을 먼저 grep으로 찾아 확인해야 한다. 이번 경우 `title = ''` 체크가 유일한 소비 지점이었는데, 이를 모르고 두 곳에서 독립적으로 "친절한 기본값을 보여주자"는 수정을 하면서 센티널이 깨졌다.

## 관련

- [[sessions/2026-07-06-admin-pagination-dialog-fixes-and-perf]]
