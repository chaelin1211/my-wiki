---
type: session-log
project: dna-sql-agent
date: 2026-07-06
duration: "장시간 (컨텍스트 압축 1회 포함)"
focus: "관리자 화면 서버사이드 페이징, 다이얼로그/슬라이더 버그 수정, 새 대화 제목 저장 버그, 시스템 목록 API 성능 개선, 한글화"
tools-used: [claude-code]
outcome: success
---

# 2026-07-06 — 관리자 화면 페이징·다이얼로그 정리, 대화 제목 버그, 시스템 목록 성능 개선

## 목표

관리자 화면(연결/시스템/사용자/그룹) UI/UX를 다듬으면서 발견되는 버그를 그때그때 수정. 세션 도중 대화 제목 저장 회귀, 설정 화면 슬라이더 입력 버그, 시스템 목록 API 응답 지연 등이 추가로 발견되어 함께 처리.

## 수행한 작업

### 1. 사이드바/대시보드 UI 한글화 (세션 전반부 — 컨텍스트 압축 이전)
- 사이드바 hover 툴팁 전체 한글화, 대시보드 이름 변경을 팝업 → conversation-list와 동일한 인라인 편집 방식으로 전환
- 대시보드 상세에서 이름 수정 시 좌측 목록에 반영 안 되던 버그 수정 (`use-dashboards.ts` `handleDetailUpdated`가 `title` 누락)

### 2. 새 대화 제목 저장 버그 (반복 발생)
- 1차: `CreateConversationRequest`에 `title` 필드 자체가 없어 프론트가 보낸 제목이 Pydantic에서 조용히 버려지고 DB에 빈 문자열로 저장되던 문제 → 필드 추가 + `"새 대화"` 기본값 삽입
- 2차(회귀): 1차 수정이 `ChatSaveHook.after_message`의 `title = '' THEN ...` 센티널 계약을 깨버림 — `"새 대화"`가 non-empty라 첫 사용자 메시지로 자동 갱신되는 로직이 영구히 멈춤. 백엔드는 title 없으면 빈 문자열 저장하도록 되돌리고, 프론트도 `createConversation(systemName, '새 대화')`에서 강제로 넘기던 title 인자를 제거 → [[issues/conversation-title-empty-string-sentinel-broken-by-default]]

### 3. 관리자 목록 서버사이드 페이징
- 연결/시스템/사용자/그룹 4개 목록 모두 클라이언트 사이드 전체 로드 → 서버 사이드 `page`/`page_size` 페이징으로 전환
- 공통 `DataPagination` 컴포넌트 신설(중앙 정렬, 화살표, 생략된 페이지 번호), `app/ui/page.tsx`에 샘플 추가
- 사용자/그룹은 "그룹 필터", "그룹별 사용자 수", "그룹 멤버 관리" 등 전체 목록이 필요한 부가 기능이 있어 별도의 경량 무페이징 API(`/admin/users/roster`, 기존 `/admin/groups`)를 병행 유지
- 페이지 전환 시 전체 스피너로 갈아엎던 것 → 데이터 있으면 그대로 두고 교체(깜빡임 제거)
→ [[decisions/021-admin-list-server-side-pagination]]

### 4. 설정 화면 슬라이더 소수점 입력 버그
- `LabelSlider`(AI/RAG, 에이전트 온도, 쿼리비용예측기 가중치) 입력창이 매 키 입력마다 즉시 스텝 단위로 반올림해서 되쓰는 바람에, `"0.300001"`처럼 긴 소수점을 타이핑하면 한 글자만 입력해도 `0.3`으로 되돌아가 입력 자체가 막힘
- draft(로컬 임시 문자열) + blur 시점에만 반올림하는 패턴으로 수정
- 추가로 React가 "문자열은 다르지만 숫자값이 같으면" DOM을 안 갱신하는 특성 때문에 `"0.300000000000"` 입력 후 blur해도 화면에 그대로 남는 버그 발견 → blur 시 `input.value`를 직접 정리된 문자열로 덮어써서 해결
- 클릭만 하고 값 변경 없이 blur해도 dirty로 잡히던 것도 "값이 실제로 바뀌었을 때만 onChange 호출"로 수정
- 세 파일(`aisrag-tab.tsx`, `agent-tab.tsx`, `infrastructure-tab.tsx`)에 중복되어 있던 로직을 `components/settings/ui/shared.tsx`의 `LabelSlider` 하나로 통합
→ [[knowledge/troubleshooting/react-controlled-number-input-same-numeric-value-no-dom-update]]

