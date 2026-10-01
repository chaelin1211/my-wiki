---
type: decision-record
project: dna-sql-agent-web
date: 2026-07-24
status: accepted
superseded-by: ""
tags: [performance, sql, prism, sql-formatter, react]
---

# ADR-016: SQL 카드 하이라이팅 — Prism + sql-formatter 이중 파싱 구조 유지

## 맥락

`components/sql-block.tsx`의 SQL 카드가 스트리밍 중 부모가 리렌더될 때마다 SQL이 안 바뀌었는데도
매번 `formatSQL()`(sql-formatter) + `Prism.highlight()`를 재실행하고 `dangerouslySetInnerHTML`로
DOM을 통째로 교체하던 문제를 고치는 과정에서, "Prism 없이 이 정도 성능을 낼 수 없나",
"sql-formatter가 이미 파싱하는데 그 결과를 색칠에 재사용할 수 없나"라는 더 근본적인 질문이 나옴.

현재 구조는 같은 SQL 문자열을 두 라이브러리가 각각 다시 파싱하는 형태:

```
sql (원본) → sql-formatter.format() [1차 파싱, 들여쓰기 결정, 문자열만 반환]
           → Prism.tokenize()        [2차 파싱, 색칠용 토큰 타입 획득]
           → renderToken()            [React 엘리먼트로 변환]
```

## 선택지

### 옵션 A: 현행 유지 (sql-formatter + Prism, 파싱 2회, 둘 다 useMemo 캐싱)
- **장점:** 둘 다 공식 공개 API만 사용, 관리자 화면과 동일한 조합이라 일관성 있음, 검증된 SQL 문법(방언별 키워드/이스케이프 등)을 재사용
- **단점:** 개념적으로 같은 문자열을 두 번 파싱 (구조적 비효율)
- **비용/노력:** 0 (변경 없음)

### 옵션 B: sql-formatter 제거, Prism 토큰만으로 직접 줄바꿈/들여쓰기 규칙 작성
- **장점:** 파싱 1회로 감소, 외부 라이브러리 의존 축소
- **단점:** sql-formatter가 제공하는 방언별 규칙·중첩 서브쿼리 들여쓰기·콤마 정렬 등 정교함을 포기해야 함. 복잡한 SQL(CASE WHEN, 서브쿼리)에서 포맷팅 품질 저하 가능
- **비용/노력:** 중간 — 직접 포매터 구현 및 엣지케이스 검증 필요

### 옵션 C: sql-formatter 내부 토크나이저(`lexer/Tokenizer`)를 딥임포트해 색칠에 재사용
- **장점:** 이론적으로 파싱 1회로 합칠 수 있고, sql-formatter의 정교한 TokenType(RESERVED_CLAUSE, RESERVED_JOIN 등)이 Prism보다 SQL 특화도가 높음
- **단점:** `lexer/Tokenizer`는 `sql-formatter` 패키지의 공개 API(`export`)가 아닌 내부 구현 — semver 보장 밖이라 버전업 시 조용히 깨질 수 있음. 방언별 `tokenizerOptions` 조립도 직접 해야 해서 코드 복잡도 증가. 실제로 딥임포트 경로(`sql-formatter/dist/{cjs,esm}/lexer/Tokenizer.js`)와 필요한 설정(`languages/sql/sql.formatter.js`의 `tokenizerOptions`)을 확인해 기술적으로는 가능함을 검증함
- **비용/노력:** 낮음(구현 자체는 간단) 이지만 유지보수 리스크가 큼

### 옵션 D: CodeMirror(관리자 쪽에 이미 도입된 `@uiw/react-codemirror` + `@codemirror/lang-sql`)로 교체, 읽기 전용 모드
- **장점:** admin과 동일 스택, 접기/줄번호 등 에디터급 기능 여지
- **단점:** 관리자도 실제로는 **입력용 에디터**에만 CodeMirror를 쓰고, 읽기 전용 미리보기(`sql-examples-table.tsx` 등)는 채팅과 동일하게 sql-formatter+Prism을 쓰고 있음 → 용도가 다름(편집 vs 표시). 번들 크기 증가, 커서/스크롤 등 불필요한 편집기 UX 포함
- **비용/노력:** 중간

## 결정

**옵션 A(현행 유지)를 선택한다.** 재렌더 시 재계산 문제는 `useMemo`로 이미 해결했고([[sessions/2026-07-24-sql-block-render-perf-and-conversation-loading]]),
남은 "파싱 2회"라는 구조적 비효율은 캐싱 덕분에 SQL 문자열이 바뀔 때만 발생해 실사용에서 체감되지 않는다.

## 근거

- Node.js + jsdom 벤치마크로 확인한 84% 성능 개선(4729ms → 748ms)의 대부분은 `dangerouslySetInnerHTML` 제거가 아니라 **메모이제이션 부재 해소**에서 나왔다. 즉 "파싱 2회"는 이미 병목이 아니었음이 측정으로 확인됨.
- 옵션 B/C 모두 얻는 이득(파싱 1회) 대비 리스크(포맷팅 품질 저하 또는 비공식 내부 API 의존)가 크다.
- 옵션 D는애초에 admin 쪽 선례가 "입력=CodeMirror, 표시=Prism"으로 용도를 구분하고 있어, 채팅의 읽기 전용 카드에 억지로 가져올 이유가 없다.
- 안정성(공식 API만 사용) > 이론적 성능(파싱 1회)로 우선순위를 정함.

## 결과

- `components/sql-block.tsx`는 `sql-formatter` + `Prism` + `useMemo` 조합을 그대로 유지, 대신 `Prism.highlight()`(HTML 문자열 생성) → `Prism.tokenize()` + React 토큰 렌더링으로만 교체 ([[sessions/2026-07-24-sql-block-render-perf-and-conversation-loading]])
- 향후 SQL이 지금보다 훨씬 커지거나(예: 수십 KB) 카드가 대량으로 동시 렌더되는 요구가 생기면, 이 ADR의 옵션 B/C를 재검토할 것
- `sql-example-dialog.tsx` 등 관리자 미리보기도 동일 구조라 별도 대응 불필요

## 참고 자료

- 벤치마크 스크립트: `dna-sql-agent-web/scripts/bench-sql-block.js`
- 관련 커밋: `perf/sql-block-render` 브랜치 `aad250a`
- 관리자 CodeMirror 도입: [[decisions/010-codemirror-sql-editor]]
