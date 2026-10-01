---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-31
resolved: false
root-cause: "권한 회수 후에도 대화 이력의 이전 시스템 테이블명이 LLM 문맥에 그대로 남아 재사용됨"
related: []
tags: [security, permission, llm-context, policy]
---

# 권한 회수 후에도 대화 이력의 이전 시스템 테이블명이 LLM 문맥에 남음

## 증상

시스템 권한이 회수된 뒤에도 그 대화에서 질문하면, LLM 이 이전에 조회했던
테이블명을 그대로 써서 SQL 을 만든다. 겉보기에는 "권한을 뺏었는데도 이전
시스템을 계속 조회하는" 것처럼 보인다.

## 환경

- `dna-sql-agent`
- `src/dna/storage/postgres_conversation_store.py` — `get_conversation` 이 대화의
  전체 메시지를 로드
- `src/vanna/core/agent/agent.py` — 로드된 메시지를 LLM 문맥으로 전달

## 근본 원인

권한 검사와 무관한 **기존 동작**이다. 대화의 메시지 이력에는 이전에 조회한
테이블명·SQL·결과가 그대로 들어 있고, 에이전트는 매 요청마다 그 전체를 LLM
문맥으로 넘긴다. 권한이 회수되어도 이력 자체는 남으므로 LLM 은 그 이름들을
계속 참고한다.

**권한 우회는 아니다.** 실제 실행 대상은 서버가 확정한 스코프로 결정되는데,
권한 회수 시 스코프가 비어 `"default"` runner(기본 DB)로 폴백된다. 로그에서
`user.metadata={'source': 'jwt'}` 로 스코프가 비어 있음을 확인했다. 따라서
그 SQL 은 이전 시스템이 아니라 기본 DB 에 대해 실행된다.

혼동하기 쉬운 지점: `.env` 기본 DB 가 그 시스템과 같은 물리 DB 를 가리키면
결과가 동일하게 나와 "이전 시스템을 조회한다"고 오인하게 된다. 다른 DB 라면
`ORA-00942: table or view does not exist` 류의 오류가 난다.

## 해결 방법

미해결. 정책 결정 필요.

| 안 | 내용 |
|---|---|
| A. 현행 유지 | 이력은 사실 기록이므로 보존. 실행 대상만 서버가 통제 |
| B. 읽기 전용 전환 | 권한이 회수된 대화는 조회만 가능하고 새 질문 차단 |
| C. 문맥에서 이력 제외 | 스코프가 없으면 이전 메시지를 LLM 문맥에 넣지 않음 |
| D. 대화 자체 차단 | 권한 회수 시 접근 거부 (2026-07-31 결정과 배치) |

C 는 대화의 연속성을 깨뜨리고, B 는 화면 안내가 함께 필요하다.
[[issues/sql-guard-fail-open-when-scope-absent]] 와 같은 정책(기본 DB 를 어떻게
다룰 것인가) 아래에서 함께 결정하는 것이 맞다.

## 예방책

- "실행 대상"과 "LLM 이 보는 문맥"은 별개의 통제 대상임을 인지할 것. 전자를
  서버가 통제해도 후자에는 과거 정보가 남는다
- 권한 상태 변화가 과거 데이터에 소급 적용되어야 하는지는 기능이 아니라
  정책 문제 — 설계 시점에 정해둘 것

## 관련 페이지

- [[issues/sql-guard-fail-open-when-scope-absent]]
- [[decisions/029-conversation-system-scope-server-side]]
