---
type: knowledge
category: troubleshooting
tags: [javascript, json, nan, serialization]
related: ["projects/dna-sql-agent-web/issues/expires-in-null-bug"]
---

# JavaScript: NaN이 JSON.stringify 시 null로 직렬화

## 증상

숫자 계산 결과가 `NaN`인데 `localStorage`나 API 응답에서 `null`로 저장/전달됨.

## 원인

JSON 명세상 `NaN`은 유효한 값이 아니므로 `JSON.stringify`가 `null`로 변환한다.

```js
JSON.stringify({ value: NaN })   // '{"value":null}'
JSON.stringify({ value: undefined * 1000 })  // '{"value":null}'
```

파싱 시에도 `null`로 복원되어 원래 `NaN`이었다는 정보가 사라진다.

## 흔한 발생 패턴

```ts
// 서버 응답에 필드가 없을 때
const expiresAt = Date.now() + serverResponse.expires_in * 1000
// → expires_in이 undefined면 NaN → localStorage에 null로 저장
```

## 해결책

계산 전 fallback 처리:

```ts
const expiresAt = Date.now() + (serverResponse.expires_in ?? 1800) * 1000
```

또는 저장 전 유효성 검사:

```ts
if (!Number.isFinite(expiresAt)) throw new Error('Invalid expiresAt')
```

## 주의

`Date.now() >= null` → `Date.now() >= 0` → 항상 `true`가 되어
"항상 만료" 상태로 인식될 수 있음. 인증 토큰 만료 시각 계산에서 특히 위험.
