---
type: session-log
project: dna-sql-agent
date: 2026-08-14
duration: 
focus: "도구 권한 fail-open 정리 + 설정 미반영 표시 도입"
tools-used: [claude-code]
outcome: success
---

# 2026-08-14 — 도구 권한 fail-open 정리 + 설정 미반영 표시

## 목표

전날 파악해 둔 [[projects/dna-sql-agent/issues/tool-permission-revoke-all-becomes-allow-all|도구 권한 fail-open]] 을 실제로 고치고, 그 과정에서 드러난 "저장했는데 반영이 안 되는" 문제 전반을 정리한다.

## 수행한 작업

1. **빈 권한 목록을 거부로 뒤집었다.** 흩어져 있던 판정 3벌(실행·스키마 노출·결과 출력)을 `registry.has_tool_access()` 하나로 모았다.
2. **권한 해제가 반영되게 했다.** `_apply_tool_permissions()` 를 DB dict 순회에서 레지스트리 전체 순회로 바꿔, DB에 없는 도구를 빈 목록으로 되돌린다. 미등록 DB 키는 경고로 남긴다.
3. **도구 on/off 를 핫리로드 대상으로 올렸다.** `unregister_local_tool()` + `sync_registered_tools()` 를 만들어 `hot_reload()` 에 편입했다. `vector_search` 가 내려가면 `clarify_request` 도 함께 내린다.
4. **최초 설치 시딩 구멍을 메웠다.** 설정 파일을 만들기 전에 최초 설치를 판단해 전 도구에 `pending_permission_seed` 를 붙인다. 추측 기반이던 `seed_from_json_if_empty()` 는 삭제했다.
5. **estimator 설정이 무시되던 버그를 고쳤다.** `QueryEstimator.apply_config()` 를 추가하고 pool 생성 시점·호출 시점 양쪽에서 적용한다.
6. **미반영 설정 표시를 만들었다.** `ApplyMode` 선언 + `GET /api/v1/settings/pending` + 헤더 배너.
7. 설계 문서 §9 정본 표를 실제 동작에 맞춰 정정하고, 상단 다이어그램의 중복 목록을 참조로 대체했다.

## 핵심 결정

- **`[]` = 권한 없음.** "제한 없음"과 "전부 해제"가 같은 값으로 표현돼 구분이 불가능했다. 거부로 통일하고, 대신 시딩이 확실히 돌도록 보강했다.
  → ADR: [[projects/dna-sql-agent/decisions/035-empty-access-groups-means-deny]]

- **적용 시점을 코드에 선언한다.** 설정마다 효력 시점이 다른데 어디에도 적혀 있지 않아 관리자도 개발자도 알 수 없었다. `ApiSection.apply_mode` 로 선언하고 화면이 그걸 읽어 알린다. config 가 아니라 코드에 두는 이유는, 구현이 정하는 값이라 어긋나면 화면이 거짓말을 하기 때문이다.
  → ADR: [[projects/dna-sql-agent/decisions/036-apply-mode-declaration-and-pending-notice]]

- **적용 시점을 하나로 통일하지 않았다.** "전부 hot-reload 로" 안을 검토했으나, 즉시 반영되는 것들(sql_guard 등)을 일부러 느리게 만드는 셈이라 접었다. 섞여 있는 게 문제가 아니라 구분이 안 되는 게 문제였고, 그건 배너가 해결한다.

- **DB 변경은 타임스탬프가 아니라 표식으로 추적한다.** 권한을 전부 지우면 행이 사라져 `max(created_at)` 으로는 변경을 알 수 없다. 저장 API 가 표식을 세우고 `hot_reload()` 가 지운다.

## 배운 것

