---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-13
resolved: true
root-cause: "도구 권한 판정이 빈 목록을 '허용'으로 읽는데, 권한 회수는 DB 행 삭제로 구현되어 있어 '전부 해제'가 '전원 허용'이 된다"
related: [tool-access, group-permissions, fail-open]
tags: [permissions, fail-open, security]
---

# 도구 권한을 전부 해제하면 오히려 전원이 쓸 수 있게 된다

## 증상

관리자 화면에서 어떤 도구의 그룹 접근 권한을 **모두 해제**하면, 의도는 "아무도 못 쓴다"인데 실제로는 **모든 사용자가 그 도구를 쓸 수 있다.** 에러도 경고도 없다. 다음 기동 이후에도 그대로다.

같은 이유로, DB에 권한 행이 한 번도 만들어진 적 없는 도구도 전원에게 열려 있다.

## 환경

- 관련 파일: `src/vanna/core/registry.py`, `src/dna/agent_service.py`, `src/dna/settings/group_permissions_service.py`, `src/dna/group_permissions/crud.py`
- 확인 시점: 2026-08-13, `feat/config-validator` 브랜치에서 `origin/main` 병합 중 발견
- 재현: 관리자 화면에서 도구 하나의 그룹을 모두 해제한 뒤, 그 그룹에 속하지 않은 계정으로 해당 도구 호출

## 근본 원인

권한 판정이 빈 목록을 "제한 없음"으로 읽는다.

```python
# src/vanna/core/registry.py:96-98
tool_access_groups = tool.access_groups
if not tool_access_groups:
    return True          # 빈 목록이면 통과
```

여기에 세 가지가 겹친다.

1. `agent_service.py` 는 모든 도구를 `access_groups=[]` 로 등록한다. 권한 정본이 DB이기 때문이다.
2. 기동 시 `_apply_tool_permissions()` 는 **DB에 행이 있는 도구만** 목록을 채운다. 행이 없는 도구는 빈 목록으로 남는다.
3. 권한 회수(`set_item_permissions`)는 해당 도구의 행을 **모두 삭제**한다. 그래서 "관리자가 전부 해제한 상태"와 "한 번도 설정한 적 없는 상태"가 DB에서 구분되지 않는다.

결과적으로 "미설정 = 전원 허용" 이라는 기준이 회수에도 그대로 적용되어 의미가 뒤집힌다.

덧붙여 `crud.seed_from_json_if_empty()` 는 정의만 있고 호출하는 곳이 없다. `main`, `feat/config-validator` 양쪽 모두 그렇다. 그래서 신규 설치에서도 도구 권한 행은 0개로 시작하며, 제품이 그 상태로 동작한다는 것 자체가 현재 기준이 "미설정 = 허용" 임을 보여준다.

## 함께 확인한 것 — `pending_permission_seed`

`main` 이 명확화 도구(`ClarifyRequestTool`)를 추가하면서 넣은 일회용 표식이다. 기동 시 새 도구를 설정 파일에 덧붙이고 표식을 남긴 뒤, DB 준비 후 기본 권한을 한 번 넣고 표식을 지운다.

`main` 에서 이게 필요했던 이유는 "행이 없으면 권한이 없어서"가 아니라, `main` 의 `tool_access.json` 이 항목마다 `access_groups` 를 갖고 있어 **그 목록 밖 그룹이 막히기 때문**이다. 우리 브랜치는 그 필드를 걷어냈고 모든 도구를 빈 목록으로 등록하므로, 이 도구는 이미 전원 허용이고 시딩은 오히려 "그 시점에 있던 그룹만"으로 좁히는 동작이 된다.

즉 지금 우리 코드에서 이 표식은 도구 하나에만 붙어 있어 나머지와 기준이 다르다.

## 해결 (2026-08-14 적용)

"행 없음 = 거부"로 기준을 통일했다. 판정만 뒤집으면 기존 설치가 통째로 막히므로 시딩을 먼저 보강했다.

1. **판정 통일.** `registry.has_tool_access()` 하나로 모으고 빈 목록을 거부로 바꿨다. 실행·스키마 노출·결과 출력 세 벌이 각자 복제하고 있어 함께 처리했다.
2. **해제 반영.** `_apply_tool_permissions()` 를 DB dict 순회에서 레지스트리 전체 순회로 바꿨다. DB dict 만 돌면 행이 사라진 도구는 순회 대상이 아니라 옛 권한이 남는다. 이게 "설정 적용을 눌러도 해제가 반영되지 않던" 원인이었다.
3. **전환 시딩.** 최초 설치일 때 전 도구에 `pending_permission_seed` 를 붙인다. 이전에는 설정 파일을 만든 뒤 defaults 와 비교해서 차이가 없어 시딩이 아예 돌지 않았다.
4. **추측 제거.** `seed_from_json_if_empty()`(테이블이 비면 신규 설치로 간주)를 삭제했다. 권한을 전부 지운 상태와 구분되지 않아, 남겨두면 관리자가 뺀 권한이 재기동 때 되살아난다.

