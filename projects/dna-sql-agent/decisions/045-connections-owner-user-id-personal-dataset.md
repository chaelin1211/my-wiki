---
type: decision-record
project: dna-sql-agent
date: 2026-10-01
status: accepted
superseded-by: ""
tags: [personal-dataset, admin, schema]
---

# ADR-045: 개인 데이터셋 구분을 `connections.owner_user_id` 로 한다

## 맥락

관리자 연결·시스템 목록과 사용자 시스템 권한 화면에 사용자마다 생기는 '내 데이터셋'이 노출됐다.
`connections`·`systems` 에는 개인 데이터셋 여부나 소유자 컬럼이 없고, 이름 관례로만 구분됐다.

- 시스템: `system_name = 'personal_datasets'` (유니크 제약은 연결별이라 관리자가 같은 이름을 만들 수 있음)
- 연결: `connection_name = 'sqlite-{sha256(user_id)[:16]}'`

## 선택지

### 옵션 A: 이름 관례로 필터 (`connection_name LIKE 'sqlite-%'` 또는 `system_name`)
- **장점:** 스키마 변경 없음
- **단점:** 로컬 DB 실측 결과 `sqlite-` 연결 17건 중 11건이 관리자가 등록한 BIRD 벤치마크 연결(`sqlite-bird-*`). 공용 연결까지 걸러짐
- **비용/노력:** 작음

### 옵션 B: `connections.owner_user_id UUID NULL` 추가
- **장점:** 개인 여부와 소유자를 한 번에 판단. 이후 사용자 정리·통계에도 사용 가능
- **단점:** 마이그레이션 필요
- **비용/노력:** 마이그레이션 1블록 + 목록 쿼리 조건

## 결정

**옵션 B를 선택한다.** FK 는 걸지 않는다.

## 근거

- 이름 prefix 는 실제 데이터에서 공용 연결과 충돌함을 확인했다
- 기존 개인 연결은 `'sqlite-' || left(encode(sha256(u.id::text::bytea),'hex'),16)` 일치로 소유자를 정확히 채울 수 있다(로컬 6건 매칭, BIRD 11건 미매칭)
- FK `ON DELETE SET NULL` 은 사용자 삭제 시 개인 연결을 공용으로 드러내고, `CASCADE` 는 사용자 삭제 동작을 바꾼다. 현재 사용자 삭제는 소프트 삭제라 FK 가 필요 없다

## 결과

- 목록 API 4종에 `exclude_personal` 옵션(기본 false). 관리자 화면만 true 전달, 위젯 추가 패널은 '내 데이터셋' 표시명 때문에 포함
- 사용자 권한 관리자 API 3종은 항상 제외. `/me/systems` 는 포함
- 그룹 관리자 목록은 `group_connection_mappings` 기준이라 원래 제외됨
- 사용자 비활성화 시 개인 데이터셋은 보존(정책 문서화). 영구 삭제 API 는 없음

## 참고 자료

- 백엔드 `docs/datasets/architecture-review.md`
- 세션: [[projects/dna-sql-agent-web/sessions/2026-10-01-dataset-manager-and-settings-apply-flow]]