- **"비어 있음"을 신호로 쓰면 반드시 두 상태가 겹친다.** 도구 권한(`[]`), 시딩 여부(테이블 빈 상태), DB 변경 감지(`max(created_at)`) 세 곳에서 같은 함정이 반복됐다. 답은 매번 같았다 — 추론하지 말고 사실을 기록한다(`pending_permission_seed`, `mark_db_changed`).
- **문서 표가 코드와 갈라지면 조용히 틀린 채로 남는다.** `tool_access`·`chart`·`estimator` 세 항목이 §9 표와 실제가 달랐다. 값 목록을 여러 곳에 적어두지 않고 정본 하나만 두는 게 유일한 방어였다.
- **캐시는 "언제 다시 읽는가"를 함께 설계해야 한다.** estimator 는 pool 이 config 를 아예 안 읽어 설정이 통째로 죽어 있었고, 아무도 몰랐다.

## 문제 & 해결

- **문제:** 도구 권한을 전부 해제하면 오히려 전원 허용이 된다.
- **원인:** 판정이 빈 목록을 "제한 없음"으로 읽는데, 해제는 DB 행 삭제로 구현돼 두 상태가 구분되지 않는다.
- **해결:** 판정을 거부로 뒤집고, 레지스트리 전체 순회로 해제를 반영하고, 최초 설치 시딩을 보강했다.
  → 이슈: [[projects/dna-sql-agent/issues/tool-permission-revoke-all-becomes-allow-all]]

- **문제:** `enabled: false` 로 껐는데 도구가 계속 동작한다.
- **원인:** 도구 등록이 기동 시 1회뿐이고 핫리로드가 재등록하지 않는다. 끄기 전에 이미 등록된 객체가 메모리에 살아 있었다.
- **해결:** `sync_registered_tools()` 를 핫리로드에 편입.

- **문제:** 관리자 화면에서 예측기 임계값을 바꿔도 아무 효과가 없다.
- **원인:** `database_pool` 경로가 `QueryEstimator` 를 자격증명만으로 만들고 `estimator.json` 을 읽지 않았다. `from_config()` 는 쓰이지 않는 legacy 경로에만 있었다.
- **해결:** `apply_config()` 추가 후 생성·호출 양쪽에서 적용.

- **문제:** 신규 도구 추가 후 기동하면 아무것도 안 했는데 미반영 배너가 뜬다.
- **원인:** 기동 중 `tool_access.json` 이 두 번 저장되는데(표식 부착·소비), 판정 기준 시각이 모듈 import 시점이라 그 쓰기가 미반영으로 잡혔다.
- **해결:** `mark_started()` 로 기준 시각을 기동 완료 시점으로 옮김.

- **문제:** 금액 표기가 이탤릭 수식으로 깨져 보이고 KaTeX 경고가 뜬다.
- **원인:** `remark-math` 가 `$` 를 수식 구분자로 보아 `-$0.03 ~ -$10에서` 를 수식으로 묶었다.
- **해결:** `singleDollarTextMath: false` — `$$` 블록만 수식으로 취급.
  → 로그: [[projects/dna-sql-agent/issues/log]]

## 다음 할 일

- [ ] 테스트가 `src/vanna` 를 보도록 경로 정리 — 지금은 site-packages 구버전을 검증한다. 정리하면 `test_tool_permissions.py` 11건이 실패한다(옛 동작 단언 2, 메시지 문구 3, `access_groups=[]` 를 편의로 쓴 transform_args 6)
- [ ] `origin/main` 최신화 후 PR — `registry.py`·`agent.py` 충돌 가능
- [ ] DB에 남은 미등록 도구 권한 6건 처리 방침 (일부러 남긴 것이라 삭제 보류)
- [ ] `always_enabled` 이 코드에서 강제되지 않음 (의도된 것으로 확인, 기록만)

## 효과적이었던 프롬프트

```
그럼 _apply_tool_permissions 이거 보자
있는 키만 덮어쓰는건 확실히 말이 안 되네
```

```
아니 근데 max_rows에 맞춰서 6개 로우만 나오던데
```

→ 코드를 부분만 읽고 단정한 설명을 실제 관찰로 반박받아 두 번 정정했다.
`max_rows` 는 비용 점수용이라고 했으나 LIMIT 상한으로도 쓰였고,
`enabled=false` 도구가 실행되던 것도 DB 권한이 아니라 등록 시점 문제였다.
로그·DB·실제 실행으로 확인하기 전에는 단정하지 않는 편이 낫다.
