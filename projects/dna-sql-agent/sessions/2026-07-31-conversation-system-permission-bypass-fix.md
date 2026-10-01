---
type: session-log
project: dna-sql-agent
date: 2026-07-31
duration: 
focus: "대화 시스템 권한 우회 취약점 수정 — 조회 대상 System 을 서버가 확정하도록 변경"
tools-used: [claude-code]
outcome: success
---

# 2026-07-31 — 대화 시스템 권한 우회 취약점 수정

## 목표

대화별로 묶인 System 에 대해서만 질의할 수 있어야 하는데, 서버가 권한을 확인하지
않아 요청 값을 조작하면 권한 없는 System 을 조회할 수 있었다. 이를 막는다.

## 수행한 작업

1. **취약점 분석** — 클라이언트가 요청 `metadata` 로 보낸
   `system_name`/`connection_name`/`database_id` 를 서버가 검증 없이 그대로
   `user.metadata` 에 복사하고, SQL 실행 대상·RAG 스코프·프롬프트가 모두 그 값을
   신뢰하는 구조임을 확인. `chat_sse` 외에 `chat_websocket`, `chat_poll` 도 동일 경로.

2. **권한 검증 함수 추가** (`crud.py`) — `get_authorized_system_scope`,
   `get_authorized_scope_for_conversation`. 스코프 조회와 권한 검증을 **단일 쿼리로 묶어**
   호출부가 권한 체크를 누락할 수 없게 설계.

3. **대화 생성 API 전환** — `system_name` → `system_id`(UUID) 필수, 권한 없으면 403.
   INSERT 를 조건 블록 밖으로 빼 대화 행이 항상 생성되도록.

4. **채팅 엔드포인트 3곳 수정** — 클라이언트 `metadata` 를 `RequestContext` 에 싣지 않고,
   `conversation_id` 로 대화 레코드에서 스코프를 확정해 주입. 매 요청 권한 재확인.

5. **우회로 차단** — 스코프 덮어쓰기 경로 2곳 제거, DB 에 없는 `conversation_id` 거부.

6. **프론트 대응** — `system_id` 전송, 스코프 metadata 전송 제거, 동명 시스템 오표시
   수정, 403 처리(안내 토스트 + 홈 이동).

7. **문서 갱신** — `docs/multi-db-design.md`, `docs/user-management-design.md`.

## 핵심 결정

- **결정 1:** 클라이언트 metadata 를 덮어쓰는 대신 **아예 싣지 않는다.** 전수 조사 결과
  서버가 읽어야 할 클라이언트 값이 하나도 없어 화이트리스트가 비어 있었다.
  → ADR: [[decisions/029-conversation-system-scope-server-side]]

- **결정 2:** 권한이 회수되면 **거부하지 않고 기본 DB 로 폴백**한다. 기존 대화를 못 쓰게
  되는 것을 피하려는 잠정 처리. 해당 System 에는 접근하지 않으므로 우회는 아니다.

- **결정 3:** 대화 생성은 `system_id`(UUID)로 받는다. `system_name` 은 커넥션 단위로만
  유일해(`uq_system_per_connection`) 이름 단독으로 System 을 특정할 수 없었다.

- **결정 4:** `/chat/[id]` 라우트를 제거한다. 세션(쿠키) 인증 전환 후 서버 검증과 함께
  재도입.

## 배운 것

- **`user.metadata` 에 시스템 정보가 실린 이유**는 vanna 프레임워크가 "에이전트 하나 =
  DB 하나" 전제라 확장 지점들이 `User` 만 받고 `Conversation` 은 안 받기 때문이었다.
  담을 자리가 없어 자유 dict 에 실은 것. 근본 해결은 코어 인터페이스 변경이 필요하다.

- **`database_id` 는 `connection_name` 의 레거시 별칭**이다. 벡터화 job 생성부가
  `database_id=system["connection_name"]` 로 대입하고, 오케스트레이터가
  `WHERE c.connection_name = database_id` 로 조회한다. 문서에도 명시돼 있었다.

