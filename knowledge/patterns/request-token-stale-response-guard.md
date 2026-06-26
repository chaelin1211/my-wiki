---
type: pattern
title: "요청 토큰으로 stale 비동기 응답 무시 (다이얼로그/탭 전환 race 방지)"
tags: [react, async, race-condition, dialog, fetch]
date: 2026-06-25
---

# 요청 토큰(reqRef)으로 stale 비동기 응답 무시

## 문제

같은 컴포넌트에서 선택값(시스템/연결/탭)이 바뀔 때마다 비동기 로드를 트리거하면,
**느린 이전 요청이 새 요청보다 늦게 도착해 새 화면 상태를 덮어쓴다.**

특히:
- 연결 안 되는 대상(sqlite 등)을 골랐다가 다른 대상으로 바꿨을 때, 이전 **실패 응답**이 늦게 와서 새 화면에 오류가 잔류
- 다이얼로그를 닫았다 다시 열어도 이전 상태가 남음

## 해결: 단조 증가 요청 토큰

`useRef` 카운터를 두고, 요청 시작 시 증가시켜 캡처한다. 응답 처리 직전 현재 토큰과
비교해 **자신이 최신 요청이 아니면 결과를 버린다.**

```ts
const reqRef = useRef(0)
const load = useCallback(async () => {
  const reqId = ++reqRef.current        // 이 요청의 토큰
  setLoading(true); setError(null)
  try {
    const res = await fetchSomething(args)
    if (reqId !== reqRef.current) return // 더 최신 요청 있으면 무시
    setData(res)
  } catch (e) {
    if (reqId !== reqRef.current) return
    setError(message(e))
  } finally {
    if (reqId === reqRef.current) setLoading(false)
  }
}, [args])
```

함께 쓸 것:
- **재오픈/전환 시 상태 초기화** — `useEffect(() => { setData([]); setError(null); ... }, [open])` 또는 `[key]`
- 토큰은 `useState`가 아니라 **`useRef`** (리렌더 없이 즉시 반영, 클로저로 캡처).

## 적용 예 (dna-sql-agent-web)

- `system-dialog.tsx`: 스키마 감지/테이블 목록 로드에 `schemaReqRef`/`loadReqRef`
- `table-transfer-select.tsx`: 시스템 변경 시 테이블 목록 재조회

## 대안

- `AbortController`로 이전 요청을 실제 취소 — fetch가 abort 지원하면 더 깔끔(네트워크 절약).
  단, 이미 시작된 비-fetch 작업이나 라이브러리 호출엔 토큰 방식이 범용적.

## 관련 페이지

- [[knowledge/patterns/async-state-watch-with-useEffect]]
- 세션: [[projects/dna-sql-agent/sessions/2026-06-25-system-exclude-tables-table-access-control]]
