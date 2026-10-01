---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-13
resolved: true
root-cause: "그룹 마스킹 액션이 DB와 config 파일 두 곳에 있었고, 리로드 경로가 파일 사본을 다시 읽어 DB 값을 덮어씀"
related: [masking, settings, hot-reload]
tags: [configuration, masking, duplicate-source]
---

# 설정 리로드하면 마스킹 그룹 액션이 옛 값으로 되돌아감

## 증상

관리자 화면에서 그룹별 마스킹 액션을 바꾸고 저장하면 적용된다. 그런데
`POST /api/v1/settings/reload` 나 그룹 권한 리로드가 한 번 돌면 **바꾸기 전 동작으로
돌아간다.** 에러는 나지 않는다. 개인정보 컬럼이 가려져야 하는데 그대로 나오거나,
반대로 관리자에게도 가려진다.

## 환경

- **관련 파일:** `src/dna/settings/group_permissions_service.py`,
  `src/dna/settings/masking_runtime.py`, `src/dna/utils/masking/column_masker.py`
- **재현 조건:** 그룹 마스킹 액션 변경 후 `reload_permissions()` 호출

## 시도한 것들

1. ❌ 리로드 순서 조정 — 파일을 먼저 읽든 나중에 읽든, 파일 값이 최종 상태에 섞이는 한 같다
2. ✅ 리로드 경로에서 `SettingsManager().load("masking")` 자체를 제거

## 근본 원인

그룹별 마스킹 액션의 출처가 **두 곳**이었다.

- 정본: `group_masking_actions` 테이블 (DB) — 화면에서 바꾸면 여기 저장된다
- 사본: `config/masking.json` 의 `strategies.*.groups` — 예전 구조의 잔재

`reload_permissions()` 는 DB 에서 `get_masking_actions()` 를 읽으면서, 동시에
`SettingsManager().load("masking")` 로 파일도 읽어 `_apply_masking_permissions()` 에
같이 넘겼다. 그 결과 파일에 남아 있던 옛 그룹 액션이 DB 값 위에 덮였다.

같은 뿌리의 문제가 세 번 반복됐다. `masking_rules.json` 사본, `defaults` 와 `.env`
양쪽의 마스킹 규칙, 그리고 이번 건이다. **같은 값이 두 곳에 있으면 언젠가 갈라진다.**

## 해결 방법

```python
# group_permissions_service.py — reload_permissions()
-    from dna.settings.manager import SettingsManager
-    masking_json = SettingsManager().load("masking")
     ...
-    _apply_masking_permissions(masking_json, masking_actions)
+    _apply_masking_permissions(masking_actions)
```

앞선 커밋에서 그룹 액션 전달 경로를 config 파일 사본이 아니라 런타임 캐시
(`settings/masking_runtime.py`)로 바꿔 두었고(`4925767`), 리로드 경로만 옛 코드가
남아 있었다. 이 호출을 지우면서 정본이 DB 하나로 정리됐다.

함께: 그룹 목록에 없는 그룹의 기본 동작을 `none` → `mask` 로 바꿨다(`0a95018`).
모르는 그룹은 가리는 쪽이 안전하다 — fail-closed.

## 예방책

- 값의 정본을 하나로 정하고, 나머지 경로는 **읽지 않는다**. "일단 둘 다 읽어서 합친다"
  가 이 버그의 형태다
- 구조를 옮길 때 쓰기 경로만 바꾸고 **리로드/부팅 경로를 놓치기 쉽다.** 같은 값을
  읽는 곳을 전부 grep 해서 확인할 것
- `config/*.json` 에서 제거한 필드는 defaults 에서도 지운다. 남아 있으면 언젠가
  누군가 다시 읽는다

## 관련 페이지

- [[projects/dna-sql-agent/decisions/012-masking-group-actions-db-migration]]
- [[projects/dna-sql-agent/decisions/034-defaults-as-config-validation-spec]]
- [[projects/dna-sql-agent/sessions/2026-08-13-config-spec-validation-and-docs-consolidation]]
