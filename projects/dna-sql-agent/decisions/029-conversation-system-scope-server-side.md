---
type: decision-record
project: dna-sql-agent
date: 2026-07-31
status: accepted
superseded-by: ""
tags: [security, permission, multi-db, api]
---

# ADR-029: 대화의 조회 대상 시스템을 서버가 확정한다

## 맥락

대화는 생성 시 하나의 System 에 묶이고, 그 System 의 DB 에 대해서만 질의할 수
있어야 한다(multi-db-design 결정 #1). 그런데 실제 구현은 조회 대상을 **클라이언트가
매 요청 metadata 로 전달**하고 서버가 그대로 사용하는 구조였다.

```
클라이언트 요청 body
  metadata: { system_name, connection_name, database_id }
        │
        └─ 서버가 그대로 복사 → RequestContext → user.metadata
                                    │
                                    └─ SQL 실행 대상 DB, RAG 스코프, 프롬프트 결정
```

`system_name` 을 조작해 보내면 **권한 없는 System 을 조회**할 수 있었다. 서버에
권한을 확인하는 코드가 없었고, `docs/user-management-design.md` 에는
"권한 체크는 Agent 레벨(system_name 라우팅)에서 구현됩니다"라고 적혀 있었으나
그 `system_name` 의 출처가 검증되지 않은 클라이언트 입력이었다.

같은 경로가 `chat_sse` 외에 `chat_websocket`, `chat_poll` 에도 있었다.

배경 원인: vanna 프레임워크는 "에이전트 하나 = DB 하나" 전제라 확장 지점
(`SystemPromptBuilder`, `LlmContextEnhancer`, `ToolContext`)이 모두 `User` 만 받고
`Conversation` 은 받지 않는다. dna 레이어가 "System 여러 개 + 사용자별 권한"이라는
축을 얹으면서, 담을 자리가 없어 자유 dict 인 `user.metadata` 에 실어 보낸 것이다
(`a4c957f`).

## 선택지

### 옵션 A: 클라이언트 값을 서버 값으로 덮어쓰기
- **장점:** 변경 범위 최소
- **단점:** 블랙리스트 방식 — 새 스코프 키가 생기면 빠뜨리기 쉬움
- **비용/노력:** 소

### 옵션 B: 클라이언트 metadata 를 아예 싣지 않고, 서버가 확정한 값만 주입
- **장점:** 화이트리스트 방식. 클라이언트 값이 도달할 경로 자체가 없어짐
- **단점:** 클라이언트가 전달해야 할 값이 생기면 명시적으로 추가해야 함
- **비용/노력:** 소 (엔드포인트 3곳)

### 옵션 C: vanna 코어에 System 개념 추가
- **장점:** 근본 해결. `user.metadata` 에서 스코프를 분리
- **단점:** `SystemPromptBuilder`/`LlmContextEnhancer`/`ToolContext` 등 코어 인터페이스
  4개 변경 + 소비자 8개 파일
- **비용/노력:** 대

## 결정

**옵션 B를 선택한다.** 옵션 C는 별건으로 분리한다.

- 세 엔드포인트(`chat_sse`/`chat_websocket`/`chat_poll`) 모두 클라이언트 `metadata` 를
  `RequestContext` 에 싣지 않는다
- `conversation_id` 로 대화 레코드에서 시스템을 조회하고 **매 요청 권한을 재확인**한 뒤
  스코프를 주입한다 (`crud.get_authorized_scope_for_conversation`)
- 대화 생성은 `system_name` 이 아니라 `system_id`(UUID)를 받고 권한을 확인한다
- 대화의 System 은 생성 시점에 확정되며 이후 변경되지 않는다

## 근거

**클라이언트 metadata 에서 서버가 실제로 읽어야 할 값이 하나도 없었다.** 전수 조사
결과 소비되는 키는 스코프 3개(`system_name`/`connection_name`/`database_id`)와
`starter_ui_request` 뿐이었고, 후자는 프론트가 보내지 않으며 빈 메시지로도 같은
동작이 가능하다. 즉 화이트리스트가 비어 있어 "아예 싣지 않기"가 가능했다.

`system_id` 로 바꾼 이유는 별개다. `system_name` 은 `uq_system_per_connection` 으로
**커넥션 단위로만 유일**한데, 기존 생성 API 는 이름 단독으로 `fetchrow` 조회해
동명의 다른 커넥션 시스템이 선택될 수 있었다. UUID PK 로 이 모호성이 사라진다.

## 결과

### 트레이드오프

- **권한 회수 시 거부하지 않고 기본 DB 로 폴백한다.** 기존 대화를 못 쓰게 되는 것을
  피하려는 잠정 처리이며, 해당 System 에는 접근하지 않으므로 우회는 아니다.
  정책 확정 시 재검토 대상 → [[issues/sql-guard-fail-open-when-scope-absent]]
- **대화 이력의 이전 시스템 테이블명은 LLM 문맥에 남는다.** 실행 대상은 서버가
  통제하지만 문맥은 그대로다 → [[issues/conversation-history-retains-revoked-system-tables]]
- `user.metadata` 에 스코프가 남아 있는 구조는 그대로다. 보안 문제는 아니게 됐으나
  개념적으로는 대화 속성이 사용자 속성에 실려 있다(옵션 C 대상).

### 함께 수정한 것

- **대화의 시스템 정보 유실 버그** — `ChatSaveHook` 이 메시지 저장마다
  `ON CONFLICT DO UPDATE` 로 스코프를 갱신해, 권한 회수 상태에서 메시지를 보내면
  NULL 로 덮어써져 영구 유실됐다. 권한을 다시 줘도 복구되지 않았다
- **동명 시스템 오표시** — 프론트가 `system_name` 단독으로 매칭해, 대화가 묶인
  시스템이 삭제되면 동명의 다른 커넥션 시스템 이름이 정상처럼 표시됐다
- **접근 불가 대화 미처리** — 서버가 거부해도 클라이언트가 인지하지 못해 빈 응답만
  남았다. 403 으로 응답하고 안내 후 홈으로 이동하도록 변경
- `database_id` 가 `connection_name` 의 레거시 별칭임을 확인하고, 저장 대신 파생으로
  통일 (`COALESCE(database_id, connection_name)`)

### 영향받는 컴포넌트

- API 계약 변경: `POST /api/v1/chat` 이 `system_id` 필수 → **백엔드·프론트 동시 배포 필요**
- `chat_sse` 가 접근 불가 시 403 응답 (기존 200 + SSE forbidden 이벤트)

### 향후 재검토

- 기본 DB(`.env` 기반 `"default"` runner) 접근 정책이 정해지면 폴백 동작 재검토
- vanna 코어에 System 개념 도입(옵션 C) 시 이 결정의 주입 지점이 단순해짐

## 참고 자료

- `docs/multi-db-design.md` 결정 #1, #12, §4.1
- `docs/user-management-design.md` §5.1
- 브랜치 `fix/system_access_authorization` — 백엔드 7커밋, 프론트 6커밋
