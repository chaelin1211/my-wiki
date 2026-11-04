---
type: troubleshooting
tags: [database, schema, migration, fresh-install, testing]
---

# 실행 중에 만드는 테이블은 새 DB에서만 터진다 — 기존 환경 E2E로는 못 잡음

## 증상

개발·검증 서버에서는 잘 되던 기능이 새로 설치한 환경에서만 `relation "..." does not exist`(PostgreSQL `UndefinedTableError`)로 실패한다.

## 원인

테이블을 스키마 초기화가 아니라 **특정 기능이 처음 실행될 때** `CREATE TABLE IF NOT EXISTS`로 만드는 코드가 있다. 그 기능이 꺼지거나 실행 조건이 바뀌었는데(모드 전환, 기능 플래그) 다른 코드가 여전히 그 테이블을 읽는 경우다.

- 오래된 환경: 예전에 그 기능이 한 번이라도 돌았으면 테이블이 남아 있어 문제가 안 보임
- 새 환경: 테이블을 만드는 기능이 한 번도 안 돌았으므로 읽는 쪽이 실패

그래서 기존 환경에서 한 E2E·회귀 테스트는 통과하고, 새 설치에서만 드러난다.

## 확인 방법

1. 오류 난 테이블의 `CREATE TABLE` 위치를 찾는다. 스키마 초기화 파일 밖에 있으면 의심
2. 그 생성 코드가 실행되는 조건을 확인한다 (어떤 모드·설정에서만 도는지)
3. 같은 테이블을 읽는 곳이 그 조건 밖에서도 실행되는지 확인한다

## 해결

- 읽는 쪽이 그 기능 전용이면 같은 조건으로 게이트를 건다 (예: [[projects/dna-sql-agent/decisions/051-collection-lease-table-loop-only]])
- 여러 경로에서 쓰는 테이블이면 스키마 초기화로 옮긴다

## 예방

- 규칙: 앱 DB 테이블은 스키마 초기화(마이그레이션) 한 곳에서만 만든다. 소스에서 그 밖의 `CREATE TABLE`을 찾는 검사를 테스트로 둔다
- **빈 DB 설치 테스트**: 빈 DB에 스키마 초기화만 실행한 상태에서 주요 API를 호출한다. 컨테이너 DB(`docker run postgres`)로 수십 초면 된다
- 기능·모드를 제거할 때 판정 로직뿐 아니라 그 기능의 테이블을 읽는 조회·훅까지 찾아본다

## 사례

- [[projects/dna-sql-agent/issues/collection-health-lease-table-missing-on-fresh-db]] — SQL 수집 task 모드 전환 후 loop 전용 lease 테이블 조회가 남아 새 DB에서만 실패
