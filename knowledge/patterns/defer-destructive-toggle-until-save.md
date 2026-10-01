---
type: knowledge
category: pattern
date: 2026-09-22
tags: [ux, react, undo, navigation-guard, cascade-delete]
---

# 파괴적 토글은 저장 전까지 보류한다 — 대기 상태 + 일괄 저장 + 이동 가드

## 문제

"해제했다가 다시 누르면 되돌아가는" 토글이 실제로는 삭제 후 재생성이면 되돌린 것처럼 보여도 같은 상태가 아니다.

- 새 id·등록 시각이 생겨 정렬 위치가 바뀌고, 고정 같은 부가 상태가 사라진다.
- FK `ON DELETE CASCADE`로 연결된 데이터(예: 대시보드 위젯)는 재생성해도 돌아오지 않는다.

## 패턴

1. **대기 상태:** 해제를 누르면 서버를 호출하지 않고 대기 목록(Set)에만 넣는다. 카드는 흐리게 표시하고 제자리에 둔다. 다시 누르면 대기 목록에서 뺀다.
2. **영향 안내:** 연쇄 삭제될 대상이 있으면 카드와 요약 막대에 알린다(예: "대시보드 위젯 2개도 함께 삭제"). 안내는 레이아웃을 밀지 않게 기존 영역 위에 겹친다.
3. **일괄 저장:** 요약 막대의 `저장`으로 대기 목록을 한꺼번에 삭제하고, 실패한 항목만 대기로 남긴다. `되돌리기`로 전체 취소.
4. **이동 가드:** 대기 항목이 있을 때 앱 내 이동은 `저장 후 이동 / 저장하지 않고 이동 / 취소`를 묻는다. 새로고침·탭 닫기는 `beforeunload`(브라우저 기본 문구만 가능).
5. **실패 방향:** 가로챌 수 없는 이탈(브라우저 뒤로 가기 등)은 대기 목록을 버려 "데이터가 남는" 쪽으로 끝낸다.

## 이동 가드 구현 요령 (Next.js App Router)

App Router는 라우트 전환을 막는 공식 훅이 없다. 이동을 일으키는 핸들러를 한 함수로 감싸는 방식이 단순하다.

```ts
type LeaveInterceptor = (proceed: () => void) => boolean
let interceptor: LeaveInterceptor | null = null
export const setLeaveInterceptor = (next: LeaveInterceptor | null) => { interceptor = next }
export function guardLeave(proceed: () => void) {
  if (interceptor?.(proceed)) return   // 가로챈 쪽이 확인창을 띄우고 나중에 proceed 호출
  proceed()
}
```

- 화면은 마운트 시 인터셉터를 등록하고 언마운트 시 해제한다. 대기 항목이 없으면 `false`를 돌려 그대로 통과시킨다.
- 인터셉터 안에서는 state가 아닌 ref로 대기 목록을 읽는다(등록 시점 클로저 고정 문제).
- 새 이동 경로를 추가할 때 `guardLeave`로 감싸는 것을 잊기 쉽다. 이동 핸들러를 한 곳(레이아웃)에 모아 둔다.

## 언제 쓰지 않나

- 기기·세션을 넘어 되돌리기가 필요하면 서버 보관 후 삭제(`deleted_at`)로 간다.
- 연쇄 삭제가 없고 복원이 완전하면 즉시 반영 + 되돌리기 토스트가 더 가볍다.

## 실제 사례

- [[projects/dna-sql-agent/decisions/044-bookmark-page-deferred-remove]]
