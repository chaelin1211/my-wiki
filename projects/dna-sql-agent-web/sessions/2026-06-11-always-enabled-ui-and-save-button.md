---
type: session-log
project: dna-sql-agent-web
date: 2026-06-11
duration: ~1h
focus: "always_enabled 도구 UI 읽기 전용 표시, 테이블 접근 제어 저장 버튼 활성화 버그 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-06-11 — always_enabled UI + 테이블 권한 저장 버튼 수정

## 수행한 작업

### 1. ValidatedRunSqlTool always_enabled UI 처리 (`infrastructure-tab.tsx`, `settings.ts`)

- `ToolDefinition`에 `always_enabled?: boolean` 추가
- always_enabled 도구는 활성화 Switch → disabled, 그룹 접근 버튼 → pointer-events-none
- 관리자가 실수로 핵심 도구를 비활성화하지 못하도록 보호

### 2. 테이블 접근 제어 저장 버튼 활성화 버그 수정 (`security-tab.tsx`, `page.tsx`)

**문제:** 그룹별 테이블 차단 설정 변경 시 dot 인디케이터는 표시되나 상단 우측 "변경사항 저장" 버튼이 활성화되지 않았음.

**원인:** `GroupTablePermissions` 컴포넌트의 dirty 상태가 상위 `page.tsx`의 `dirtyCount`에 포함되지 않았음.

**수정:**
- `SecurityTabProps`에 `onTablePermDirtyChange` 콜백 추가
- `GroupTablePermissions` → `SecurityTab` → `page.tsx` 순으로 dirty 상태 전파
- `page.tsx`: `tablePermDirty` state 추가, `dirtyCount`에 포함

## 다음 할 일

- [ ] 마스킹 JSON groups 제거 작업 완료 (백엔드 변경과 연동)
