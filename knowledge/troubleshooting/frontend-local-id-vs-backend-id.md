---
type: knowledge
category: troubleshooting
date: 2026-06-09
tags: [react, api, id-mismatch, 404]
---

# 프론트엔드 로컬 ID vs 백엔드 ID 불일치로 인한 API 404

## 문제 패턴

프론트엔드에서 리소스를 낙관적으로 생성할 때 로컬 ID(`generateId()`, `uuid()` 등)를 할당하고, 백엔드 API 응답으로 실제 ID(`backendId`)를 받아 별도 필드에 저장하는 패턴에서 발생.

API 호출 시 로컬 ID를 그대로 전달하면 백엔드가 인식하지 못해 404 반환.

## 언제 발생하는가

- 신규 생성 직후(새로고침 전)에 편집·삭제·핀 등 API 조작을 시도할 때
- 백엔드에서 목록을 다시 불러오면 로컬 ID가 백엔드 ID로 덮어써지므로, **새로고침 후에는 우연히 정상 동작**하여 재현이 어려움

## 해결 패턴

API 호출 전 반드시 `backendId`를 명시적으로 조회하고, 없으면 API 스킵.

```ts
const backendId = resourcesRef.current.find(r => r.id === localId)?.backendId
if (!backendId) return   // 아직 백엔드에 저장 안 된 리소스 — 로컬만 업데이트
await apiCall(backendId, ...)
```

**주의:** 낙관적 로컬 업데이트(`setState`) 전에 `backendId`를 읽을 것.
삭제처럼 setState가 해당 리소스를 목록에서 제거하는 경우, setState 후에는 ref에서도 찾을 수 없을 수 있음.

```ts
// 올바른 순서
const backendId = ref.current.find(r => r.id === id)?.backendId  // ← 먼저 읽기
setState(prev => prev.filter(r => r.id !== id))                   // ← 그 다음 상태 변경
if (!backendId) return
await deleteApi(backendId)
```

## 예방책

- 로컬 ID와 백엔드 ID를 명확히 구분하는 타입 설계 (`localId` vs `backendId` 등 네이밍)
- API 호출 헬퍼에 백엔드 ID 조회를 캡슐화
- 새로 생성된 리소스의 API 연동을 통합 테스트로 커버

## 실제 사례

- [[projects/dna-sql-agent-web/issues/new-conversation-local-id-api-404]]
