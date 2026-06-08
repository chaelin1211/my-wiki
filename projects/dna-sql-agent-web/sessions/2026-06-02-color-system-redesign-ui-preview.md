---
type: session-log
project: dna-sql-agent-web
date: 2026-06-02
duration: ~3h
focus: "전체 색상 시스템 교체 + UI 컴포넌트 정비 + /ui 미리보기 페이지 보강"
tools-used: [claude-code]
outcome: success
---

# 2026-06-02 — 색상 시스템 리뉴얼 및 UI 컴포넌트 정비

## 목표

- 전체 색상을 보라색 → 뉴트럴 그레이 + 오렌지 포인트로 교체
- 다크모드 UI 가시성 문제 개선
- /ui 미리보기 페이지 컴포넌트 보강

## 수행한 작업

1. **색상 시스템 전면 교체** (`app/globals.css`)
   - `:root` 라이트 모드: hue 280(보라) → 뉴트럴 그레이(chroma 0) + 오렌지 포인트(hue 42)
   - `.dark` 다크 모드: 다크 웜 그레이(hue 60, 극저채도) + 오렌지 포인트
   - 포인트 컬러: `oklch(0.56 0.20 42)` (light) / `oklch(0.68 0.20 42)` (dark)
   - 태그 팔레트에서 violet, indigo 제거 (orange, lime으로 교체)

2. **채팅 창·북마크 배경 정비**
   - 채팅 창: `dark:bg-card/70` → `dark:bg-background` (불투명, admin/mypage와 통일)
   - 북마크: 동일하게 적용
   - 채팅 목록: `bg-background` → `bg-card` (배경 계층 구분)
   - 채팅창 배경 그라데이션 제거 (`app/page.tsx`)

3. **다크모드 가시성 개선**
   - `--muted` 다크: `oklch(0.26)` → `oklch(0.40)` (hover 가시성 — card 0.27보다 밝게)
   - `--border` 다크: `oklch(0.30)` → `oklch(0.38)` (구분선 가시성)
   - sidebar-accent 다크: `oklch(0.26)` → `oklch(0.32 0.08 42)` (오렌지 힌트 + 대비)
   - ghost 버튼 dark hover: `/50` → `/70` (불투명도 개선)

4. **컴포넌트 정비**
   - `Switch` thumb: 다크 unchecked → `muted-foreground`, checked → `card`
   - `Select` 체크 아이콘: `text-primary` 적용
   - `Toggle` outline variant: `border-input` → `border-border`
   - `ToggleRow`: 네이티브 `<input type="checkbox">` → shadcn `Checkbox` 교체
   - 대화 목록 새대화·북마크·관리자 inner Button에 `pointer-events-none` 추가

5. **대화 목록 레이아웃 정비**
   - 관리자 버튼 스타일 → 북마크 버튼과 동일한 구조로 맞춤
   - `agent-tab` 차트 렌더링 설정: `space-y-2` → `flex flex-col gap-2`

6. **로그인 페이지 그라데이션**
   - `from-primary/20 to-accent/20` → `from-primary/10 dark:from-primary/3` (연하게)

7. **/ui 미리보기 페이지 보강**
   - Input: 라벨+에러, 아이콘 prefix/suffix, 비밀번호 토글, 검색창(클리어 버튼)
   - Select, RadioGroup, ToggleGroup 섹션 추가
   - 색상 토큰 테이블 현행화
   - 브랜치명 `fix/ui-spacing` → `style/ui-spacing`

## 핵심 결정

- **OKLCH 기반 색상 시스템 유지**: CSS 변수 중앙 관리, hue 값 하나만 바꾸면 포인트 컬러 전체 교체 가능
  → ADR: [[decisions/012-color-system-neutral-gray-orange]]
- **다크모드 배경 계층**: background(0.24) < card(0.27) < muted(0.40) 순서로 명도 확보

## 배운 것

- Tailwind v4에서 `space-y-*`는 `> :not(:first-child)` margin 방식이라 일부 상황에서 예상대로 안 먹힘 → `flex flex-col gap-*` 권장
- outer div가 click 처리할 때 inner Button에 `pointer-events-none` 추가해야 이중 hover 방지
- OKLCH에서 chroma 0이면 hue는 의미 없음 (완전 무채색)
- 다크모드 hover 색(`--muted`)이 배경(`--card`)보다 어두우면 hover가 역방향으로 표시됨

## 문제 & 해결

- **문제:** 다크모드 대화 목록 hover가 역방향 (어두워짐)
- **원인:** `--muted(0.26)` < `--card(0.27)` — muted가 card보다 어두웠음
- **해결:** `--muted` → `oklch(0.40)`으로 올려서 card 대비 밝은 방향으로 수정

- **문제:** ToggleGroup outline 라인이 다크모드에서 안 보임
- **원인:** `border-input(oklch 0.26)`이 배경(0.27)과 거의 동일
- **해결:** `border-border(oklch 0.38)`로 교체

## 다음 할 일

- [ ] style/ui-spacing 브랜치 PR 생성 및 머지
- [ ] /ui 페이지에 Skeleton, Dialog, Sheet 등 추가 컴포넌트 보강 고려
