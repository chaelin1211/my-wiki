---
type: decision-record
project: dna-sql-agent
date: 2026-06-10
status: accepted
tags: [sql-guard, security, schema]
---

# ADR-010: SQL Guard 차단 테이블 schema.table 형식 지원

## 맥락

같은 DB 커넥션 안에 스키마가 여러 개 있고, 각 스키마에 동명 테이블이 존재하는 경우 (`hr.employees`, `fin.employees`) 테이블명만으로는 특정 스키마의 테이블만 차단하기 어렵다. 기존 `_extract_tables`는 unqualified 이름(`employees`)만 추출했음.

## 선택지

### 옵션 A: unqualified 이름만 사용 (기존)
- **장점:** 단순
- **단점:** `employees`를 차단하면 모든 스키마의 employees 테이블이 차단됨 — 과도 차단

### 옵션 B: schema-qualified 이름도 추출 (선택)
- **장점:** `hr.employees` 차단 시 `fin.employees`는 허용 가능, 세밀한 제어
- **단점:** blocked_tables 입력 시 스키마를 명시해야 하는 UX 부담

### 옵션 C: 시스템 레벨 스키마 컨텍스트 활용
- **장점:** 시스템 정의 시 스키마를 지정하므로 맥락 내 자동 처리 가능
- **단점:** 구현 복잡도 높음, 현재 시스템 스키마 필터와 맞물림

## 결정

**옵션 B를 선택한다.**

`_extract_tables`에서 `table.name`(unqualified)과 `table.db.table.name`(schema-qualified) 양쪽을 frozenset에 포함. blocked_tables에 `hr.employees`가 있으면 schema-qualified 매칭, `employees`만 있으면 모든 스키마 매칭.

## 근거

- 가장 적은 코드 변경으로 세밀한 제어 가능
- 기존 행동(unqualified 차단 = 전체 차단)과 하위 호환
- 관리자가 `SCHEMA.TABLE` 형식으로 입력하면 특정 스키마만 차단 가능

## 결과

- blocked_tables 입력 UI에 `SCHEMA.TABLE_NAME` 형식 안내 필요
- `table.db`가 None이면 unqualified만 추가 (기존 동작 유지)
- sqlglot이 dialect에 따라 `table.db` 파싱 방식이 다를 수 있음 — 테스트 필요
