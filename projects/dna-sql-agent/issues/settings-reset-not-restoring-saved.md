---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-25
resolved: true
root-cause: "ctx.reset이 서버 공장 초기화였고, ref 기반 권한 카드(테이블접근제어/인프라)는 resetRef가 배선되지 않아 미저장 변경 폐기 경로가 없었음"
related: [settings, dirty-save, agent-config]
tags: [settings, reset, dirty-save, react]
---

# 에이전트 설정 "설정 리셋"이 저장값으로 안 돌아가고 버튼도 비활성 안 됨

## 증상

- 차트 엔진(ctx 섹션)을 바꿔 저장한 뒤 "설정 리셋"을 누르면 **저장값이 아니라 공장 기본값**으로 되돌아감.
- 테이블 접근 제어/도구·UI 권한을 수정 후 "설정 리셋"을 눌러도 **변경이 안 되돌아가고** 리셋 버튼(disabled=!hasChanges)도 계속 활성.

## 환경

- **런타임:** Next.js(React), 관리자 에이전트 설정 화면 (`app/admin/agent-config/page.tsx`)
- **관련:** `hooks/use-settings.ts`(ctx), `security-tab`(GroupTablePermissions), `infrastructure-tab`(useDbPermissions)
- **재현 조건:** 값 변경 → 저장 → 다시 리셋 / 또는 권한 토글 후 리셋

## 시도한 것들

1. ❌ 리셋 버튼만 확인 — dirtyCount엔 잡히는데 reset 핸들러에서 처리 안 됨
2. ✅ ctx.reset을 originals 복원으로 변경 + 권한 카드에 resetRef 배선

## 근본 원인

두 가지가 겹침:
1. `ctx.reset(id)`이 `resetSection(id)`(**서버 기본값 초기화**)를 호출하고 그 값을 baseline으로 다시 저장 → 저장값이 아니라 기본값으로 복원.
2. ref 기반 권한 카드(GroupTablePermissions, ToolAccessCard, UiFeatureCard)는 `saveRef`/`onDirtyChange`만 연결되고 **`resetRef`가 없어** `handleTabReset`이 호출할 폐기 경로가 없음. dirty는 집계되니 버튼은 활성인데 리셋이 무동작.

## 해결 방법

```ts
// hooks/use-settings.ts — 공장 초기화 → 마지막 저장값(originals) 복원
const reset = useCallback(async (id: SectionId) => {
  const orig = state.originals.get(id)
  if (orig === undefined || !state.dirty.has(id)) return false
  state.sections = { ...state.sections, [id]: JSON.parse(JSON.stringify(orig)) }
  state.dirty.delete(id); emit(); return true
}, [])
```

```ts
// 권한 카드: resetRef 배선 (저장값 복원)
useEffect(() => { if (resetRef) resetRef.current = reset }, [resetRef, reset])
// useDbPermissions.reset = () => setPendingPerms(savedPerms)
// GroupTablePermissions.reset = () => { setPendingChanges({}); setBlocked(perm?.blocked_tables ?? []) ... }
```

`page.tsx` `handleTabReset`에서 `tablePermResetRef`/`infraPermResetRef`/`maskingGroupsResetRef`를 모두 호출.

## 예방책

- dirty-save 카드를 만들 때 **save/dirty/reset 3종을 한 세트로 배선**. reset 없이 save만 연결하면 리셋이 조용히 죽음.
- "리셋"의 의미를 명확히: 미저장 변경 취소(저장값 복원) vs 공장 초기화. 버튼이 "변경 있을 때만 활성"이면 전자가 맞음.

## 관련 페이지

- 세션: [[projects/dna-sql-agent/sessions/2026-06-25-system-exclude-tables-table-access-control]]
