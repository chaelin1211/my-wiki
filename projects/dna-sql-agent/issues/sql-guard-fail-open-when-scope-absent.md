---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-31
resolved: false
root-cause: "시스템 스코프가 없으면 그룹 테이블 권한 조회를 건너뛰고 '차단 없음'을 반환 — 기본 DB 경로가 테이블 제한 밖에 놓임"
related: []
tags: [security, permission, sql-guard, policy]
---

# 시스템 스코프가 없으면 테이블 접근 제한이 통째로 사라짐 (fail-open)

## 증상

`src/dna/utils/sql_guard/auth.py:21-28`:

```python
if not group_names or not connection_name or not system_name:
    logger.debug("... 컨텍스트 없음, 권한 없이 통과")
    return {"blocked_tables": set(), "write_allowed_tables": set()}
```

`connection_name`/`system_name`(이하 스코프)이 비어 있으면 `group_table_permissions`를
조회하지 않고 **"차단 테이블 없음 = 전부 허용"**을 반환한다. 관리 화면에서 그룹별로
차단 테이블을 걸어두었더라도 이 경로에서는 제한이 적용되지 않는다.

같은 fail-open이 시스템 프롬프트에도 있다 —
`src/dna/prompt_builders/dna_system_prompt_builder.py:149`의
`if system_name and connection_name:` 블록을 건너뛰면서 LLM 에게 명시적으로 알린다:

```
## 현재 테이블 접근 정책
차단된 테이블: 없음. 모든 테이블에 접근 가능합니다.
```

## 환경

- `dna-sql-agent`
- `src/dna/utils/sql_guard/auth.py` — 테이블 단위 접근 제어
- `src/dna/prompt_builders/dna_system_prompt_builder.py:142-180` — 프롬프트 생성

## 근본 원인

스코프가 비는 것을 "예외 상황"으로 보고 통과시켰으나, 실제로는 **정상 경로**다.
2026-07-31 권한 검증 작업 이후 스코프가 비는 경우는 다음 세 가지다:

| 경우 | 배경 |
|---|---|
| 시스템 미지정 레거시 대화 | `conversations.system_name` nullable — multi-db-design 결정 #12 |
| 권한 회수·시스템 삭제 후 폴백 | 기존 대화를 못 쓰게 되는 것을 피하려는 잠정 처리 |
| 권한 0개 사용자의 대화 | 시스템 선택 없이 생성되는 fallback 대화 |

이 세 경로는 모두 `"default"` runner, 즉 `.env`의 `DB_*`로 만든 기본 DB를 조회한다.
그 DB는 `connections`/`systems` 테이블에 등록되지 않은 별도 커넥션이라
`group_table_permissions`에 규칙을 걸 대상 자체가 없다. **관리 화면의 권한 체계
바깥에 있다.**

## 해결 방법

미해결. 단순히 fail-closed로 바꾸면 위 세 경로가 전부 막혀
"기존 대화는 계속 쓸 수 있어야 한다"는 요구와 충돌한다.

선택지:

| 안 | 내용 | 평가 |
|---|---|---|
| A. 보류 | 기본 DB 정책이 정해질 때까지 현행 유지 | 현재 선택 |
| B. 기본 DB 전용 스코프 도입 | `"default"` 를 가상 시스템으로 등록해 `group_table_permissions` 규칙을 걸 수 있게 | **근본적**. 정책·화면 작업 수반 |
| C. 프롬프트 문구만 완화 | "모든 테이블 접근 가능" 문장 제거 | 실효 작음 |
| D. fail-closed | 스코프 없으면 거부 | 레거시·폴백 대화 차단 — 현 결정과 배치 |

B가 근본 해결이다. 기본 DB에도 테이블 제한을 걸 수 있게 되면 fail-open 자체가
문제가 아니게 된다.

**선행 결정 필요:** 로그인만 하면 누구나 접근 가능한 기본 DB를 계속 유지할 것인가.
현재는 정책이 없어 열려 있는 상태다.

## 예방책

- 접근 제어에서 "컨텍스트 없음"을 통과로 처리하지 말 것. 통과가 필요하면 그것이
  정상 경로임을 명시하고, 그 경로에도 규칙을 걸 수 있는 수단을 함께 마련
- 새로운 fallback 경로를 만들 때 그 경로가 기존 권한 검사 밖으로 나가는지 확인

## 관련 페이지

- [[issues/conversation-history-retains-revoked-system-tables]]
- [[decisions/029-conversation-system-scope-server-side]]