- **읽기 경로와 쓰기 경로가 어긋나 있었다.** `get_conversation` 이 DB 에서 읽어
  `conversation.metadata` 에 넣던 스코프 값은 **코드베이스 어디서도 읽지 않는 죽은
  데이터**였고, 실제로 소비되는 건 클라이언트가 채운 `user.metadata` 였다.

- 검증 없는 추론으로 여러 번 잘못된 진단을 했다. 로그 부재를 근거로 삼았다가
  `logger.info` 가 해당 로그 파일에 안 찍히는 걸 나중에 발견한 사례, `ChatHandler` 를
  확인하지 않고 `agent.py` 만 보고 id 생성 주체를 오판한 사례가 있었다.
  **부재를 근거로 쓰기 전에 그 관측 수단이 동작하는지부터 확인할 것.**

## 문제 & 해결

- **문제:** 권한 회수 상태에서 메시지를 보내면 대화의 시스템 정보가 영구 유실
- **원인:** `ChatSaveHook` 이 메시지 저장마다 `ON CONFLICT DO UPDATE` 로 스코프 컬럼을
  갱신하는데, 스코프가 비어 NULL 로 덮어써짐. 권한을 다시 줘도 복구 불가
- **해결:** `DO UPDATE` 에서 스코프 3개 제거. 대화의 System 은 생성 시 확정되며 불변
  (multi-db-design 결정 #1)

- **문제:** 시스템이 삭제된 대화가 동명의 다른 커넥션 시스템 이름으로 정상처럼 표시
- **원인:** 프론트가 `system_name` 단독으로 매칭. 이름은 커넥션 단위로만 유일
- **해결:** `(connection_name, system_name)` 쌍으로 매칭

- **문제:** `/chat/{아무거나}` 로 진입해도 무시되고 URL 에 남음. 콜드 진입 딥링크도 실패
- **원인:** localStorage 인증이라 Next.js 서버가 대화를 조회할 수 없고, 깜빡임 방지로
  렌더링이 layout 으로 올라가(`a00abbc`) URL 이 상태 파생물이 됨. 동기화도 반쪽
- **해결:** 라우트 제거. 클라이언트 우회 시도 4가지 모두 실패해 되돌림
  → 이슈: [[issues/chat-url-conversation-id-decorative]]

- **미해결:** 스코프가 없으면 테이블 접근 제한이 사라짐(fail-open)
  → 이슈: [[issues/sql-guard-fail-open-when-scope-absent]]

- **미해결:** 권한 회수 후에도 대화 이력의 테이블명이 LLM 문맥에 남음
  → 이슈: [[issues/conversation-history-retains-revoked-system-tables]]

## 다음 할 일

- [ ] 브랜치 `fix/system_access_authorization` 푸시 및 PR (백엔드 7커밋, 프론트 6커밋)
- [ ] **백엔드·프론트 동시 배포** — `POST /api/v1/chat` 계약 변경(`system_id` 필수)
- [ ] 기본 DB 접근 정책 결정 → fail-open, 이력 잔존 두 이슈가 여기에 걸려 있음
- [ ] 예외 원문이 클라이언트로 노출되는 문제 — `except Exception` 이 `str(e)` 를 전달하고
      프론트가 채팅창에 렌더. DB 에러 원문으로 스키마 탐색 가능
- [ ] `conversations.database_id` 컬럼 DROP + 응답 필드 제거 (파생으로 통일 완료)
- [ ] conversation id 엔트로피 — `conv_{hex[:8]}` = 32비트, 8만 건에서 충돌 확률 50%
- [ ] (장기) vanna 코어에 System 개념 추가해 `user.metadata` 에서 스코프 분리

## 효과적이었던 프롬프트

```
서버에서 주는 페이징 방식이랑 달라. 그냥 목록에 추가 안 하면 안돼?
```

구현 방향이 복잡해질 때 "그 제약이 정말 필요한가"를 되묻는 형태. 실제로
`activeConversation` 이 배열에서 파생되는 것 외에 목록에 넣을 이유가 없었고,
별도 슬롯으로 분리하니 엣지 케이스가 통째로 사라졌다.

```
database_id가 connection_name인 것이 확실해?
```

확신에 찬 결론에 근거를 다시 요구하는 형태. 쓰기 경로(벡터화 job 생성부)까지
확인하게 만들어 결론이 단단해졌다.
