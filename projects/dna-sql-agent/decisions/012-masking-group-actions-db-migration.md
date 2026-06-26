---
type: decision-record
project: dna-sql-agent
date: 2026-06-10
status: accepted
superseded-by: ""
tags: [masking, permissions, db, group]
---

# ADR-012: 마스킹 그룹 액션 DB 이관 + 초기값 없음

## 맥락

`masking.json`의 각 전략에 `"groups": {"admin": "none", "user": "mask"}` 형태로 그룹별 액션이 하드코딩되어 있었다. JSON은 재배포 시 초기화되므로 관리자가 변경해도 배포 시 덮어쓰이는 문제가 있었다. 동시에 도구 권한, UI 기능 권한도 JSON으로 관리되고 있어 통합 필요성이 대두됐다.

## 선택지

### 옵션 A: masking.json groups → 코드 상수 _MASKING_DEFAULTS로 이동 후 첫 실행 시 DB 시딩
- **장점:** 초기값이 코드로 명시되어 의도가 명확
- **단점:** 코드에 비즈니스 정책(누가 볼 수 있는지)이 박힘, 재배포 시 시딩 조건 분기 복잡

### 옵션 B: 초기값 없이 DB만 사용, UI에서 직접 설정
- **장점:** JSON과 코드에서 그룹 정책 완전 분리, 단순
- **단점:** 첫 배포 시 마스킹 액션이 없으므로 `default_group_action`(none)이 모두에게 적용됨

## 결정

**옵션 B를 선택한다.**

## 근거

- DB가 source of truth이면 초기값도 DB에서 관리해야 일관성이 있음
- 마스킹 초기 상태는 `default_group_action: "none"` (마스킹 안 함)이 안전한 기본값
- 관리자가 UI에서 설정하는 것이 맞는 흐름

## 결과

- `masking.json`에서 `groups` 필드 완전 제거 — 전략 정의(컬럼, 설명)만 유지
- `group_masking_actions` 테이블에서 전략별 그룹 액션 관리
- `seed_from_json_if_empty`에서 masking 시딩 로직 제거
- 도구/UI 기능 권한은 코드 상수(`_TOOL_DEFAULTS`, `_UI_FEATURE_DEFAULTS`)로 첫 실행 시 시딩 — 이건 개발자 정의 항목이므로 코드 관리가 적합

## 참고 자료

- [[decisions/010-sql-guard-schema-qualified-block]]
