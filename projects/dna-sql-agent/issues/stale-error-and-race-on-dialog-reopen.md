---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-25
resolved: true
root-cause: "다이얼로그 재오픈 시 오류/테이블 상태를 초기화하지 않고, 이전 요청의 느린 실패 응답이 새 상태를 덮어씀"
related: []
tags: [react, dialog, race-condition, stale-state]
---

# 다이얼로그 재오픈 시 이전 시스템의 오류가 잔류하고 응답이 뒤섞임

## 증상

sqlite 처럼 테이블 목록을 불러오지 못하는 시스템의 다이얼로그를 연 뒤 닫고,
정상 동작하는 다른 시스템의 다이얼로그를 열면 **이전 시스템의 오류 메시지가 그대로
남아 있다**. 또 이전 요청의 실패 응답이 늦게 도착하면 새로 연 시스템의 정상 상태를
덮어쓴다.

## 환경

- `dna-sql-agent-web` — 테이블 접근 제어 설정 다이얼로그
- 시스템별 테이블 목록 비동기 조회

## 근본 원인

두 가지가 겹쳤다.

1. **재오픈 시 상태 미초기화** — 다이얼로그 컴포넌트가 언마운트되지 않아 오류·테이블
   목록 state 가 이전 값을 유지한 채 다시 열린다.
2. **응답 race** — 실패가 느리게 돌아오는 시스템(sqlite)의 요청이 아직 진행 중인데
   다이얼로그를 닫고 다른 시스템을 열면, 뒤늦게 도착한 이전 응답이 새 시스템의
   state 에 그대로 반영된다. 어느 요청의 응답인지 구분하는 수단이 없었다.

## 해결 방법

- 다이얼로그 오픈 시점에 테이블 목록·오류 상태를 명시적으로 초기화
- **요청 토큰(`reqRef`)** 을 두어, 응답 처리 직전에 현재 토큰과 비교해 일치하지 않으면
  stale 응답으로 보고 버린다

```ts
const reqRef = useRef(0);
const token = ++reqRef.current;
const res = await fetchTables(systemName);
if (reqRef.current !== token) return; // stale — 무시
setTables(res);
```

## 예방책

- 재사용되는 다이얼로그·탭은 **열릴 때 상태를 초기화**할 것. 언마운트를 전제하지 말 것
- 대상이 바뀔 수 있는 비동기 조회는 요청 토큰으로 stale 응답을 걸러낼 것.
  "실패가 느린 경로"가 있으면 race 는 반드시 드러난다

## 관련 페이지

- [[knowledge/patterns/request-token-stale-response-guard]]
- [[projects/dna-sql-agent/sessions/2026-06-25-system-exclude-tables-table-access-control]]
- [[issues/settings-reset-not-restoring-saved]]
