---
type: session-log
project: dna-sql-agent-web
date: 2026-07-24
duration: 
focus: "SQL 카드 렌더링 성능 개선 + 채팅 목록 로딩 체감 지연 조사"
tools-used: [claude-code, claude-in-chrome]
outcome: success
---

# 2026-07-24 — SQL 카드 렌더링 성능 개선 + 채팅 목록 로딩 체감 지연 조사

## 목표

메인 채팅 화면 SQL 카드 렌더링 방식 파악에서 시작해, "DOM 수정 때문에 렌더가 오래 걸린다"는 지적을 검증하고 실제로 고치는 것. 이어서 "채팅 목록 로딩이 느린 것 같다"는 체감 문제 원인 조사.

## 수행한 작업

1. `components/sql-block.tsx` 구조 파악 — `sql-formatter`(포맷팅) → `Prism.highlight()`(HTML 문자열 생성) → `dangerouslySetInnerHTML`로 DOM 주입 구조 확인
2. `dangerouslySetInnerHTML` + 매번 재계산 문제 식별: `useMemo` 없이 매 리렌더마다 `formatSQL()`/`Prism.highlight()` 재실행 → `Prism.tokenize()` + 재귀 `renderToken()`으로 React `<span>` 트리 생성하는 방식으로 교체, `useMemo(..., [sql])`로 캐싱
3. Node.js + jsdom으로 구버전/신버전 벤치마크 스크립트 작성·실행 — 34,079자 SQL, 30회 리렌더 시뮬레이션에서 **4729ms → 748ms (약 84% 감소)** 확인. 대부분은 `dangerouslySetInnerHTML` 자체보다 메모이제이션 부재가 원인
4. 브라우저에서 직접 확인 가능하도록 벤치마크를 Artifact(HTML, Prism 인라인 번들)로 만들어 시각화 — 첫 배포 시 유저가 "아무 동작 없다"고 보고, claude-in-chrome으로 직접 열어 재현·정상 동작 확인 (act() 경고는 무해, 콘솔 에러 없음)
5. 관리자(admin) 쪽 SQL 관련 라이브러리 확인 — `@uiw/react-codemirror` + `@codemirror/lang-sql`이 있으나 **입력용 에디터**(`sql-editor.tsx`)에만 쓰이고, 읽기 전용 미리보기는 채팅과 동일하게 `sql-formatter` + `prismjs` 사용 중임을 확인 → 채팅 SQL 카드에 CodeMirror 도입은 보류
6. `sql-formatter`가 내부적으로 파싱하지만 토큰을 공개 API로 노출하지 않음을 확인(`lexer/Tokenizer` 등은 딥임포트로만 접근 가능, 비공식) → Prism과의 이중 파싱 구조를 그대로 유지하기로 결정
7. git 작업 중 실수로 `feat/group-admin`의 미완료 변경사항 전체(73개 파일)가 `perf/sql-block-render` 브랜치 인덱스에 섞여 스테이징된 사고 발생 → `git stash push -u`로 안전 보관 후 `origin/main`(당시 이미 `feat/group-admin` PR #72 머지된 최신 지점) 기준으로 브랜치 리셋, `git checkout stash@{0} -- components/sql-block.tsx`로 필요한 파일만 복구
8. `perf/sql-block-render` 브랜치에 SQL 카드 수정 커밋(`aad250a`) 후 push, PR 본문 초안 작성(사용자가 PR 생성은 직접 하기로 함)
9. "채팅 목록 로딩이 느리다" 조사 — `hooks/use-conversations.ts` 로그인 초기화 로직에서 `loadMySystems()` → `loadConnections()` → `loadConversationList()`가 순차 `await` 체이닝되어 있음을 발견. `loadConnections`은 systems/목록과 완전히 독립적(코드 내 참조 없음)인데 불필요하게 직렬화되어 있었음 → `loadConnections`를 `loadMySystems`와 병렬 실행, `loadConversationList`만 `loadMySystems` 완료를 기다리도록 수정
10. claude-in-chrome으로 실제 dev 서버(`localhost:3000`) 접속해 `performance.getEntriesByType('resource')`로 검증 — `connections`(67ms)와 `systems`(72ms)가 정확히 동시 시작함을 확인해 병렬화 반영 검증. 단, 전체 페이지 `loadEvent`가 2.5~3초로 API 시간(수십~수백 ms)을 압도 — **원인이 `next dev`(Turbopack 개발 서버)의 번들 비압축/HMR 오버헤드**임을 규명, 프로덕션 빌드 재확인 필요성 안내
11. `.vscode/launch.json`에 "Run Script: build & start" 설정 추가 (프로덕션 빌드로 실제 성능 확인용)
12. `use-conversations.ts` 병렬화 수정 커밋(`9f8a8f2`, 같은 브랜치, push는 보류)

## 핵심 결정

- **결정 1:** SQL 카드 하이라이팅은 `sql-formatter` + `Prism` 이중 파싱 구조를 유지하고, Prism을 걷어내거나 sql-formatter 내부 토크나이저를 딥임포트하는 최적화는 하지 않는다.
  → ADR: [[decisions/016-sql-block-keep-dual-parse-prism-sql-formatter]]

## 배운 것

- `useMemo` 캐싱이 있으면 파싱을 두 번 하는 구조적 비효율은 실사용에서 거의 체감되지 않는다 (SQL 문자열이 바뀔 때만 재계산되므로) — "이론적으로 비효율"과 "실제로 느림"을 구분해서 판단해야 함
- 성능 벤치마크는 실제 두 구현을 나란히 real DOM(jsdom) + React로 돌려서 재는 게 가장 설득력 있음. 정적인 설명만으로는 "차이를 모르겠다"는 반응이 나올 수 있음
- 라이브러리 내부 구현(`sql-formatter`의 `lexer/Tokenizer`)이 파일로 존재해도 공개 API가 아니면 딥임포트하지 말 것 — semver 보장 밖이라 버전업 시 조용히 깨질 위험
- `next dev`는 프로덕션 대비 페이지 로드가 몇 배 느릴 수 있다 (Turbopack HMR 클라이언트, 비압축 번들). "느려 보인다"는 체감 보고를 받으면 **API 응답 시간보다 dev/prod 여부를 먼저 확인**하는 게 진단 순서상 맞다
- git에서 여러 `reset`/`merge`를 거친 뒤엔 `git status`가 보여주는 스테이징 내용이 의도와 다를 수 있다 — 큰 diff가 스테이징돼 있으면 커밋 전에 반드시 `git diff --cached --stat`로 스코프를 확인해야 함 (이번 세션에서 이걸로 사고를 미리 잡음)

## 문제 & 해결

- **문제:** `perf/sql-block-render` 브랜치에 `feat/group-admin`의 미완료 작업 73개 파일이 실수로 스테이징된 상태로 남아 있었음 (여러 차례 `merge`/`reset` 반복 후 발생)
- **원인:** `git reset --soft`로 HEAD만 뒤로 이동하고 인덱스는 이전(더 앞선) 상태 그대로 남아있어, HEAD 대비 diff가 거대해짐
- **해결:** `git stash push -u`로 전체 보관 → `git fetch` + `git reset --hard origin/main`으로 깨끗한 베이스 확보 → `git checkout stash@{0} -- components/sql-block.tsx`로 필요한 파일만 복원 → 필요한 diff만 커밋. 원래 스테이징돼 있던 group-admin 관련 변경은 스태시에 그대로 보존(삭제하지 않음)

## 다음 할 일

- [ ] `perf/sql-block-render` 브랜치의 `use-conversations.ts` 병렬화 커밋(`9f8a8f2`) push 여부 확인
- [ ] PR 생성 (사용자가 직접 진행 예정)
- [ ] 프로덕션 빌드(`npm run build && npm run start`)로 실제 체감 속도 재확인 — `.vscode/launch.json`에 설정 추가해둠
- [ ] 스태시에 보관된 `feat/group-admin` 관련 미완료 변경사항(`stash@{1}` 등 확인 후) 처리 필요 여부 점검

## 효과적이었던 프롬프트

```
prism의 역할이 정확히 뭐야
sql-formatter가 파싱은 못하나봐?
파싱 두 번 안 하게 합쳐볼 수 있나
```
→ 구현을 먼저 밀어붙이지 않고 "정확히 뭘 하는지" 단계적으로 캐물어서, 불필요한 라이브러리 교체(CodeMirror, 자체 토크나이저) 대신 현재 구조를 유지하는 합리적 결론에 도달함.
