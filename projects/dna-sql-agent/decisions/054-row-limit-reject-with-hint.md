---
type: decision-record
project: dna-sql-agent
date: 2026-11-04
status: accepted
superseded-by: ""
tags: [sql-guard, prompt, dialect, row-limit]
---

# ADR-054: DB가 실행 못 하는 행 제한 문법은 고치지 않고 대체 문법 안내와 함께 거절

## 맥락

LLM이 DB와 맞지 않는 행 제한 문법을 자주 썼다. Altibase에 `FETCH FIRST`(SQL 검증에서 차단), Oracle에 `LIMIT`(검증 통과 후 ORA-00933), MySQL·SQLite에 `FETCH`(검증 통과 후 DB 오류). 오류 문구에 대신 쓸 문법이 없어 LLM이 헛도는 재시도로 호출 횟수를 소모했다. sqlglot은 두 문법을 같은 AST로 읽어 DB 문법으로 다시 쓸 수 있다.

## 선택지

### 옵션 A: 실행 직전 행 제한 문법 자동 변환
- **장점:** 추가 호출 없음.
- **단점:** 실행 SQL과 LLM 원본이 달라져 화면·감사·SQL 예제 수집에서 원본이 모호. LLM이 같은 실수를 계속함. 주석 보존·OFFSET 의미 차이(표준 0부터 vs Altibase 1부터) 처리 필요. "이것도 고치자"로 범위가 번질 위험.

### 옵션 B: 검증 단계에서 대체 문법 안내와 함께 거절
- **장점:** 실행 SQL은 항상 LLM 원본. Deny by Default 원칙과 일치. 구현이 작음.
- **단점:** 대화마다 재시도 1회 비용, 새 대화에서는 같은 실수 반복.

### 옵션 C: 프롬프트만 보강
- **장점:** 실수 자체를 줄임.
- **단점:** 이미 `DB type`이 있는데도 틀렸음. 단독으로는 신뢰 불가.

## 결정

옵션 B + C. 중앙 파서(`parse_one_for_dialect`·`parse_for_dialect`)에서 DB별로 실행 못 하는 문법을 거절하고 대체 문법을 안내한다(Oracle `LIMIT` → `FETCH FIRST n ROWS ONLY`/`ROWNUM`, Altibase·MySQL·MariaDB·SQLite `FETCH` → `LIMIT n`, Postgres 제외). 거절은 대화 안에서만 효과가 있으므로 시스템 프롬프트 DB 메타데이터에 현재 DB의 행 제한 문법 한 줄을 추가한다.

## 결과

- `src/dna/utils/sqlglot_dialects/row_limits.py` 신설, Altibase 기존 거절 문구에 대체 문법 추가.
- 가드·비용 추정·마스킹·SQL 예제 검증·수집기 등 중앙 파서를 쓰는 모든 경로에 일관 적용. 원래 DB에서 실패하던 SQL이 실행 전에 실패하는 차이만 있음.
- 로그로 재시도 낭비가 계속 확인되면 옵션 A를 다시 검토.
