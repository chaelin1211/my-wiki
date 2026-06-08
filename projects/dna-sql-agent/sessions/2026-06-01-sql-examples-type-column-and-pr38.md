---
type: session-log
project: dna-sql-agent
date: 2026-06-01
duration: ~1h
focus: "sql_examples type 컬럼 반영 및 PR #38 생성"
tools-used: [claude-code]
outcome: success
---

# 2026-06-01 — sql_examples type 컬럼 반영 및 PR #38 생성

## 목표

- 세션 시작 시 상태 파악 및 맥락 복원
- PR #33 머지 여부 확인 및 위키 갱신
- `GET /api/v1/db/systems/{conn_id}/{system_name}/sql-examples` 500 오류 원인 파악 및 수정
- `feat/admin-improvements` PR 생성

## 수행한 작업

1. `/wiki-start`로 상태 파악 — PR #33이 이미 MERGED임을 확인, status.md 갱신
2. PR #35 후속 버그 투두 제거 (사용자 요청)
3. sql-examples 500 오류 히스토리 조사
   - `sql_examples` 테이블에 `type bpchar(1) NOT NULL` 컬럼이 production DB에 추가되어 있었으나 코드에 미반영
   - 코드 기준 컬럼이 없어 INSERT 시 NOT NULL 위반 → 500
4. `type CHAR(1)` 컬럼 코드 반영 (3군데)
   - `schema.py`: DDL 및 migration ELSE 분기 (`ADD COLUMN IF NOT EXISTS`)
   - `crud.py`: INSERT에 `type='M'` 고정
   - `models.py`: `SqlExampleResponse`에 `type: str` 추가
5. 타입 값 확인: Auto=`'A'`, Manual=`'M'`
6. 커밋 및 `feat/admin-improvements` push
7. PR #38 생성

## 핵심 결정

- **type 값 규칙:** `CHAR(1)`, `'M'`=화면 직접 입력, `'A'`=자동 수집. 화면 API에서는 `'M'` 고정 삽입, 자동 수집 경로에서는 `'A'`로 INSERT.
- **update 쿼리에서 type 제외:** `("question", "sql", "description", "tags", "status")` 고정 순회 — type은 생성 시점에 결정되므로 변경 불필요

## 문제 & 해결

- **문제:** `GET .../sql-examples` 500 오류
- **원인:** production DB에 `type bpchar(1) NOT NULL` 컬럼이 추가되어 있었으나 코드에 미반영 → RETURNING * 시 type 필드가 None으로 반환되어 Pydantic NOT NULL 검증 실패
- **해결:** schema/crud/models 3곳 반영, 화면 단에서 `'M'` 자동 삽입

## 다음 할 일

- [ ] PR #38 리뷰 및 머지
- [ ] 프론트에서 expires_in 활용한 refresh 인터셉터 연동 확인
- [ ] SQL Guard: group 별 테이블 접근 제한 DB 연동