### 5. 시스템 관리 다이얼로그 개선
- 프롬프트 수정을 별도 다이얼로그(`SystemPromptDialog`)로 분리해뒀던 것을 `SystemDialog` 안의 탭("기본 정보/제외 테이블/프롬프트")으로 통합, 별도 컴포넌트 삭제
- "사용 여부" 토글을 다이얼로그 안에도 추가, 목록의 "기본 접근" 컬럼을 정적 배지 → 즉시 토글로 변경
- DB 연결 생성 직후 "시스템을 바로 생성할까요?" 확인창 → 확인 시 시스템 관리 탭으로 전환 + 해당 연결이 미리 선택된 채 시스템 추가 다이얼로그가 열리도록 배선 (`SystemDialog`에 `initialConnectionId` prop 추가)
- 이 과정에서 죽은 코드 발견: 원래 있던 `SchemaDetector`(스키마 자동 감지 다이얼로그)가 실제로는 어디서도 트리거되지 않는 반쪽짜리 기능이었고, `SystemDialog` 자체가 이미 연결 선택 시 자동으로 스키마를 감지해서 체크박스로 보여주고 있어 완전 중복 → 컴포넌트·관련 훅 상태(`detectionId`, `detectedSchemas`, `detectSchemas`) 전부 삭제

### 6. 사용자/그룹 관리 정리
- "허용 테이블 목록" 뷰잉·입력 UI(사용자 수정 다이얼로그, 시스템 권한 탭)를 프론트에서 제거 — 백엔드 `user_table_permissions` 테이블/API는 남겨둠(실제 SQL 실행 시 강제되는 코드가 없어 관리 화면에만 있던 미완성 기능)
- 시스템 권한 매트릭스 안에 있던 "권한 상세" 다이얼로그가 매트릭스 자체의 체크 토글 기능과 완전히 중복이라 제거
- 다이얼로그 이름/문구, 컬럼 너비, 중앙 정렬 등 다듬기

### 7. 시스템 목록 API 응답 지연
- `GET /systems`, `/systems/paged`가 시스템 개수만큼 `get_system_jobs()`를 순차 호출하는 N+1 패턴 → 배치 쿼리(`get_system_jobs_batch`, `recover_stale_vectorization_jobs_batch`)로 통합
- 진짜 병목은 따로 있었음: `systems.table_relation_info` (테이블 관계 그래프 전체를 담는 JSON, 시스템당 수백 KB 이상 가능)를 `SELECT s.*`로 목록 조회마다 통째로 가져오고 있었는데, 실제 필요한 건 그 안의 작은 `metadata` 하위 객체뿐 → SQL에서 `json_build_object('metadata', ...)`로 필요한 부분만 추출하도록 컬럼 목록을 명시
→ [[issues/systems-list-api-slow-n-plus-one-and-heavy-json-column]]

### 8. 스타일/한글화 마무리
- 채팅 전송 버튼 disabled 시 `cursor-not-allowed` → 프로젝트 관례인 `pointer-events-none` + 흐린 색으로 변경 (클릭은 막히지만 hover 시 금지 마크 대신 흐리게만)
- 다크모드 인풋 대비 부족 — `--input` 명도 상향 + 반투명 대신 불투명 배경으로 변경
- 커넥션 풀 설정 라벨(풀 크기/대기시간/최대수명)에서 범위 힌트가 라벨과 한 줄에 붙어있어 폭이 좁으면 줄바꿈되던 것 → 힌트를 아래 줄로 분리
- `schema-detector.tsx`(삭제 전), `connection-list.tsx` 삭제 확인 다이얼로그, 각종 toast 메시지 등 남아있던 영어 UI 문구 전수 한글화

