---
type: session-log
project: dna-sql-agent
date: 2026-06-11
duration: ~2h
focus: "tool_access JSON 권한 목록 제거, ValidatedRunSqlTool always_enabled, SQL 가드레일 메시지 정제"
tools-used: [claude-code]
outcome: in-progress
---

# 2026-06-11 — tool_access JSON 정리 + SQL Guard 정제

## 목표

- `config/tool_access.json`의 `access_groups` 제거 — DB 단일 진실 공급원 원칙 적용
- `ValidatedRunSqlTool`을 항상 활성화 고정 (`always_enabled`)
- SQL 가드레일 차단 메시지 정제 (과거 대화 히스토리에 남는 강한 조건화 완화)
- 시스템 프롬프트에 현재 차단 테이블 목록 실시간 주입

## 수행한 작업

### 1. tool_access JSON 정리 (`config/tool_access.json`, `agent_service.py`, `schemas.py`)

**배경:** `config/tool_access.json`에 `access_groups` 배열이 남아있었음. 하지만 실제 런타임에서는 `seed_and_apply_permissions()`가 시작 시 DB 값으로 덮어쓰므로 JSON의 `access_groups`는 dead code였음. `masking.json` groups 제거(ADR-012)와 같은 원칙을 일관 적용.

- `config/tool_access.json`: `access_groups` 제거, `ValidatedRunSqlTool`에 `always_enabled: true` 추가
- `agent_service.py`: `tool_def.get("access_groups", [])` → `access_groups=[]` (DB가 덮어쓰므로)
- `schemas.py` `ToolDefinition`: `access_groups` 제거, `always_enabled: bool = False`, `default_access: bool = True` 추가

→ ADR: [[decisions/013-tool-access-json-permission-cleanup]]

### 2. ValidatedRunSqlTool always_enabled

**배경:** SQL 실행 도구는 에이전트의 핵심 도구이므로 관리자가 실수로 비활성화하지 않도록 UI에서 읽기 전용으로 표시해야 함.

- `config/tool_access.json`: `"always_enabled": true` 추가
- `defaults/tool_access.json`: 이미 반영됨 (이전 세션)
- `schemas.py` `ToolDefinition`: `always_enabled` 필드 추가

→ ADR: [[decisions/014-always-enabled-tool]]
→ 프론트엔드 대응: [[projects/dna-sql-agent-web/sessions/2026-06-11-always-enabled-ui-and-save-button]]

### 3. SQL 가드레일 차단 메시지 정제 (`validated_run_sql.py`)

**배경:** 차단 메시지에 "절대로 재시도하지 마십시오"를 포함했더니 차단이 해제된 후에도 대화 히스토리에 남은 해당 tool result가 LLM을 강하게 조건화 — 새로운 조회 요청에도 계속 거부함. LLM은 시스템 프롬프트보다 대화 내 tool result를 "사실적 증거"로 더 강하게 받아들이는 경향.

**변경:**
- 제거: `"절대로 쿼리를 수정하거나 재시도하지 마십시오. 사용자에게 안내하고 대화를 종료하십시오."`
- 유지: `"차단된 테이블은 SQL 수정, 조인, 서브쿼리, 뷰 등 어떠한 방법으로도 우회하거나 접근을 시도하지 마십시오."`

→ ADR-011 수정 내역 (보완)

### 4. 시스템 프롬프트에 현재 차단 테이블 목록 주입 (`dna_system_prompt_builder.py`)

매 사용자 메시지마다 DB에서 실시간으로 차단 테이블 목록을 조회하여 시스템 프롬프트에 포함. 정보 제공 수준으로만 사용 (강제 지시 아닌 현황 안내).

```
## 현재 테이블 접근 정책
차단된 테이블: TABLE_A, TABLE_B   ← 있을 때
차단된 테이블: 없음. 모든 테이블에 접근 가능합니다.  ← 없을 때
```

**참고:** `DnaSystemPromptBuilder.build_system_prompt`는 이미 매 메시지마다 DB 조회(`get_system_by_connection_name_and_name`)를 수행하고 있었으므로 추가 조회 비용이 크지 않음.

### 5. masking.json access_groups 제거 (진행 중 — 중단)

`config/masking.json`의 각 전략에 남아있는 `groups` 필드 제거 작업을 시작했으나 세션 중단. 다음 세션에서 계속.

## 핵심 결정

- **JSON = 설정값(config), DB = 권한(permission):** 이 원칙을 tool_access에도 일관 적용. `defaults/tool_access.json`은 열거형(enum-like) 역할, `config/tool_access.json`은 활성화/비활성화 오버라이드 역할.
- **가드레일 차단 메시지 강도:** 우회 금지는 유지하되 "재시도 금지·대화 종료" 절대 명령은 제거. 이유: 대화 히스토리에 남는 강한 조건화 방지.
- **스태일 대화 히스토리 처리:** 권한 변경 시 이전 대화를 비활성화하는 방식은 보류 — 매끄러운 UX와 구현 복잡도 사이에서 추가 검토 필요.

## 문제 & 해결

| 문제 | 원인 | 해결 |
|------|------|------|
| always_enabled 적용 안 됨 | `config/tool_access.json` (런타임 실제 파일)이 수정되지 않고 `defaults/` 파일만 수정됨 | `config/tool_access.json` 직접 수정 |
| 제한 해제 후에도 LLM이 조회 거부 | 대화 히스토리의 차단 tool result가 시스템 프롬프트보다 강하게 LLM 조건화 | 차단 메시지 소프트닝 + 시스템 프롬프트 현황 주입 병행 |

## 다음 할 일

- [ ] `config/masking.json` groups 필드 제거 완료
- [ ] `schemas.py` `MaskingStrategyConfig.groups` 필드 제거
- [ ] 스태일 대화 처리 방식 추가 검토 (보류 중)
- [ ] tool_access / masking 변경 사항 커밋
