---
type: issue
project: dna-sql-agent-web
date: 2026-05-27
resolved: true
title: "사용자 클릭 시 권한 매트릭스 전체 깜빡임"
---

# 권한 매트릭스 깜빡임 on 사용자 선택

## 증상

시스템 권한 탭에서 사용자 행을 클릭하여 상세 다이얼로그를 열면 매트릭스 전체가 잠깐 사라졌다 다시 나타남.

## 원인

`page.tsx`에서 `useUserPermissions(selectedUserId)`의 `loading` state(`permsLoading`)를 `PermissionMatrixPanel`의 `loading` prop으로 전달하고 있었음. 컴포넌트 최상단에:

```tsx
if (loading) {
  return <div>Loading...</div>  // 매트릭스 전체 교체
}
```

사용자를 선택하면 `selectedUserId`가 변경 → 훅의 `load()` 실행 → `setLoading(true)` → `loading=true` → 매트릭스 전체가 로딩 스피너로 교체됨.

## 해결

최상단 `if (loading) return ...` guard 제거. `loading`은 다이얼로그 내부에서만 사용:

```tsx
{loading ? (
  <div>Loading...</div>
) : (
  <Table>...</Table>
)}
```

매트릭스는 자체 `matrixLoading` state로 관리하며 `loading` prop에 의존하지 않음.