관련 커밋: `a0d3847`, `d728836`, `cabfe86` (`fix/tool-access-apply`)
→ ADR: [[projects/dna-sql-agent/decisions/035-empty-access-groups-means-deny]]

## 미해결로 남긴 것

- **DB 장애 시 동작.** 거부 기준이라 DB를 못 읽으면 도구가 전부 막힌다. `sql_guard` 의 `fail_closed`, 마스킹 기본값 `mask` 와 같은 방향이지만 영향 범위가 크다. 기동 시 권한 적용 실패를 기동 중단으로 볼지 정하지 않았다.
- **`always_enabled` 도구.** `ValidatedRunSqlTool` 에 붙어 있으나 코드에서 강제되지 않는다. 화면은 "항상 허용(변경 불가)"으로 막지만 설정 API 로는 끌 수 있고, 도구 on/off 가 핫리로드 대상이 되면서 설정 적용 한 번으로 내려간다. 의도된 상태로 확인했다.
- **테스트.** `test_tool_permissions.py` 가 옛 동작(`[]` = 전원 허용)을 단언한다. 테스트가 site-packages 의 구버전 vanna 를 검증하고 있어 드러나지 않는다.

## 추가로 확인한 남은 구멍 (2026-09-03)

"처음 배포했을 때 `ValidatedRunSqlTool` 권한이 아무에게도 없었다"는 보고를 계기로 시딩 경로를 다시 훑었다. 위 3번(전환 시딩)으로 최초 설치는 해결됐지만 두 경로가 남아 있다.

- **업그레이드 배포에는 시딩이 걸리지 않는다.** 최초 설치 판정 기준이 `config/tool_access.json` 파일의 존재 여부다(`migrations.py:19`). `config/` 를 영속 볼륨으로 쓰는 환경에서 구버전으로 한 번이라도 뜬 적이 있으면 파일이 이미 있어 `first_install=False` 가 되고, `ValidatedRunSqlTool` 은 defaults 에 원래 있던 도구라 "새로 추가된 도구"에도 안 잡힌다. 결과적으로 표식이 영영 붙지 않는다. 판정 기준을 파일 존재가 아니라 **DB 권한 행의 유무**로 바꾸는 쪽이 맞다.
- **그룹이 없는 순간에 시딩이 돌면 표식만 소진된다.** `seed_pending_tool_permissions()` 는 `group_names` 가 비면 `add_missing_item_permissions()` 가 조용히 반환하는데도 `consumed` 에 넣고 표식을 지운 뒤 저장한다(`group_permissions_service.py:97-110`). 한 번 이러면 재기동해도 복구되지 않는다. 부여에 실제로 성공한 경우에만 소진해야 한다.

현재 배포본 확인용 질의:

```sql
SELECT g.name FROM group_permissions gp
JOIN groups g ON gp.group_id = g.id
WHERE gp.category = 'tool' AND gp.item_key = 'ValidatedRunSqlTool';
```

비어 있으면 관리자 화면에서 부여하거나 직접 INSERT 하면 되고, 이후 hot reload 로 반영된다.

부트스트랩 그룹이 이 구멍에 걸리는 구조적 이유도 함께 확인했다 — `admin`·`user` 는 `schema.py:254` 에서 SQL 로 직접 INSERT 되므로, 신규 그룹이 타는 `apply_default_permissions_for_new_group()` 경로를 지나지 않는다. "새 그룹은 권한을 받는데 처음부터 있던 그룹은 못 받는" 비대칭이 여기서 나온다.

→ 일반화: [[knowledge/troubleshooting/first-install-detection-by-file-presence]]

## 곁가지 — 같은 함정이 세 번 반복됐다

"비어 있음"을 신호로 쓰면 두 상태가 겹친다는 점이 이 문제의 본질이다. 같은 구조가 세 곳에 있었다.

| 위치 | 겹친 두 상태 | 해법 |
|---|---|---|
| 도구 권한 `[]` | 제한 없음 / 전부 해제 | 거부로 통일 |
| `group_permissions` 빈 테이블 | 신규 설치 / 전부 해제 | 표식(`pending_permission_seed`)으로 기록 |
| `max(created_at)` | 변경 없음 / 행이 전부 삭제됨 | 표식(`mark_db_changed`)으로 기록 |

답은 매번 같았다 — **추론하지 말고 사실을 기록한다.**

## 관련 페이지

- [[projects/dna-sql-agent/decisions/035-empty-access-groups-means-deny]]
- [[projects/dna-sql-agent/sessions/2026-08-14-tool-permission-fail-open-fix-and-pending-notice]]
- [[projects/dna-sql-agent/decisions/013-tool-access-json-permission-cleanup]]
- [[projects/dna-sql-agent/decisions/014-always-enabled-tool]]
- [[projects/dna-sql-agent/decisions/025-default-group-access-initialization]]
- [[projects/dna-sql-agent/sessions/2026-08-13-config-spec-validation-and-docs-consolidation]]
