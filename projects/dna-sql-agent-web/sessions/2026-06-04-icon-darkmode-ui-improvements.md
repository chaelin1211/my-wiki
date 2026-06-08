---
type: session-log
project: dna-sql-agent-web
date: 2026-06-04
duration: ~1h
focus: "파비콘/아이콘 재설계 및 다크모드 UI 스타일 개선"
tools-used: [claude-code]
outcome: success
---

# 2026-06-04 — 파비콘·아이콘 재설계 & 다크모드 UI 스타일 개선

## 목표

- 파비콘/Apple 아이콘 재설계 (오렌지 색상 시스템 반영)
- 다크모드에서 버튼·토글·라디오 UI 스타일 불일치 수정
- ToggleGroup default 변형 시각적 완성도 향상

## 수행한 작업

1. **SVG 파비콘 및 Apple 아이콘 교체**
   - `favicon.svg`: 연한 오렌지 라운드 스퀘어 배경 + 로고 삽입 (ADR-012 오렌지 포인트 반영)
   - `apple-icon.png`: 1024×1024 Apple 터치 아이콘 재생성
   - `logo.png`: 투명 배경 버전으로 교체
   - `next.config.mjs`: 개발 서버 허용 origin 추가

2. **다크모드 버튼/토글/라디오 스타일 개선** (`app/globals.css`, `components/ui/`)
   - `--primary-foreground` → 흰색(`#ffffff`)으로 변경 (다크모드 버튼 텍스트 가시성)
   - `--ring` → `var(--primary)` 통일 (포커스 링 색상 일관성)
   - `outline` 버튼/토글 hover 시 border를 primary 색으로 변경
   - 라디오 버튼(`radio-group.tsx`) 다크모드 테두리 가시성 개선

3. **ToggleGroup default 변형 스타일 개선** (`toggle-group.tsx`, `toggle.tsx`)
   - default 변형에 border 및 뮤트 배경 추가
   - 아이템 간 이중 border 제거 (`border-l-0` 방식 통일)
   - outline 변형 선택 시 border primary 색상 유지
   - outline/default 모두 hover 시 border primary 색상으로 변경

4. **문서 보완**: `docs/ui-components-design.md`에 디자인 미리보기 경로 안내 추가

## 핵심 결정

- **아이콘 파일 정리:** 기존 logo.png/apple-icon.png를 `public/icons-unused/`로 이전하고 새 버전으로 교체. SVG 파비콘에 오렌지 배경 적용 (ADR-012 색상 시스템 일관성)
- **다크모드 primary-foreground:** 흰색 고정 — 오렌지 primary 위 텍스트가 오렌지 계열이면 가시성 불량

## 배운 것

- Tailwind의 outline 변형 버튼에서 hover border 색상은 `hover:border-primary`로 별도 지정 필요 (ring 설정과 별개)
- ToggleGroup 아이템 간 이중 border 제거 시 `[&:not(:first-child)]:border-l-0` 패턴이 깔끔

## 문제 & 해결

- **문제:** 다크모드에서 primary 버튼 텍스트가 흰색이 아닌 오렌지 계열로 보여 가시성 낮음
- **원인:** `--primary-foreground`가 라이트/다크 공통으로 오렌지 계열 값으로 설정되어 있었음
- **해결:** 다크모드 `:root.dark` 블록에서 `--primary-foreground: oklch(1 0 0)` (흰색) 으로 재정의

## 다음 할 일

- [x] `feat/icon-darkmode-ui` 브랜치 PR 생성 및 main 머지
- [ ] style/ui-spacing 브랜치 PR 생성 및 머지 (기존 대기 중)
- [ ] PR #33 머지 (ECharts)
