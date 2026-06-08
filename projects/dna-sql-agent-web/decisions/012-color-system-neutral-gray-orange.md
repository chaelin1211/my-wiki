---
type: decision-record
project: dna-sql-agent-web
date: 2026-06-02
status: accepted
superseded-by: ""
tags: [ui, color, design-system, tailwind, oklch]
---

# ADR-012: 전체 색상 시스템 뉴트럴 그레이 + 오렌지 포인트로 교체

## 맥락

기존 색상 시스템은 hue 280(보라색) 기반으로 primary/accent/secondary/background 모두 보라 톤이었다.
디자인 방향이 바뀌면서 보라색을 제거하고 뉴트럴한 그레이 베이스에 오렌지 포인트 컬러를 적용하기로 했다.
Tailwind CSS v4를 사용 중이라 CSS 변수(`globals.css`)가 색상 시스템의 단일 진실 공급원(SSOT)이다.

## 선택지

### 옵션 A: CSS 변수 전체 교체 (채택)
- **장점:** hue 값 하나만 바꾸면 포인트 컬러 전체 교체 가능. 컴포넌트 코드 변경 불필요.
- **단점:** 한 번에 많은 변수를 바꿔야 하므로 실수 가능성.
- **비용/노력:** 중간 (globals.css 1개 파일)

### 옵션 B: Tailwind 커스텀 컬러 팔레트 별도 정의
- **장점:** 기존 변수와 공존 가능.
- **단점:** Tailwind v4는 CSS 변수 방식 권장. 관리 포인트 증가.
- **비용/노력:** 높음

## 결정

**옵션 A를 선택한다.** CSS 변수만 교체하고 컴포넌트 코드는 유지.

## 근거

- Tailwind v4는 `@theme inline`으로 CSS 변수를 Tailwind 토큰과 매핑하는 구조 → CSS 변수가 SSOT
- 포인트 컬러를 바꿀 때 `hue` 값(현재 42) 하나만 바꾸면 전체 적용됨
- OKLCH는 명도(L)/채도(C)/색상(H) 분리가 직관적 → 라이트/다크 전환 시 L 값만 조정

## 색상 설계

| 토큰 | 라이트 | 다크 | 용도 |
|---|---|---|---|
| `--background` | oklch(0.94 0 0) | oklch(0.24 0.006 60) | 페이지 배경 |
| `--card` | oklch(1 0 0) | oklch(0.27 0.006 60) | 카드·채팅 목록 |
| `--muted` | oklch(0.93 0 0) | oklch(0.40 0.006 60) | hover·비활성 |
| `--border` | oklch(0.88 0 0) | oklch(0.38 0.006 60) | 구분선 |
| `--primary` | oklch(~0.69 0.17 40) | oklch(~0.57 0.17 41) | 오렌지 포인트 |
| `--sidebar-accent` | oklch(0.93 0 0) | oklch(0.32 0.08 42) | 사이드바 active |

**다크 배경 계층 (낮은 명도 → 높은 명도):**
`background(0.24)` → `card(0.27)` → `muted(0.40)`

이 순서가 깨지면 hover가 역방향(더 어두워짐)으로 표시된다.

## 결과

- 포인트 컬러 변경 시: `globals.css`에서 primary/accent의 hue(현재 40~42) 값만 수정
- 라이트 배경은 완전 뉴트럴(chroma 0), 다크 배경은 극저채도(chroma 0.006) warm tint 유지
- violet/indigo 태그 팔레트 항목 → orange/lime으로 교체 (`lib/group-color.ts`, `lib/utils.ts`)

## 참고 자료

- [OKLCH Color Space](https://oklch.com/)
- Tailwind CSS v4 CSS 변수 기반 테마 방식
