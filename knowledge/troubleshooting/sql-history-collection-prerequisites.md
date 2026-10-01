---
type: knowledge
category: troubleshooting
date: 2026-09-22
tags: [postgresql, mariadb, mysql, pg_stat_statements, performance_schema, sql-collection]
---

# DB 쿼리 이력 수집 전제 조건 — pg_stat_statements·performance_schema

DB가 쌓아 둔 실행 쿼리 통계를 읽어 무언가를 만드는 기능(예: SQL 예제 자동 생성)은 **대상 DB 쪽에서 이력 기록이 켜져 있어야** 동작한다. 앱 설정으로는 해결되지 않는다.

## PostgreSQL — pg_stat_statements

설정이 두 단계로 나뉘고 범위가 다르다.

| 설정 | 범위 | 재시작 |
|---|---|---|
| `shared_preload_libraries`에 `pg_stat_statements` 추가 | 서버(인스턴스)당 1번 | 필요 |
| `CREATE EXTENSION pg_stat_statements;` | DB마다 1번 (조회용 뷰가 DB 단위) | 불필요 |

오류로 어느 단계가 빠졌는지 구분할 수 있다.

| 오류 | 빠진 것 |
|---|---|
| `relation "pg_stat_statements" does not exist` | 접속한 DB에 확장 없음 |
| `pg_stat_statements must be loaded via "shared_preload_libraries"` | 확장은 있으나 서버에 라이브러리 미로드 |

```sql
SHOW shared_preload_libraries;  -- 기존 값 확인
ALTER SYSTEM SET shared_preload_libraries = 'pg_bigm,pg_stat_statements';  -- 기존 값 유지하고 이어 붙이기
-- 재시작 후
SELECT count(*) FROM pg_stat_statements;
```

- 기존 값(예: `pg_bigm`)을 덮어쓰면 그 라이브러리를 쓰는 기능이 깨진다.
- 통계는 서버 전체를 모으지만 조회는 접속한 DB의 뷰로 한다. 다른 계정의 쿼리 원문까지 보려면 `pg_read_all_stats` 역할 필요.
- 재시작 직후 통계는 비어 있다.

## MariaDB / MySQL — performance_schema

| 항목 | 범위 | 재시작 |
|---|---|---|
| `my.cnf`의 `[mysqld]`에 `performance_schema=ON` | 서버당 1번 | 필요 (실행 중 변경 불가) |
| 수집 계정에 `GRANT SELECT ON performance_schema.* TO ...` | 계정당 | 불필요 |

- **MariaDB는 기본값이 OFF**(MySQL 5.6 이상은 기본 ON).
- 꺼져 있으면 `events_statements_summary_by_digest` 테이블은 존재하지만 비어 있어 **오류 없이 0건**. 켜졌는지 `SHOW VARIABLES LIKE 'performance_schema';`로 확인.

## 함정 — 조용한 0건

수집기가 예외를 로그로만 남기고 빈 목록을 돌려주면, 작업은 "완료 · 0건"으로 끝나 원인이 화면에 드러나지 않는다. 수집 결과가 0건이면 먼저 대상 DB 설정과 서버 로그의 수집기 오류를 확인한다.

## 실제 사례

- [[projects/dna-sql-agent/sessions/2026-09-22-bookmark-row-fix-and-pending-remove]] — dnasql_agent DB의 `shared_preload_libraries`에 `pg_bigm`만 있어 SQL 예제 AI 생성이 0건으로 끝남.
