---
type: session-log
project: dna-sql-agent-web
date: 2026-05-27
duration: ~3h
focus: "시스템 권한 매트릭스 UX 전면 재설계"
tools-used: [claude-code]
outcome: success
---

# 2026-05-27 — 시스템 권한 매트릭스 UX 재설계

## 목표

- 관리자 > 시스템 권한 탭의 혼란스러운 UX 구조를 개선
- 상단 Select 필터 제거, 매트릭스 셀 동작 직관화, 상세 편집 팝업화

## 수행한 작업

1. **반응형 처리** — `permission-list.tsx` 검색 영역을 `user-list.tsx`와 동일한 패턴으로 개선 (커밋 완료)
2. **매트릭스 아이콘 의미 수정** — ✓/✗가 각각 현재 상태를 나타내도록 변경 (✓ 초록=권한 있음, ✓ 흐림=권한 없음)
3. **native title → shadcn Tooltip** 교체 (즉시 표시)
4. **sticky 컬럼 고정 너비 수정** — `min-w`만으로는 두 번째 컬럼 `left` 오프셋 틀어짐 → `w + min-w + max-w` + truncate
5. **UX 전면 재설계**:
   - 상단 사용자 Select 필터 / 권한 추가 버튼 제거
   - 사용자 행 클릭 → 권한 상세 Dialog 팝업
   - 하단 "선택된 사용자의 권한" 테이블을 Dialog 내부로 이동
6. **매트릭스 깜빡임 수정** — `loading` prop이 매트릭스 전체를 교체하던 구조 → Dialog 내부 로딩으로 한정
7. **옵티미스틱 업데이트** — 셀 토글 시 API 응답 기다리지 않고 즉시 UI 반영, 실패 시 롤백
8. **셀 토글 race condition 수정** — `onGrant/onRevoke`는 `selectedUserId` 클로저에 묶여 있어 다른 사용자 토글 시 API 미호출 → `grantPermission/revokePermission` 직접 호출로 교체
9. **권한 추가 인라인 row** — "권한 추가" 클릭 시 Dialog 팝업 대신 테이블 상단에 row 삽입 (Select + tag input + 저장/취소)

## 핵심 결정

- **옵티미스틱 업데이트 채택**: 매트릭스 셀 토글은 API 호출이 잦으므로 UI 반응성 우선, 실패 시 Set 기반 롤백
  → ADR: [[decisions/006-optimistic-update-permission-matrix]]

- **인라인 추가 row**: 권한 추가를 별도 팝업 대신 테이블 내 row로 처리, 컨텍스트 유지 + 단계 최소화

## 배운 것

- HTML table에서 sticky 컬럼은 `min-w`만으로는 두 번째 컬럼 left 오프셋이 틀어짐 → `w` + `max-w` 세트 필요
- React hook의 `userId` 클로저 문제: 부모에서 prop으로 내려온 콜백은 mount 시점의 state를 캡처 → state 변경 후 바로 호출하면 stale value 사용

## 문제 & 해결

- **문제:** 사용자 클릭 시 매트릭스 전체 깜빡임
- **원인:** `permsLoading`이 `loading` prop으로 전달되어 `if (loading) return <Spinner>` 블록이 매트릭스 전체를 교체
- **해결:** 최상단 loading guard 제거, Dialog 내부에만 로딩 표시
  → 이슈: [[issues/permission-matrix-flicker-on-user-select]]

- **문제:** 매트릭스 셀 토글 시 API가 selectedUserId로 호출되어 다른 사용자 셀 클릭 시 잘못된 대상에 적용
- **원인:** `onGrant/onRevoke`가 `useUserPermissions(selectedUserId)` 훅의 클로저에 묶임
- **해결:** `grantPermission/revokePermission`을 컴포넌트에서 직접 호출, userId를 인자로 직접 전달

- **문제:** sticky 두 번째 컬럼(그룹) 위치 어긋남
- **원인:** 첫 번째 컬럼 `min-w-[180px]` → 이메일이 길면 실제 너비 > 180px
- **해결:** `w-[180px] min-w-[180px] max-w-[180px]` + `truncate`로 정확히 180px 고정

## 다음 할 일

- [ ] 지금까지 변경사항 `feat/responsive-ui` 브랜치에 커밋
- [ ] PR 생성 (반응형 + 권한 매트릭스 UX 개선 전체)
- [ ] 권한 삭제(휴지통) AlertDialog 내 텍스트 "취소" 중복 (AlertDialogAction과 AlertDialogCancel 모두 취소) — 버튼 문구 재검토
