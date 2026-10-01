---
type: session-log
project: dna-sql-agent
date: 2026-08-13
duration: 
focus: "설정 검증 도입, 설정 API 관리자 전용화, 설정 정의 통합, main 병합과 PR"
tools-used: [claude-code]
outcome: success
---

# 2026-08-13 — 설정 스펙 검증과 문서 정본화 (`feat/config`)

## 목표

`config/*.json` 이 잘못돼도 기동은 되고 한참 뒤에 엉뚱한 동작으로 드러나는 상태를
없앤다. 그리고 설정 관련 문서가 네 곳으로 흩어져 사본끼리 갈라진 것을 정리한다.

## 수행한 작업

`feat/config` 브랜치 (2026-08-10 ~ 08-13, 15 커밋).

1. **설정 기본값 정형화** (`07d0578`, `317c194`, `0b97d77`)
   - `tool_access`·`ui_features` 를 배열에서 키 기반 객체 구조로 전환, `ui_features` 를
     별도 defaults 파일로 분리
   - `rag`·`agent`·`license`·`collection_runner` defaults 를 실사용 키 기준으로 정리
2. **기동 시 설정 검증 추가** (`cacaf29`, `23ef18a`, `cb8f352`, `43f0031`, `81916ab`)
   - `dna/settings/validation.py` — `defaults/*.json` 을 스펙으로 삼아 `config/*.json`
     을 대조. 없는 키(MISSING)·타입 불일치(TYPE)는 기동 중단, 모르는 키는 경고만
   - 메타 키를 `_` 접두 사이드카로 통일 (`_required`/`_type`/`_item`)
     → ADR: [[projects/dna-sql-agent/decisions/034-defaults-as-config-validation-spec]]
   - CORS 는 `CORSMiddleware` 인자로 그대로 넘어가 모르는 키가 기동 중 `TypeError`
     가 되므로 별도 화이트리스트 검사
   - `collection_runner` 를 설정 API 노출 대상에서 제외 (파일로 만들지 않는 기본값 전용)
   - 회귀 테스트 61건 (`tests/test_settings_validation.py`)
3. **defaults 스펙 린터** (`c6a6572`) — `scripts/check_default_config.py`
   - 기동 검증이 못 보는 "스펙 자체가 틀린" 경우를 잡는다: 짝 없는 사이드카,
     사이드카 안의 오타 키, 값과 어긋난 `_type`, null 기본값에 `_type` 없음,
     배열 아닌 키의 `_item`, 인라인+사이드카 동시 사용, `SECTIONS`↔defaults 짝
   - ERROR 는 exit 1, `_item` 없는 배열처럼 검사가 헐거워지는 지점은 WARN (`--strict`)
   - `.dockerignore` 의 `scripts` 로 배포 이미지에서 제외
4. **버그 수정** (`204d395`, `a796882`, `4925767`, `0a95018`, `6c7f4ff`)
   - `sql_guard.max_query_length` 가 `SQLInspector` 에 전달되지 않던 문제
     → [[projects/dna-sql-agent/issues/sql-guard-max-query-length-not-passed-to-inspector]]
   - 마스킹 그룹 액션이 설정 리로드 때 되돌아가던 문제
     → [[projects/dna-sql-agent/issues/masking-group-action-lost-on-settings-reload]]
   - 마스킹 기본 그룹 액션 폴백을 `none` → `mask` (fail-closed)
5. **문서 재편** (`948e465`)
   - `configuration-reference.md`: 상단 문서 지도 + §5 `defaults` 작성 규칙 신설
   - `server-settings-design.md` 1251 → 464줄: §15 RAG 파이프라인 이관,
     §6 스키마 JSON 사본 제거(특기사항 표만 유지), hot-reload 표 2개 → 1개
   - `settings-ui-design.md` 867 → 726줄: API 엔드포인트·요청/응답 예시·hot-reload
     표·소스 위치 표를 서버 문서 링크로 대체
   - `rag-architecture.md` 612 → 1011줄: 분리했던 파이프라인 문서를 흡수

## 핵심 결정

