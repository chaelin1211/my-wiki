---
type: session-log
project: dna-sql-agent
date: 2026-06-10
duration: ~3h
focus: "마스킹 그룹 권한 DB 기반 전환"
tools-used: [claude-code]
outcome: success
---

# 2026-06-10 — 마스킹 그룹 권한 DB 기반 전환

## 목표

- `masking.json`의 `groups` 필드를 제거하고 그룹별 마스킹 액션을 DB로 이관
- 도구 권한 / UI 기능 권한 / 마스킹 권한을 하나의 DB 구조로 통합
- SecurityTab의 "권한 그룹별 처리 방식" 카드를 DB 기반으로 전환

## 수행한 작업

1. **DB 테이블 설계 및 추가** (`schema.py`)
   - `group_permissions` — tool/ui_feature 항목별 허용 그룹 (allowlist)
   - `group_masking_actions` — 마스킹 전략별 그룹 액션 (mask/none/hidden)
2. **백엔드 모듈 신규 작성**
   - `src/dna/group_permissions/__init__.py`, `crud.py`, `routes.py`
   - `src/dna/settings/group_permissions_service.py` — startup 시딩 및 런타임 적용
3. **masking.json 정리** — 모든 전략에서 `"groups"` 필드 제거 (전략 정의만 유지)
4. **시딩 단순화**
   - `_extract_masking_defaults()` 제거 — masking은 초기값 없이 시작, UI에서 설정
   - `seed_from_json_if_empty`에서 masking 파라미터 제거
5. **startup/hot-reload 연결** (`main.py`, `migrations.py`)
   - startup: `seed_and_apply_permissions()` 호출
   - hot-reload: `reload_permissions()` 호출
6. **프론트엔드 전환** (`security-tab.tsx`, `page.tsx`)
   - `MaskingStrategiesCard` — `getMaskingActions()` / `setMaskingActions()` 연결
   - `maskingGroupsSaveRef` / `onMaskingGroupDirtyChange` — SaveBanner 연동
7. **미사용 파일 제거**
   - `components/group-permissions/group-permissions-panel.tsx` (및 디렉토리)
   - `hooks/use-group-permissions.ts`
   - `lib/permission-definitions.ts`

## 핵심 결정

- **masking 초기값 없음:** 기존 `masking.json`의 groups를 코드 상수로 옮기려 했으나, DB가 source of truth이므로 초기값 자체를 없애고 UI에서 설정하는 방식 채택
  → ADR: [[decisions/012-masking-group-actions-db-migration]]
- **두 테이블 분리:** `group_permissions`(allowlist)와 `group_masking_actions`(action값 포함)를 별도 테이블로 분리 — masking은 단순 on/off가 아닌 action 값이 필요하기 때문
- **GroupPermissionsPanel 미사용:** 도구/UI 기능 권한 UI는 별도 탭으로 구성할 계획이었으나 사용자가 기존 탭 구조 변경 거부 → 패널 삭제

## 배운 것

- `masking.json`은 전략 정의(컬럼, 설명)만 담당하고, 그룹별 동작은 DB — 관심사 분리
- `merge_masking_config()` 패턴: JSON 전략 정의에 DB 액션을 오버레이해서 masker에 적용
- 저장만으로는 DB에 들어가고, 설정 적용(hot-reload)을 눌러야 실행 중인 agent에 반영됨

## 문제 & 해결

- **문제:** `_extract_masking_defaults()`가 `masking.json groups` 제거 후 항상 빈 dict 반환
- **해결:** 함수 자체를 제거하고 masking 시딩 로직 폐기 — 초기값 없이 시작

## 다음 할 일

- [ ] 도구 권한 / UI 기능 권한 UI 화면 연결 (백엔드 API는 준비됨)
- [ ] Geomap 시각화 프론트엔드 연동 (leaflet 설치 방향 결정 후)
