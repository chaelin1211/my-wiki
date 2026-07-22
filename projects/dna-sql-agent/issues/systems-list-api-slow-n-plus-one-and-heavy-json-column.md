---
type: issue
project: dna-sql-agent
date: 2026-07-06
status: resolved
tags: [performance, postgres, n-plus-one, json]
---

# 시스템 목록 API(`/systems`, `/systems/paged`) 응답 지연

## 증상

관리자 화면의 시스템 목록 조회가 느렸다. 페이징을 도입한 이후에도(20건만 조회하도록 줄였음에도) 체감 지연이 남아 있었다.

## 시도한 것들

- ❌ **N+1 배치화만으로는 부족**: 시스템별 벡터화 job 상태 조회가 시스템 개수만큼 반복 쿼리되던 것을 `unnest` + `ROW_NUMBER() OVER (PARTITION BY ...)` 패턴으로 한 번에 배치 조회하도록 고쳤지만, 체감 속도는 거의 개선되지 않았다.
- ❌ **전역 무필터 stale job 복구가 오히려 더 느려짐**: 매 요청마다 `recover_stale_vectorization_jobs()`를 필터 없이 전체 테이블에 대해 호출하도록 추가했더니, 오히려 응답이 더 느려졌다(0.2초 vs 이전). 이 함수는 이미 오케스트레이터 시작 시(`Orchestrator.start()`) 한 번 호출되므로 요청마다 다시 돌 필요가 없었다.
- ✅ **페이지 범위로 좁힌 배치 stale 복구 + 불필요한 대용량 컬럼 제거**: stale job 복구를 현재 페이지에 있는 시스템들로만 범위를 좁히고(`recover_stale_vectorization_jobs_batch`), 결정적으로 `SELECT s.*` 대신 실제로 쓰는 컬럼만 선택하도록 바꿨다.

## 근본 원인

`systems` 테이블의 `table_relation_info` 컬럼은 시스템 전체 테이블 관계 그래프를 담은 대용량 JSON(수백 KB 이상 가능)이다. 그런데 목록 조회 API는 이 컬럼에서 `metadata` 하위 객체 하나만 읽어서 상태/진행률 파생 필드(`relation_info_status` 등)를 계산하는 데 쓴다. `SELECT s.*`로 조회하면 이 무거운 JSON 전체를 매번 DB→앱 서버로 전송하고 파싱해야 했다 — 이게 진짜 병목이었다.

## 해결

SQL 단에서 필요한 하위 객체만 추출하도록 축소:

```sql
json_build_object('metadata', s.table_relation_info -> 'metadata') AS table_relation_info
```

`SystemResponse` Pydantic 모델이 애초에 `table_relation_info` 원본을 필드로 노출하지 않고 파생 필드만 노출한다는 것을 확인한 뒤 안전하게 적용했다.

## 예방책

"API가 느리다"는 문제는 쿼리 개수(N+1)뿐 아니라 `SELECT *`가 끌고 오는 컬럼 크기(특히 대용량 JSON/TEXT 컬럼)도 항상 함께 의심해야 한다. 이번 케이스는 쿼리 개수 문제를 먼저 고쳤지만 실제 지배적 원인은 페이로드 크기였다. 목록/페이징 API처럼 자주 호출되는 엔드포인트는 처음부터 필요한 컬럼만 명시적으로 선택하는 것이 안전하다.

## 관련

- [[decisions/021-admin-list-server-side-pagination]]
- [[sessions/2026-07-06-admin-pagination-dialog-fixes-and-perf]]
