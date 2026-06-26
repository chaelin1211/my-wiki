---
type: decision-record
project: dna-sql-agent
date: 2026-06-11
status: accepted
tags: [tool-access, config, ui, security]
---

# ADR-014: always_enabled 도구 개념 도입

## 맥락

`ValidatedRunSqlTool`은 에이전트가 SQL을 실행하기 위한 핵심 도구다. 관리자가 실수로 이 도구를 비활성화하면 에이전트 전체가 동작하지 않는다. 도구 접근 제어 UI에서 이 도구는 활성화 상태를 바꿀 수 없어야 하고, 그룹 접근 버튼도 읽기 전용이어야 한다.

## 결정

**`always_enabled: true` 플래그를 도입한다.**

- `tool_access.json`에 `"always_enabled": true` 필드 추가
- 프론트엔드: `always_enabled` 도구는 Switch disabled, 그룹 접근 버튼 pointer-events-none
- `schemas.py ToolDefinition`: `always_enabled: bool = False` 필드 추가

## 적용 대상

| 도구 | always_enabled |
|------|----------------|
| ValidatedRunSqlTool | true |
| 기타 도구 | false (기본) |

## 근거

- 핵심 인프라 도구는 관리자 실수로 비활성화되면 서비스 전체가 멈춤
- UI에서 시각적으로 "이건 건드릴 수 없음"을 명확히 표시하는 것이 UX에 유리
- 비활성화 여부보다 그룹 접근 권한이 실제 보안 제어이므로, 도구 자체를 끄는 기능은 불필요

## 참고 자료

- [[decisions/013-tool-access-json-permission-cleanup]]
