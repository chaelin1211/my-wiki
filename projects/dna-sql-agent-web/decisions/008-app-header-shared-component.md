---
type: decision-record
project: dna-sql-agent-web
date: 2026-05-28
status: accepted
superseded-by: ""
tags: [ui, component, office-addin]
---

# ADR-008: AppHeader 공통 컴포넌트 추출

## 맥락

`chat-header.tsx`와 `bookmark-view.tsx`의 헤더가 동일한 구조를 가지고 있었다:
- 왼쪽: 아이콘 + 타이틀 영역
- 오른쪽: (뷰별 추가 버튼) + 마이페이지 버튼 + 다크모드 토글

마이페이지 버튼은 PPT(Office Add-in) 환경에서 숨겨야 하는 조건이 있는데, `chat-header.tsx`에만 `useIsOfficeAddin()` 체크가 있었고 `bookmark-view.tsx`는 누락돼 있었다. 공통 로직이 분산되면 한쪽만 수정되고 다른 쪽은 누락되는 문제가 반복된다.

## 선택지

### 옵션 A: 각 뷰에서 직접 처리 (현상 유지)
- **장점:** 변경 범위가 작음
- **단점:** 공통 로직 중복, 누락 위험 반복
- **비용/노력:** 낮음 (단기), 높음 (장기 유지보수)

### 옵션 B: AppHeader 공통 컴포넌트 추출
- **장점:** 마이페이지/다크모드 로직 단일 관리, 새 뷰 추가 시 일관성 보장
- **단점:** 아이콘·타이틀이 뷰마다 달라 슬롯 설계 필요
- **비용/노력:** 중간

## 결정

**옵션 B를 선택한다.**

```tsx
interface AppHeaderProps {
  icon?: ReactNode    // 선택 — 없으면 공간 생략, 향후 아이콘 없는 헤더 지원
  children: ReactNode // 필수 — 타이틀 영역 (뷰마다 다름)
  actions?: ReactNode // 선택 — 뷰별 추가 버튼 (chat: PDF/PPT 버튼)
}
```

내부에서 공통 처리: `useIsOfficeAddin()` → 마이페이지 버튼 조건부 렌더, 다크모드 토글

## 근거

- 조건 로직이 분산되면 신규 뷰 추가 시 누락이 구조적으로 발생
- `icon?` 선택 prop으로 설계해 향후 아이콘 없는 헤더도 지원
- `children` + `actions?` 슬롯으로 뷰별 커스터마이징 유지

## 결과

- `components/app-header.tsx` 신규 생성
- `bookmark-view.tsx` / `chat-header.tsx` 중복 코드 제거
- 향후 헤더가 필요한 뷰는 AppHeader를 기본으로 사용
- 트레이드오프: 헤더 레이아웃 전체 변경 시 AppHeader 수정이 모든 뷰에 영향

## 참고 자료

- [[sessions/2026-05-28-responsive-ui-pr-and-app-header]]
- [[issues/bookmark-header-missing-office-addin-check]]
