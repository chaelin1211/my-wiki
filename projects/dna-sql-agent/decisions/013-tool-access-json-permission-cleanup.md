---
type: decision-record
project: dna-sql-agent
date: 2026-06-11
status: accepted
tags: [tool-access, permissions, db, json, config]
---

# ADR-013: tool_access.json에서 access_groups 제거 — JSON은 설정값, 권한은 DB

## 맥락

`config/tool_access.json`에 `access_groups` 배열이 남아있었다. 런타임에서는 `seed_and_apply_permissions()`가 시작 시 DB 값으로 덮어쓰므로 JSON의 `access_groups`는 사실상 dead code였다. 반면 ADR-012에서 masking.json의 groups를 DB로 이관한 것처럼, 권한 매핑은 DB에서 관리하고 JSON은 설정값(활성화 여부 등)만 담는다는 원칙이 있었다.

## 결정

**tool_access.json에서 `access_groups` 필드를 완전히 제거한다.**

- `config/tool_access.json`, `defaults/tool_access.json`: `access_groups` 제거
- `agent_service.py`: `tool_def.get("access_groups", [])` → `access_groups=[]` (DB가 startup 시 덮어씀)
- `schemas.py ToolDefinition`: `access_groups` 필드 제거

## JSON에 남는 필드

| 필드 | 역할 |
|------|------|
| `name` | 도구 식별자 |
| `enabled` | 활성화 여부 (설정값) |
| `always_enabled` | 항상 활성화 고정 여부 (설정값) |
| `default_access` | 신규 그룹 생성 시 자동 접근 부여 여부 |

## 근거

- DB가 source of truth이면 JSON에 중복 보관하는 것은 일관성 위반
- `seed_and_apply_permissions()`가 항상 startup 시 실행되어 DB 값으로 덮어쓰므로 JSON 값은 무의미
- masking.json(ADR-012), sql-guard(ADR-010)와 동일한 원칙 일관 적용

## 결과

- JSON과 DB 사이의 "어느 게 진짜?"라는 혼란 제거
- `defaults/tool_access.json`은 enum-like 역할(도구 목록 + 기본 설정), `config/tool_access.json`은 오버라이드 역할

## 참고 자료

- [[decisions/012-masking-group-actions-db-migration]]
- [[decisions/014-always-enabled-tool]]
