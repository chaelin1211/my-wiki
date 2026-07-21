---
type: decision-record
project: dna-sql-agent
date: 2026-07-21
status: accepted
superseded-by: ""
tags: [auth, permissions, group-admin]
---

# ADR-025: 기본 그룹의 접근 권한 초기화 기준 — `default_accessible` 단일화

## 맥락

시스템 접근 권한을 신규/재편입 사용자에게 자동으로 부여하는 경로가 두 개
존재했다:

1. `systems.default_accessible` (시스템 단위 전역 플래그) — `register()`
   엔드포인트가 가입 시점에 이 플래그가 켜진 시스템을 그룹 매핑 여부와
   무관하게 자동 부여.
2. `group_system_mappings.default_grant` (그룹 단위 플래그, §4.3) —
   `move_user_group()`이 그룹 이동/재편입 시 대상 그룹의 이 매핑만 보고
   재부여.

`move_user_group()`은 이동할 때마다 `user_system_permissions`를 전량
삭제한 뒤 위 2번 기준으로만 다시 채운다. 문제는 **기본 그룹(`is_default`)에는
애초에 그룹 관리자가 없어 `default_grant` 매핑이 관리되지 않는다는 것** —
그래서 그룹 이동으로 기본 그룹에 들어오는(예: 그룹 관리자에게 추방된)
사용자는 매번 권한이 0개로 초기화되는 실제 버그가 있었다. 반면 최초
가입자는 1번 경로 덕분에 정상적으로 권한을 받고 있어 불일치가 컸다.

## 선택지

### 옵션 A: 기본 그룹에도 `default_grant` 매핑을 쓸 수 있게 한다
- **장점:** 두 경로가 결국 하나(`group_system_mappings`)로 통일됨
- **단점:** 기본 그룹은 그룹 관리자가 없다는 정책(§2, §4.7 계열)과 충돌 —
  그 매핑을 대신 누가 관리할지 새 역할/화면이 필요해짐

### 옵션 B: 기본 그룹은 `default_accessible` 하나로 통일한다
- **장점:** 이미 `register()`가 쓰고 있는 경로라 새 개념이 필요 없음.
  "기본 그룹 = 그룹 관리자 없음 = 커넥션 위임도 없음"이라는 기존 정책과
  일관됨 — 대신 시스템 관리자가 시스템 단위로 전역 기본값을 관리
- **단점:** 여전히 두 개의 서로 다른 "기본 권한" 축(시스템 전역 vs
  그룹별)이 공존 — 다만 각자 적용 범위가 겹치지 않게 명확히 분리됨

## 결정

**옵션 B.** `move_user_group()`에 분기를 추가해, 대상 그룹이 `is_default`면
`default_grant` 매핑 대신 `register()`와 동일한 `systems.default_accessible
= true` 쿼리로 재부여한다. 비-기본 그룹은 기존대로 `default_grant`를 따른다.

부수적으로 기본 그룹에는 애초에 그룹 관리자 지정과 커넥션 위임 자체를
서버에서 거부하도록 막았다(`assign_group_admin`, `create_group_connection_mapping`
둘 다 `is_default` 체크 후 422) — 정책이 코드로 강제되지 않고 "화면에서만
안 보이게" 남아있는 상태를 피하기 위함.

## 근거

- 기본 그룹은 [[decisions/024-connection-delegation-model|ADR-024]]의
  위임 모델 대상에서 애초에 제외된 그룹이다 — 그 모델(그룹 관리자가
  커넥션/시스템을 관리)이 적용 안 되는 곳에 `default_grant`(그 모델의
  일부)를 억지로 쓰는 것보다, 이미 존재하는 전역 플래그로 통일하는 쪽이
  더 적은 개념으로 같은 결과를 낸다.
- 서버 단 차단을 추가한 이유: UI만 숨기면 API를 직접 호출해 정책을 우회할
  수 있고, 그 상태로 며칠만 지나도 "왜 이 기본 그룹에 관리자가 있지?"
  같은 정합성 문제가 재발할 수 있다.

## 결과

- `systems.default_accessible`은 이제 "기본 그룹 전용 접근 제어" 축으로
  역할이 명확해졌다 — 비-기본 그룹에서는 이 플래그의 의미가 없다(읽는
  코드가 없음). UI(시스템 수정 다이얼로그의 "기본 접근 허용" 토글)의
  설명 문구를 이참에 "기본 그룹 사용자에게..."로 더 명확히 할 여지가 있음
  (이번엔 안 건드림 — 후속 과제).
- `test_group_admin.py`에 대상 그룹이 기본 그룹일 때/아닐 때 각각의 재부여
  SQL을 검증하는 테스트 추가.

## 참고 자료

- 이전 결정: [[decisions/024-connection-delegation-model]]
- 정책 문서: `dna-sql-agent/docs/group-admin-design.md` v0.6 §4.3, §7 #11
- 상태 로그: [[projects/dna-sql-agent/status|status.md]] 2026-07-21
