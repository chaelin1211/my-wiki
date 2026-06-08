---
type: session-log
project: dna-sql-agent-web
date: 2026-06-01
duration: ~4h
focus: "SQL 에디터 CodeMirror 교체, 다이얼로그 UI 개선, 상태 태그 통일"
tools-used: [claude-code]
outcome: success
---

# 2026-06-01 — CodeMirror SQL 에디터 교체 및 UI 폴리시

## 목표

- SQL 에디터의 auto-resize 문제 해결
- 어드민 UI 일관성 개선 (상태 태그, 다이얼로그 레이아웃)
- SQL 포맷팅 기능 추가

## 수행한 작업

1. **expires_in fallback 상수 추출** (`fetch-client.ts`, `auth-page.tsx`)
   - `?? 1800` 두 곳에 박혀 있던 매직 넘버 → `DEFAULT_EXPIRES_IN = 1800` 상수로 추출
   - `saveTokens` 파라미터 타입 `number` → `number | undefined`로 변경, 내부에서 fallback 처리

2. **SQL 에디터 CodeMirror 교체** (`sql-editor.tsx`)
   - Prism + pre/textarea 레이어드 구조 → `@uiw/react-codemirror` 단일 컴포넌트
   - auto-resize 기본 지원, `dangerouslySetInnerHTML` 제거
   - `EditorView.theme({ '&': { fontSize: '12px' } })` 로 폰트 크기 조정
   - `oneDark` / `light` 테마 자동 전환 (`useTheme`)
   - → ADR: [[decisions/010-codemirror-sql-editor]]

3. **SQL 예제 테이블 미리보기** (`sql-examples-table.tsx`)
   - Prism CSS import를 테이블 파일이 직접 소유
   - CodeMirror로 교체 시도 → 블록 느낌 거슬린다는 피드백 → Prism 유지 결정

4. **SQL 예제 다이얼로그 UI 개선** (`sql-example-dialog.tsx`)
   - Format 버튼 위치: 에디터 오버레이 → "SQL (필수)" 라벨 우측으로 이동
   - `sql-formatter` 도입, `handleFormat` 로직 다이얼로그로 이동
   - 태그 추가 버튼 `size="sm"` (h-8) → 기본 (h-9), Input과 높이 통일
   - Textarea `px-3 py-2` 중복 제거, fontSize 14→13, lineHeight 1.25→1.4
   - 스크롤 컨테이너 `pl-[3px]` 추가 — overflow-y-auto로 인한 좌측 focus ring 클리핑 수정
   - → 이슈: [[knowledge/troubleshooting/overflow-y-auto-focus-ring-clip]]

5. **DB 관리 상태 컬럼 태그 통일** (`connection-list.tsx`, `system-list.tsx`, `sql-examples-table.tsx`)
   - 기존: `<span className="text-xs text-muted-foreground">{status}</span>`
   - 변경: 사용자 탭과 동일한 초록/회색 rounded-full 태그
   - 상태 컬럼 `w/min-w/max-w [130px]` 고정

6. **PR #32 생성** — `feat/admin-improvements` → main

## 핵심 결정

- **CodeMirror 채택**: auto-resize 구현 불가 (pre/textarea 레이어드 구조 한계) + dangerouslySetInnerHTML 제거 + 테마 시스템 통합. MIT 라이선스, 어드민 전용이라 번들 크기 무관
  → ADR: [[decisions/010-codemirror-sql-editor]]
- **sql-formatter 언어 generic 유지**: 서버 수집 포맷과 차이(`FROM\n  table`, `FETCH FIRST\n  100 ROWS ONLY`)가 있으나, Format 버튼은 수동 작성 쿼리용으로 사용 관례로 처리
- **SQL 예제 미리보기 Prism 유지**: CodeMirror 블록 UI가 테이블 셀에 부적합 → Prism + CSS import 직접 소유 방식 유지

## 문제 & 해결

- **문제:** SQL 예제 다이얼로그 input 좌측 focus ring이 잘림
- **원인:** `overflow-y-auto` 설정 시 CSS 스펙에 의해 `overflow-x`도 `auto`로 변경 → scroll container 생성 → box-shadow(ring) 클리핑
- **해결:** 스크롤 컨테이너에 `pl-[3px]` 추가 (ring 3px 공간 확보)
  → [[knowledge/troubleshooting/overflow-y-auto-focus-ring-clip]]

- **문제:** SQL 에디터 auto-resize 시도 시 에디터 레이아웃 깨짐
- **원인:** pre(absolute, h-full, overflow-hidden) + container(overflow-hidden) + textarea 구조에서 height 측정/설정 순서 충돌
- **해결:** CodeMirror로 교체 (auto-resize 내장)

## 다음 할 일

- [ ] PR #32 리뷰 및 머지
- [ ] URL 라우팅 전환 (Next.js App Router)
- [ ] 어드민 toast 한국어 + JSX 패턴 통일
- [ ] Connections status 토글 깜빡임 옵티미스틱 업데이트