### 9. PR 생성
- 프론트엔드: [dna-sql-agent-web#67](https://github.com/DnA-Platform-Development-Team/dna-sql-agent-web/pull/67) — 16개 커밋
- 백엔드: [dna-sql-agent#99](https://github.com/DnA-Platform-Development-Team/dna-sql-agent/pull/99) — 4개 커밋
- 세션 도중 백엔드가 `main`이 아니라 `refactor/uiux` 브랜치에 가 있는 걸 발견하고 `main`으로 되돌리려다 사용자가 제지 — **main이 보호 브랜치라 일부러 브랜치를 쓴 것**이었음. 기존 메모(백엔드는 브랜치 없이 main에서 바로 작업)가 이제 상황과 안 맞을 수 있으니 재확인 필요

## 핵심 결정

- **결정 1:** 관리자 목록 4종을 서버사이드 페이징으로 전환하되, 그룹 필터·멤버관리처럼 전체 목록이 필요한 화면은 별도 무페이징 API로 분리
  → ADR: [[decisions/021-admin-list-server-side-pagination]]
- **결정 2:** 사용자별 테이블 단위 접근 제한(`allowed_tables`) 관리 UI를 프론트에서 제거 — 실제 쿼리 실행 시 강제되지 않는 미완성 기능이라 화면에 노출하는 게 오히려 오해 소지. 백엔드 데이터/API는 향후 재구현 대비 유지

## 배운 것

- Tailwind에서 표준 스케일에 없는 임의 숫자(`w-100`, `w-30` 등)는 CSS가 생성되지 않고 조용히 무시된다 — 대괄호 임의값(`w-[100px]`) 문법을 써야 함
- shadcn `Table` 컴포넌트는 내부적으로 `<div className="overflow-x-auto">`로 감싸는데, `overflow-x`만 지정해도 CSS 스펙상 `overflow-y`가 `auto`로 강제되어 의도치 않은 스크롤 컨테이너가 하나 더 생긴다 — `sticky` 헤더가 엉뚱한 컨테이너 기준으로 붙는 원인이 됨
- Postgres 배치 조회 패턴: `WHERE (col1, col2) IN (...)` 여러 값 대신 `unnest($1::text[]), unnest($2::text[])`로 페어를 만들어 JOIN하면 N+1을 단일 쿼리로 배치화할 수 있다 (`get_system_jobs_batch`)
- 화면에서 무거워 보이는 API 응답의 원인은 항상 쿼리 개수(N+1)만이 아니라, `SELECT *`가 끌고 오는 컬럼 자체(큰 JSON/TEXT 컬럼)일 수도 있다 — 이번엔 후자가 진짜 원인이었음

## 문제 & 해결

- **문제:** 새 대화 생성 후 첫 메시지를 보내도 대화 제목이 "새 대화"로 고정
  → **원인:** 제목 저장 로직이 두 차례 걸쳐 "제목 없음 센티널"을 빈 문자열(`''`)에서 `"새 대화"`(non-empty)로 바꿔버려 자동 갱신 조건이 항상 거짓이 됨
  → **해결:** 센티널을 다시 빈 문자열로 복원, 화면 표시는 프론트의 `title || '새 대화'` fallback으로 분리
  → 이슈: [[issues/conversation-title-empty-string-sentinel-broken-by-default]]

- **문제:** 시스템 관리 목록 조회(`/systems/paged`)가 체감상 느림
  → **원인:** N+1 쿼리(작지만 다수) + 목록에 불필요한 대용량 JSON 컬럼 전체 조회(결정적 원인)
  → **해결:** 배치 쿼리 + 필요한 JSON 하위 객체만 SQL에서 추출
  → 이슈: [[issues/systems-list-api-slow-n-plus-one-and-heavy-json-column]]

- **문제:** 설정 화면 슬라이더 옆 숫자 입력창에 `"0.300000000000"`처럼 소수점 긴 값을 넣고 blur해도 화면이 안 바뀜
  → **원인:** React가 controlled input의 `value` prop을 문자열 동일성이 아니라 "이전 렌더와 값이 같은가"로 비교하는데, 숫자값(0.3)이 같으면 DOM의 실제 text content(`"0.300000000000"`)는 갱신하지 않음
  → **해결:** blur 핸들러에서 `input.value`를 직접 정리된 문자열로 덮어씀
  → [[knowledge/troubleshooting/react-controlled-number-input-same-numeric-value-no-dom-update]]

## 다음 할 일

- [ ] 백엔드 브랜치 작업 규칙(`main` 직접 작업 vs 보호 브랜치라 `refactor/uiux` 사용) 재확인 후 메모 갱신
- [ ] PR #67(프론트), #99(백엔드) 리뷰·머지
- [ ] `user_table_permissions` 테이블 단위 권한 기능을 재구현할지, 완전히 걷어낼지 결정 필요 (현재는 백엔드 API만 남아있고 프론트 UI 없음)

## 효과적이었던 프롬프트

```
지금도 그냥 나오는데
```
→ (슬라이더 버그 재현 화면을 계속 스크린샷/확대로 검증하며 실제로 고쳐졌는지 끝까지 확인시킨 케이스. "고쳤다"는 보고를 곧이곧대로 안 받아들이고 재현시켜서 두 번째, 세 번째 근본 원인까지 찾아내게 만든 프롬프트)

```
그 테이블에 값을 넣는 곳이 있어?
```
→ 기능을 제거하기 전에 "이게 실제로 쓰이는 기능인가"를 먼저 확인시킨 질문 — 덕분에 UI만 제거하고 백엔드는 남겨두는 안전한 결정으로 이어짐
