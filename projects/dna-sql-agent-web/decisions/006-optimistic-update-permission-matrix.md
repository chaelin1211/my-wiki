---
type: adr
project: dna-sql-agent-web
number: "006"
title: "권한 매트릭스 셀 토글에 옵티미스틱 업데이트 적용"
status: accepted
date: 2026-05-27
---

# ADR-006 — 권한 매트릭스 셀 토글 옵티미스틱 업데이트

## 배경

시스템 권한 매트릭스는 사용자 × 시스템 전체를 한 화면에 표시한다. 셀 하나를 클릭할 때마다 API를 호출하고 응답 후 전체 매트릭스를 리로드(`loadAllPermissions`)하면 비동기 API 호출 동안 UI가 멈춰 보인다. 매트릭스가 클수록 리로드 지연이 커진다.

## 결정

셀 클릭 즉시 `allUserPerms` state를 업데이트(옵티미스틱)하고, API 호출은 백그라운드에서 진행한다. 실패 시 state를 원래대로 롤백한다. 전체 매트릭스 리로드(`loadAllPermissions`)는 더 이상 셀 토글 후 호출하지 않는다.

```ts
// 옵티미스틱 업데이트
setAllUserPerms(prev => {
  const next = { ...prev }
  const userSet = new Set(prev[userId] ?? [])
  hasPerm ? userSet.delete(systemId) : userSet.add(systemId)
  next[userId] = userSet
  return next
})

try {
  await revokePermission(userId, systemId) // or grantPermission
} catch {
  // 롤백
  setAllUserPerms(prev => { ... 반대 연산 ... })
}
```

## 대안

- **API 후 전체 리로드**: 구현 단순, 사용자 N명 × 시스템 M개 API 호출 후 UI 반응 → 지연 체감 심함
- **단일 셀만 리로드**: 해당 userId 권한만 재조회 → 리로드보다 빠르지만 여전히 API 왕복 후 반영

## 결과

- 클릭 즉시 UI 반영으로 반응성 향상
- 실패(네트워크 오류 등) 시 state 롤백으로 데이터 정합성 유지
- `allUserPerms`가 `Set` 기반이라 롤백 로직이 단순 (`add/delete` 반전)
