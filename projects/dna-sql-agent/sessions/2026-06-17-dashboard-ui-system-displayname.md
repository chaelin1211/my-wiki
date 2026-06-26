---
type: session-log
project: dna-sql-agent, dna-sql-agent-web
date: 2026-06-17
duration: ~4h
focus: "대시보드 UI 개선 — 위젯 추가/제거, 스크롤 그림자, system_display_name 백엔드 통합, git 히스토리 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-06-17 — 대시보드 UI 개선 & system_display_name 백엔드 통합

## 목표

- 위젯 추가 패널에서 이미 추가된 위젯 제거 가능하도록 UX 개선
- 스크롤 영역 그림자 추가
- 시스템 한글명 깜빡임 제거 (백엔드 API에 포함)
- 잘못 커밋된 파일 git 히스토리에서 제거

## 수행한 작업

1. **위젯 추가 패널 이미-추가된 위젯 hover → X 표시 & 제거**
   - 체크 아이콘 → X 아이콘 교체 (group-hover z-layer 구조)
   - 호버 시 destructive red 테두리 + 배경 오버레이 (full-card 빨간 느낌)
   - 미추가 위젯은 primary 컬러, 추가된 위젯은 destructive 컬러로 차별화
   - `onRemoveByBookmarkId` prop으로 dashboard-detail까지 배선

2. **차트 인터랙션 차단**
   - 위젯 추가 패널 미리보기 카드에 `pointer-events-none` 오버레이 추가

3. **스크롤 그림자 추가**
   - widget-add-panel, dashboard 그리드, bookmark-view 세 곳에 동일 패턴 적용
   - `useRef + onScroll + useState(shadowTop/Bottom)` → `bg-gradient-to-b from-muted/60 dark:from-muted/30`
   - 다크모드 opacity 완화 (from-muted/30, from-muted/40)

4. **새로고침 버튼 툴팁 — 정확한 로드 시각**
   - `formatCachedAtExact()` 함수로 `toLocaleString('ko-KR')` 포맷
   - 위젯 푸터 + 크게보기 모달 헤더 두 곳에 `<Tooltip>` 래핑

5. **system_display_name 백엔드 통합**
   - 백엔드: bookmark/dashboard widget 조회 쿼리에 `LEFT JOIN systems` 추가 → `system_display_name` 반환
   - 프론트: `getSystems()` 별도 호출 제거, `bookmark.systemDisplayName` / `widget.systemDisplayName` 직접 사용
   - 효과: 한글명 깜빡임 완전 제거

6. **PPT 애드인 대응**
   - `conversation-list.tsx`의 대시보드 버튼에 `!isOfficeAddin` 조건 추가

7. **git 히스토리 수정 (git filter-branch)**
   - 커밋 `930a25c`에 `.claude/`, `CLAUDE.md`, `public/icons-unused` 실수로 포함됨
   - `git filter-branch --index-filter 'git rm --cached --ignore-unmatch -r ...'`로 제거
   - 부작용: filter-branch가 기존 추적 파일(`icons-unused/icon-*.png` 등)도 삭제
   - 해결: `git checkout <원래커밋> -- <파일>` + `git reset HEAD`로 디스크에 복원
   - 이슈: [[issues/git-filter-branch-side-effect-tracked-files]]

## 핵심 결정

- **system_display_name을 API 응답에 포함**: 프론트에서 별도 getSystems JOIN 없이 한글명 즉시 표시.
  백엔드 단일 쿼리에서 `LEFT JOIN systems s ON s.system_name = c.system_name AND s.connection_id = (SELECT id FROM connections WHERE connection_name = c.connection_name LIMIT 1)` 패턴 사용.
  → 기존 ADR-015 범위 내

## 배운 것

- `git filter-branch --index-filter`는 지정 범위의 **모든** 커밋 인덱스에 명령을 적용 — 이전부터 존재하던 추적 파일도 삭제될 수 있음
- 복구: `git checkout <원본커밋> -- <파일>` 후 `git reset HEAD <파일>`로 언트래킹 상태로 복원
- filter-branch 전 `git stash` 필수 (unstaged 변경사항 있으면 실행 불가)
- 스크롤 그림자 패턴: `from-background` 대신 `from-muted/60`이 카드 배경과 자연스럽게 어울림

## 문제 & 해결

- **문제:** git filter-branch 후 `public/icons-unused/icon-*.png`, `.claude/commands/`, `CLAUDE.md` 등 디스크에서 사라짐
- **원인:** filter-branch가 지정 커밋 이후 범위 전체에서 파일을 인덱스에서 제거 → 이전 커밋에서 추적되던 파일도 "삭제" 처리됨
- **해결:** 각 파일의 원래 커밋에서 `git checkout <commit> -- <path>`로 복원, `git reset HEAD`로 언트래킹
  → 이슈: [[issues/git-filter-branch-side-effect-tracked-files]]

- **문제:** `1648529` 커밋이 `icon-*.png` 등을 삭제하는 diff 포함
- **원인:** filter-branch가 해당 커밋 인덱스에서 이전부터 존재하던 파일도 제거
- **해결:** blob hash 직접 조회 후 `git update-index --add --cacheinfo`로 filter-branch 재실행하여 복원

## 다음 할 일

- [ ] 백엔드 feat/dashboard PR 생성 및 머지
- [ ] 프론트엔드 feat/dashboard PR 생성 및 머지
- [ ] 배포 검증 완료 후 워크플로우 ref를 main으로 되돌리기
