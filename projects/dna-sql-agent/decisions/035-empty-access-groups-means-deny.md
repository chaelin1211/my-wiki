---
type: decision-record
project: dna-sql-agent
date: 2026-08-14
status: accepted
superseded-by: ""
tags: [permissions, fail-open, tool-access, security]
---

# ADR-035: 도구 허용 그룹이 비면 거부한다

## 맥락

도구 접근 판정이 허용 그룹 목록이 비었을 때 통과시켰다.

```python
if not tool_access_groups:
    return True
```

여기에 두 가지가 겹쳐 fail-open 이 됐다.

- 모든 도구는 `access_groups=[]` 로 등록된다. 권한 정본이 DB 이기 때문이다.
- 권한 회수는 DB 행 삭제로 구현돼 있어, **"한 번도 설정한 적 없음"과 "관리자가 전부 해제함"이 구분되지 않는다.**

결과적으로 관리자가 어떤 도구의 그룹을 모두 해제하면 의도와 정반대로 전원에게 열렸다.
증상과 원인은 [[projects/dna-sql-agent/issues/tool-permission-revoke-all-becomes-allow-all]] 에 정리돼 있다.

## 선택지

### 옵션 A: 빈 목록을 거부로 뒤집는다

판정 한 곳을 바꾸면 끝나지만, 시딩이 확실하지 않으면 기존·신규 설치가 통째로 막힌다.

### 옵션 B: `None` 과 `[]` 를 구분한다

`None` = 미설정(허용), `[]` = 전부 차단. 의미는 가장 정확하지만 타입을 바꿔야 하고,
DB 는 여전히 "행 없음" 하나로만 표현되므로 경계에서 다시 모호해진다.

### 옵션 C: 그대로 두고 화면에서 막는다

관리자 화면이 "전부 해제"를 못 하게 한다. API 로는 여전히 가능하고, 근본 원인이 남는다.

## 결정

**옵션 A.** 빈 목록을 거부로 뒤집되, 막히지 않도록 시딩 경로를 먼저 보강했다.

- 판정을 `registry.has_tool_access()` 하나로 모았다. 실행(`_validate_tool_permissions`)·스키마 노출(`get_schemas`)·결과 출력(`agent.can_see_tool_output`) 세 벌이 각자 복제하고 있어 어긋날 여지가 있었다.
- `_apply_tool_permissions()` 를 레지스트리 전체 순회로 바꿨다. DB dict 만 순회하면 행이 사라진 도구는 손이 닿지 않아 옛 권한이 남는다.
- 최초 설치에서 전 도구에 `pending_permission_seed` 를 붙이도록 했다. 이전에는 설정 파일을 만든 뒤 비교해서 "새 도구 없음"으로 판정돼 시딩이 아예 돌지 않았다.
- 추측 기반이던 `seed_from_json_if_empty()`(테이블이 비면 신규 설치로 간주)는 삭제했다. 권한을 전부 지운 상태와 구분되지 않아, 남겨두면 관리자가 뺀 권한이 재기동 때 되살아난다.

`B` 는 DB 표현이 그대로라 경계에서 같은 모호함이 반복되고, `C` 는 원인을 남긴다.

## 결과

- 관리자의 "전부 해제"가 의도대로 동작한다.
- 미등록 DB 키는 경고로 남아, 도구 클래스명이 바뀌어 권한이 끊기면 로그로 드러난다.
- **DB 를 못 읽으면 도구가 전부 막힌다.** `sql_guard` 의 `fail_closed`, 마스킹 기본값 `mask` 와 같은 방향이지만 영향 범위가 크다. 기동 시 권한 적용 실패를 기동 중단으로 볼지는 아직 정하지 않았다.
- 기존 테스트 일부가 옛 동작(`[]` = 전원 허용)을 단언한다. 테스트가 현재 site-packages 의 구버전 vanna 를 검증하고 있어 드러나지 않으며, 경로를 바로잡을 때 함께 고쳐야 한다.

## 관련 페이지

- [[projects/dna-sql-agent/issues/tool-permission-revoke-all-becomes-allow-all]]
- [[projects/dna-sql-agent/decisions/014-always-enabled-tool]]
- [[projects/dna-sql-agent/decisions/025-default-group-access-initialization]]
- [[projects/dna-sql-agent/sessions/2026-08-14-tool-permission-fail-open-fix-and-pending-notice]]
