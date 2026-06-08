---
type: index
updated: 2026-06-08
---

# my-wiki — Index

이 위키의 전체 페이지 카탈로그. LLM이 질의 시 이 파일을 먼저 읽고 관련 페이지를 찾는다.

## 프로젝트

| 프로젝트 | 상태 | 스택 | 마지막 갱신 |
|---------|------|------|-----------|
| [[projects/kacportal/overview\|kacportal]] | active | java, spring, egovframe, oracle, tomcat | 2026-04-21 |
| [[projects/kac-idp-noti/overview\|kac-idp-noti]] | active | java, spring, kafka, hibernate, tibero, altibase, mysql, docker | 2026-04-21 |
| [[projects/dna-sql-agent/overview\|dna-sql-agent]] | active | python, fastapi, vanna, vllm, ollama, oracle, postgres, qdrant, docker | 2026-04-21 |
| [[projects/dna-sql-agent-web/overview\|dna-sql-agent-web]] | active | nextjs, typescript, tailwindcss, shadcn-ui, plotly, docker | 2026-04-21 |

## Knowledge Base

### 도구 & 기술
- [[knowledge/tools/echarts-tooltip-json-patterns|ECharts Tooltip — JSON 환경 포맷터 패턴 ({b}, pre-line, visualMap)]]

### 패턴
- [[knowledge/patterns/sse-post-completion-patch|SSE 완료 후 최소 패치 패턴 — 스트리밍 state 보존]]
- [[knowledge/patterns/postgres-lateral-latest-row-per-group|PostgreSQL LATERAL JOIN — 그룹별 최신 1건 조회]]
- [[knowledge/patterns/optimistic-update-table-toggle|테이블 토글 셀 옵티미스틱 업데이트 — Set 기반 롤백 패턴]]
- [[knowledge/patterns/refresh-token-rotation-axios-interceptor|Refresh Token Rotation — axios 401 인터셉터 + 큐 패턴]]
- [[knowledge/patterns/401-interceptor-queue-pattern|401 인터셉터 큐 패턴 — native fetch refresh token 자동 갱신]]
- [[knowledge/patterns/async-state-watch-with-useEffect|비동기 state 감지 — pendingKey + useEffect 패턴]]

### 트러블슈팅
- [[knowledge/troubleshooting/overflow-y-auto-focus-ring-clip|overflow-y-auto — 자식 input focus ring 좌측 클리핑 (pl-[3px] 해결)]]
- [[knowledge/troubleshooting/spring-url-double-encoding|Spring — 외부 API URL 더블 인코딩/프리픽스 방지]]
- [[knowledge/troubleshooting/message-rendering-heuristic-pitfall|메시지 렌더링 휴리스틱의 함정 — 단순 텍스트 드랍 안티패턴]]
- [[knowledge/troubleshooting/sticky-column-offset-mismatch|HTML Table sticky 컬럼 두 번째 열 left 오프셋 틀어짐 — w+min-w+max-w 고정]]
- [[projects/dna-sql-agent/issues/sse-middleware-str-bytes-type-error|Starlette SSE 미들웨어 — str yield 시 TypeError (bytes 인코딩 필수)]]
- [[projects/dna-sql-agent-web/issues/bookmark-soft-remove-rebookmark|React useMemo ref 의존성 함정 — soft remove + in-place rebookmark]]
- [[projects/dna-sql-agent/issues/echarts-heatmap-duplicate-cell|ECharts heatmap — 같은 셀 중복 매핑 시 합산 집계 필요]]
- [[projects/dna-sql-agent/issues/echarts-sankey-dag-cycle|ECharts Sankey DAG 사이클 오류 — iterative DFS back-edge 제거]]
- [[knowledge/troubleshooting/auth-headers-must-not-delete-localstorage|인증 헬퍼 함수에서 localStorage 삭제하면 refresh token까지 소멸]]
- [[knowledge/troubleshooting/json-nan-serialization|JavaScript: NaN이 JSON.stringify 시 null로 직렬화 — 인증 토큰 만료 계산 주의]]

### 패턴
- [[projects/dna-sql-agent-web/decisions/013-chart-palette-shared-constant|차트 공통 컬러 팔렛트 — 정적 상수 파일로 다중 엔진 통일 관리]]
- [[projects/dna-sql-agent-web/decisions/002-toast-pattern-jsx-icon|Toast JSX 아이콘 패턴 (shadcn)]]
- [[projects/dna-sql-agent-web/decisions/004-sse-done-event-message-id|SSE done 이벤트에서 필요 ID 직접 수신 (타이밍 레이스 제거)]]
- [[projects/dna-sql-agent-web/decisions/006-optimistic-update-permission-matrix|권한 매트릭스 셀 토글 옵티미스틱 업데이트]]

### 프롬프팅
- [[knowledge/prompting/effective-instructions|Claude Code 효과적 지시법]]

## 소스
- _(소스 추가 시 갱신)_
