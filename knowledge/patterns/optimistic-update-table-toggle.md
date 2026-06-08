---
type: pattern
title: "테이블 토글 셀 옵티미스틱 업데이트"
tags: [react, ux, optimistic-update]
date: 2026-05-27
---

# 테이블 토글 셀 옵티미스틱 업데이트

## 언제 쓰나

- 테이블 셀 클릭으로 권한, 상태, 플래그 등을 토글하는 경우
- API 응답 대기 없이 즉시 반응해야 할 때
- 실패 가능성이 낮지만 실패 시 정합성 복원이 필요한 경우

## 핵심 구조

```ts
const handleToggle = async (id: string, flag: boolean) => {
  // 1. 즉시 UI 반영
  setState(prev => {
    const next = { ...prev }
    const set = new Set(prev[id] ?? [])
    flag ? set.delete(targetId) : set.add(targetId)
    next[id] = set
    return next
  })

  try {
    // 2. API 호출 (백그라운드)
    await flag ? deleteApi(id, targetId) : createApi(id, targetId)
  } catch {
    // 3. 실패 시 롤백 (반대 연산)
    setState(prev => {
      const next = { ...prev }
      const set = new Set(prev[id] ?? [])
      flag ? set.add(targetId) : set.delete(targetId)  // 반전
      next[id] = set
      return next
    })
  }
}
```

## 주의사항

- state가 `Set` 기반이면 롤백이 `add/delete` 반전으로 단순해짐
- 여러 셀을 빠르게 클릭하면 race condition 가능 → 필요 시 per-cell loading state 추가
- API 실패 시 toast로 사용자에게 알림 추가 권장
- 이 패턴은 리로드(`loadAll`)를 대체하므로, 다른 탭/사용자의 변경사항은 반영 안 됨 → 주기적 새로고침 또는 별도 새로고침 버튼 제공

## 실제 적용 예

- `dna-sql-agent-web` permission-list.tsx `handleCellToggle`