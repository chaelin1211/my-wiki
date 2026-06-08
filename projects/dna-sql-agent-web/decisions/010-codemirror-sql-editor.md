---
type: decision
project: dna-sql-agent-web
id: "010"
title: "SQL 에디터 CodeMirror 전환 (Prism 제거)"
date: 2026-06-01
status: accepted
---

# ADR-010 — SQL 에디터 CodeMirror 전환

## 맥락

`sql-editor.tsx`는 syntax highlighting을 위해 Prism + `pre`/`textarea` 레이어드 구조를 사용했다.
이 구조는 pre(absolute, h-full) + container(overflow-hidden) + textarea가 얽혀 있어 auto-resize 구현이 사실상 불가능했다.
긴 SQL 쿼리 입력 시 세로 스크롤이 발생해 UX가 나쁘고, `dangerouslySetInnerHTML`로 인한 보안 리스크도 있었다.

## 결정

`@uiw/react-codemirror` + `@codemirror/lang-sql` + `@codemirror/theme-one-dark`로 교체한다.

## 결과

**장점**
- auto-resize 기본 지원 (`EditorView.lineWrapping`)
- `dangerouslySetInnerHTML` 완전 제거
- 다크/라이트 테마 자동 연동 (`useTheme` → `oneDark` / `'light'`)
- CodeMirror 6 기반 — Chrome DevTools, Firefox DevTools 등 신뢰도 높음
- MIT 라이선스

**단점/비용**
- 번들 증가 (~100KB gzip) — 어드민 전용 페이지라 영향 없음
- `dynamic import` 적용 가능하나 현재 미적용

## 미적용 결정

SQL 예제 테이블 미리보기 셀(`sql-examples-table.tsx`)은 CodeMirror 적용 시 블록 에디터 느낌이 강해 부적합 → Prism + CSS import 직접 소유 방식으로 유지.