- **`defaults/*.json` 을 초기값이자 검증 스펙으로 겸용한다.** 스키마 파일을 따로
  두지 않고, 값에서 타입을 추정하고 예외만 `_` 접두 메타로 적는다.
  → ADR: [[projects/dna-sql-agent/decisions/034-defaults-as-config-validation-spec]]
- **문서 사본을 두지 않는다.** 값 목록·엔드포인트 표처럼 갈라지기 쉬운 것은 정본
  하나만 두고 나머지는 링크한다. 사본을 걷어내는 과정에서 실제로 갈라진 것들이
  드러났다 — `chart.engine` 에 `echarts` 누락, `rag.default_systems` 가 `["IFIS"]`
  (실제 `[]`), UI 문서의 `sql-guard` 응답 예시에 이미 DB로 옮겨진 `groups` 잔존.

## 배운 것

- 검증기를 만들면 **검증기 자신의 입력(스펙)** 이 새로운 사각지대가 된다. 스펙이
  헐겁게 쓰이면 검사는 조용히 통과하고 아무도 모른다. 스펙용 린터를 따로 둔 이유다.
- 배열 원소 타입은 추정하지 않는 편이 낫다. 첫 원소로 추정하면 혼합 배열에서
  거짓 실패가 난다. `_item` 을 명시한 배열만 검사하고, 없으면 WARN 으로 남긴다.
- `_required: false` 를 배열 키에 주면 "배열이 없어도 된다"는 뜻이지 "원소 필드가
  선택"이라는 뜻이 아니다. 이 구분이 회귀 테스트로 고정돼 있다.

## 문제 & 해결

- **문제:** 설정 파일에 값이 있는데 코드에 닿지 않거나(`max_query_length`),
  리로드 때 옛 사본으로 되돌아간다(마스킹 그룹 액션).
- **원인:** 같은 값이 두 곳(설정 파일 사본 / DB·런타임 캐시)에 있었고, 소비처에
  전달하는 경로가 빠져 있었다.
- **해결:** 사본 제거(런타임 캐시 단일화) + 누락 인자 전달. 그리고 이런 부류가
  조용히 지나가지 않도록 기동 시 검증을 추가.
  → [[projects/dna-sql-agent/issues/masking-group-action-lost-on-settings-reload]]


## 이어진 작업 — 권한, 구조 통합, 병합

6. **설정 API 를 관리자 전용으로 제한** (`2bc2c03`)
   - `settings/routes.py` 의 8개 엔드포인트가 `get_current_user` 만 검사하고 있었다. 로그인한
     일반 사용자가 `masking` 을 꺼서 개인정보 마스킹을 해제하거나, `sql_guard` 를 꺼서 SQL
     가드레일을 무력화하거나, 서버를 재시작할 수 있었다. 두 설정 모두 매 호출 시 파일을
     읽으므로 재기동 없이 즉시 반영된다
   - `require_admin` 으로 통일. 프론트 사용처는 `/admin/agent-config` 한 곳이고 그 메뉴는
     관리자에게만 노출되므로 화면 영향 없음. 권한 회귀 테스트 4건 추가
7. **설정 정의를 `API_SECTIONS` 하나로 통합** (`2bc2c03`)
   - `SECTIONS`(파일명 snake) / `DEFAULT_ONLY_SECTIONS` / `SECTION_SCHEMAS`(URL kebab) 세
     목록이 같은 것을 두 철자로 나눠 갖고 있었다. 파일 이름·검증 모델·화면 주소를 한 항목이
     함께 갖는 구조로 합침
   - 검증 대상을 목록 순회에서 `config/` 폴더 스캔으로 변경. 등록을 빠뜨려도 파일이 있으면
     검증된다
   - config 파일 생성 여부는 기본값 파일의 `"_section": {"_seed": false}` 로 표시.
     `migrations.py` 의 동일한 함수 13개를 루프 하나로 (175줄 → 30줄)
8. **`origin/main` 병합** (`ac6d29b`, 26커밋 — 질의 명확화 기능)
   - `tool_access` 구조 충돌. main 은 배열 + `access_groups` 를 유지한 채 `ClarifyRequestTool`
     을 추가했고, 이 브랜치는 같은 파일을 키 기반으로 바꾼 상태였다
   - 우리 구조를 유지하면서 main 의 "기존 설치에 새 도구 덧붙이기" 동작을 이식
     (`_mark_new_tools`, 도구 항목의 `pending_permission_seed` 표식). main 이 가져온 테스트
     2개 파일도 키 기반으로 옮김
