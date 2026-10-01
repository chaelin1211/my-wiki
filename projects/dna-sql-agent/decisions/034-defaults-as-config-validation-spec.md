---
type: decision-record
project: dna-sql-agent
date: 2026-08-13
status: accepted
superseded-by: ""
tags: [configuration, validation, startup]
---

# ADR-034: `defaults/*.json` 을 설정 검증 스펙으로 겸용한다

## 맥락

[[projects/dna-sql-agent/decisions/032-connection-info-env-single-source]] 로 접속정보는
`.env` 직독이 됐지만, 운영 설정 `config/*.json` 은 여전히 **최초 기동 시 만들어지고
그 뒤로는 파일이 진실**이다. 고객사에서 파일을 직접 고치는 일도 있다.

이 파일이 잘못돼도 기동은 된다. 문제는 한참 뒤에 엉뚱한 동작으로 드러난다.

- `sql_guard.max_query_length` 는 파일에 있는데 `SQLInspector` 에 전달되지 않아
  길이 제한이 걸리지 않았다
- 마스킹 그룹 액션이 설정 리로드 때 파일 사본 값으로 되돌아갔다
- 구버전에서 쓰던 키가 남아 있어도, 새 키가 빠져 있어도 아무 신호가 없다

Pydantic 스키마(`schemas.py`)가 있지만 **설정 API 로 들어오는 값**만 검증한다.
사람이 파일을 직접 고친 경로는 지나간다.

## 선택지

### 옵션 A: 현행 유지 — Pydantic 스키마만 신뢰
- **장점:** 변경 없음
- **단점:** 파일 직접 수정 경로가 무방비. 실제로 위 세 건이 그 경로에서 났다
- **비용/노력:** 없음

### 옵션 B: JSON Schema 파일을 섹션마다 따로 둔다
- **장점:** 표준 형식, 검증기 구현 불필요
- **단점:** 기본값 파일과 스키마 파일이 **두 벌**이 된다. 필드를 추가할 때 양쪽을
  고쳐야 하고, 한쪽만 고치면 갈라진다 — 이 프로젝트가 이미 여러 번 겪은 실패
  (`masking_rules.json` 사본, 문서 안의 스키마 사본)
- **비용/노력:** 중간

### 옵션 C: `defaults/*.json` 자체를 스펙으로 쓴다
- **장점:** 파일이 하나. 값이 곧 규칙이라 대부분 추가 표기가 필요 없다
  (`"temperature": 0.7` → "number 이고 필수")
- **단점:** 값만으로 표현 못 하는 것(널 허용, 선택 키, 배열 원소 타입)에 메타
  표기가 필요하고, 그 메타 자체가 잘못 쓰일 수 있다
- **비용/노력:** 중간 — 검증기 + 메타 규칙 + 스펙 린터

## 결정

**옵션 C.** `defaults/*.json` 이 초기값이면서 동시에 `config/*.json` 의 검증 스펙이다.

기동 시 `dna/settings/validation.py` 가 두 파일을 대조한다.

- 스펙에 있는 키가 config 에 없으면 **MISSING → 기동 중단**
- 타입이 다르면 **TYPE → 기동 중단**
- 스펙에 없는 키는 **경고만** 하고 무시 — 구버전 잔재로 기동을 막을 이유는 없다

값만으로 규칙을 못 정하는 경우에만 `_` 접두 메타 키를 붙인다.

| 키 | 뜻 |
|---|---|
| `_required` | 기본 `true`. `false` 면 config 에 없어도 통과 |
| `_type` | 값 대신 타입 지정 (기본값이 `null` 이라 추정 불가일 때) |
| `_item` | 배열 원소 템플릿 |

메타는 **형제 위치의 `_키` 사이드카**에 적는 것을 원칙으로 하고, 객체 값에 한해
인라인을 허용한다. 한 키에 둘 다 있으면 `ConfigError` 로 막는다.

```jsonc
{
  "max_tokens": null,
  "_max_tokens": { "_type": "number", "_required": false },
  "allow_origins": ["http://localhost:3000"],
  "_allow_origins": { "_item": "" }
}
```

`SettingsManager.get_default()` 가 `_` 키를 걷어내므로 설정 API 응답과 새로 만들어지는
`config/*.json` 에는 메타가 섞이지 않는다.

## 근거

- **두 벌을 만들지 않는다.** 이 프로젝트가 반복해서 데인 실패가 "같은 값이 두 곳에
  있고 한쪽만 바뀌는 것"이다. 스키마 파일을 따로 두면 같은 함정을 다시 판다
- **값이 이미 규칙의 90%다.** 기본값에서 타입을 읽으면 대부분의 키는 추가 표기가
  필요 없다. 예외만 적는 쪽이 유지 비용이 낮다
- **빠르게 실패한다.** 잘못된 설정으로 조용히 동작하는 것보다 기동을 멈추고 어느
  파일 어느 키가 문제인지 알리는 편이 낫다. 메시지에 파일 경로·키 경로·기대/실제를
  같이 낸다
- **모르는 키로는 죽지 않는다.** 업그레이드 때 남은 옛 키까지 기동을 막으면 운영이
  불편해진다. 단, CORS 만은 예외 — 값이 `CORSMiddleware` 인자로 그대로 넘어가
  모르는 키가 기동 중 `TypeError` 가 되므로 화이트리스트로 막는다

## 결과

- 배열은 `_item` 을 준 것만 원소를 검사한다. 원소 타입이 섞일 수 있어 첫 원소로
  추정하지 않는다. 현재 `masking.json` 의 `strategies.*.columns` 8곳이 `_item` 없이
  남아 있다(린터 WARN)
- `_required: false` 는 그 키 하나에만 적용된다. 배열에 주면 "배열이 없어도 된다"는
  뜻이고, 원소 필드는 여전히 필수다. 회귀 테스트로 고정했다
- **스펙 자체의 오류는 기동 검증이 못 본다** — 짝 없는 사이드카, 값과 어긋난
  `_type`, `_item` 빠진 배열은 검사를 조용히 헐겁게 만들 뿐이다. 그래서 개발용
  린터 `scripts/check_default_config.py` 를 별도로 둔다 (`.dockerignore` 로 배포 제외)
- 새 섹션을 추가하면 `manager.py` 의 `SECTIONS`(API 노출) 또는
  `DEFAULT_ONLY_SECTIONS`(파일로 만들지 않는 제품 값)에 등록해야 하고, 린터가 짝을 본다

향후 재검토: 설정 항목이 크게 늘어 메타 표기가 값보다 많아지면 그때는 JSON Schema
쪽이 나을 수 있다. 현재 12개 섹션에서는 메타가 붙은 키가 열 개 남짓이다.

## 참고 자료

- 세션: [[projects/dna-sql-agent/sessions/2026-08-13-config-spec-validation-and-docs-consolidation]]
- [[projects/dna-sql-agent/decisions/032-connection-info-env-single-source]]
- [[knowledge/patterns/defaults-file-as-validation-spec]]
- `docs/configuration-reference.md` §5, `src/dna/settings/validation.py`,
  `scripts/check_default_config.py`
