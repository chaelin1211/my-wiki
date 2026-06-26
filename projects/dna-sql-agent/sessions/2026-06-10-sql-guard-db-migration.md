---
type: session-log
project: dna-sql-agent
date: 2026-06-10
duration: ~3h
focus: "SQL Guard DB 기반 전환 + 그룹 × 시스템 테이블 접근 제어"
tools-used: [claude-code]
outcome: success
---

# 2026-06-10 — SQL Guard DB 기반 전환 및 그룹 × 시스템 테이블 접근 제어

## 목표

- 하드코딩된 sql_guard.json 기반 테이블 접근 제어를 DB 기반으로 전환
- 그룹 × 시스템 단위 세분화 (기존은 그룹 단위만)
- 가드레일 차단 시 LLM이 쿼리를 재작성해 우회하는 문제 수정
- 실행 쿼리 로그 추가

## 수행한 작업

1. **`group_table_permissions` 테이블 설계 및 마이그레이션**
   - `(group_id UUID, system_id UUID, blocked_tables TEXT[], write_allowed_tables TEXT[])`
   - `UNIQUE(group_id, system_id)` — 그룹 × 시스템 쌍 단위 접근 제어
   - connection → system → table 계층 구조 반영

2. **CRUD 함수 3개 추가** (`crud.py`)
   - `get_group_table_permissions(group_id, system_id)`
   - `upsert_group_table_permissions(...)`
   - `get_group_table_permissions_by_name(group_names, connection_name, system_name)` — 가드레일 전용, 여러 그룹 합집합 반환

3. **API 엔드포인트 추가** (`routes.py`)
   - `GET /admin/groups/{group_id}/table-permissions?system_id=...`
   - `PUT /admin/groups/{group_id}/table-permissions?system_id=...`

4. **SQL Guard 리팩토링**
   - `auth.py`: `get_user_permissions` → async DB 조회로 전환 (connection_name + system_name으로 시스템 특정)
   - `guardrail.py`: `check_ast_guardrail` async 전환, rule별 한국어 차단 메시지 테이블 추가
   - `inspector.py`: `_extract_tables`에 schema-qualified 형식(`schema.table`) 추가 → 스키마별 동명 테이블 차단 지원

5. **LLM 재시도 방지**
   - `validated_run_sql.py`: 차단 시 `result_for_llm`에 `[보안 정책 차단 - 재시도 금지]` + "절대로 재시도하지 마십시오" 지시 포함
   - 실행 쿼리 INFO 로그 추가 (`%.200s` 제한)

6. **코드 리뷰 후 수정**
   - SQL 실행 로그 트런케이션 (`%s` → `%.200s`)
   - `getattr(args, "lat", None)` → `args.lat` (typed 필드 직접 접근)
   - `__init__.py` docstring sync → async 예시로 수정

## 핵심 결정

- **schema.table 형식 차단 지원**: 같은 DB 내 스키마별 동명 테이블이 있는 경우, `hr.employees`와 `fin.employees`를 구분해서 차단할 수 있도록 설계
  → ADR: [[decisions/010-sql-guard-schema-qualified-block]]

- **가드레일 차단 시 LLM 재시도 방지 방법**: loop abort vs result_for_llm 지시 중 후자 선택 — abort 시 LLM이 요약/안내 응답을 못 만들어 UX가 깨짐
  → ADR: [[decisions/011-guardrail-block-no-retry-strategy]]

## 배운 것

- 에이전트 루프에서 tool error는 LLM에 그대로 전달되므로, 차단 메시지에 "재시도 금지" 지시를 명시적으로 포함해야 효과 있음
- `ToolResult.metadata["abort"]`로 루프 중단도 구현 가능하지만, LLM 최종 응답(요약/안내)이 생략되는 UX 문제가 있음

## 문제 & 해결

- **문제:** 가드레일 차단 후 LLM이 3번 재시도해서 결국 우회 성공
- **원인:** `result_for_llm`이 `"SQL validation failed: ..."` 만 반환 → LLM이 오류 메시지를 보고 쿼리 재작성
- **해결:** rule별 한국어 차단 메시지 + "재시도 금지" 명령을 `result_for_llm`에 포함

## 다음 할 일

- [ ] 프론트엔드 group table permissions UI 연동 (security-tab 이미 작업됨, 미커밋)
- [ ] 가드레일 대화 히스토리 차단 문제 검토 — 이전 턴에서 조회한 차단 테이블 결과가 히스토리에 잔류하는 케이스
- [ ] Geomap 시각화 완성 (leaflet/react-leaflet npm install 결정 후 프론트 연동)