9. **PR 생성**
   - 서버: [#140](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/140)
   - 웹: [#82](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/82) —
     설정 화면을 서버 구조에 맞춤 (8/10 커밋이 푸시 안 된 채 남아 있었다)
   - 기존 PR(#131·#136·#138) 양식을 뽑아 `CLAUDE.md` 에 "PR 양식" 절로 기록

## 발견 — 도구 권한이 fail-open 이다

병합 중 `pending_permission_seed` 의 목적을 따라가다 확인했다. 권한 판정이 빈 목록을 "제한
없음"으로 읽는데(`vanna/core/registry.py:96-98`), 권한 회수는 DB 행 삭제로 구현되어 있다.
그래서 **관리자가 어떤 도구의 그룹을 전부 해제하면 전원 허용이 된다.**

`crud.seed_from_json_if_empty()` 는 양쪽 브랜치 모두 정의만 있고 호출되지 않는다. 즉 현재
기준은 "설정하지 않은 도구 = 전원 허용" 이고, 회수에도 그 기준이 적용되어 의미가 뒤집힌다.

main 이 `pending_permission_seed` 를 넣은 이유는 "행이 없으면 권한이 없어서"가 아니라, main
의 설정 파일이 항목마다 `access_groups` 를 갖고 있어 그 목록 밖 그룹이 막히기 때문이었다.
우리 구조에는 그 필드가 없어 이 장치는 목적을 잃었다. 다만 빼는 대신 전체 도구로 넓히는
편이 맞다 — 나중에 "행 없음 = 거부"로 뒤집으려면 전환 시딩이 먼저 필요하기 때문이다.
→ [[projects/dna-sql-agent/issues/tool-permission-revoke-all-becomes-allow-all]]

## 배운 것 (추가)

- **목록이 겸직하면 등록을 빠뜨린다.** `SECTIONS` 하나가 "파일로 저장할 것"과 "API 로 내보낼
  것" 두 가지를 겸하고 있어서, 새 설정을 추가할 때 어디까지 등록해야 하는지가 흐릿했다.
  둘을 분리하니 "파일을 놓으면 설정이 생기고, 화면에서 고치려면 한 줄 더" 로 정리됐다.
- **기준을 뒤집을 때는 전환 경로가 먼저다.** fail-open 을 fail-closed 로 바꾸는 것은 한 줄
  변경처럼 보이지만, 기존 설치에 권한 행이 없는 상태라 그대로 뒤집으면 제품이 멈춘다.

## 다음 할 일

- [x] PR 생성 — 서버 #140, 웹 #82
- [ ] PR #140 리뷰·머지 (웹 #82 는 서버 머지 후)
- [ ] 도구 권한 fail-open 정리 — 전환 시딩 → 판정 뒤집기 → 적용 실패 시 기동 중단 여부 결정
- [ ] `docs/clarification-design.md` 의 "tool_access 에서 접근 그룹 관리" 서술이 우리 구조와 어긋남 (병합 후속)
- [ ] `masking.json` 의 컬럼 목록 8곳에 내용물 표기 추가 — 현재 린터 WARN 8건
- [ ] `check_default_config.py` 를 CI 에 연결할지 결정
- [ ] `settings-ui-design.md` 의 Tab 6(Foundation/llm) 이 폐기된 기준으로 남아 있음 — 화면 실제 구성과 대조 필요
- [ ] `docs/config-validation.md` 재작성 — 로컬에서 사라져 커밋 이력에 없음(휴지통에 원본)

## 효과적이었던 프롬프트

```
config 검증 기능 - defaults config 작성 규칙을 doc에 넣고 싶어.
그리고 검증 py 파일도 별도 경로에 추가할까봐 scripts 여기. 배포 시에는 제외되니까

다른 케이스 검사 fail 날만한 샘플 Json
```

두 번째 프롬프트가 특히 유효했다. 검사기를 만든 직후 "실패하는 입력을 직접 보여달라"
고 요구하면 각 규칙이 실제로 걸리는지 한 번에 확인된다 (11개 FAIL + WARN 재현).
