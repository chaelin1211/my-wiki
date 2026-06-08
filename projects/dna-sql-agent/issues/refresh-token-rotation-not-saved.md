---
type: troubleshooting
project: dna-sql-agent
date: 2026-05-27
resolved: true
root-cause: "Refresh token rotation 시 새 refresh_token을 저장하지 않아 다음 갱신 시 무효 토큰 사용"
related: [auth, jwt, refresh-token]
tags: [auth, refresh-token, rotation, frontend]
---

# Refresh Token Rotation — 새 토큰 미저장 버그

## 증상

- 첫 번째 auto refresh(401 → /auth/refresh → 재시도) 성공
- 이후 다음 API 호출 시 바로 로그인 페이지로 이동

## 환경

- 백엔드: refresh token rotation 방식 (매 refresh마다 새 토큰 쌍 발급)
- 프론트엔드: 401 인터셉터 + 큐 패턴

## 시도한 것들

1. ❌ `/auth/refresh` 성공 후 `access_token`만 저장 → 다음 401에서 이전(무효) refresh_token 재사용 → 실패 → 로그인
2. ✅ `access_token` + `refresh_token` 둘 다 교체 저장 → 2회 연속 refresh 정상 동작

## 근본 원인

Rotation 방식에서는 refresh 할 때마다 refresh_token도 새로 발급된다.
이전 refresh_token은 즉시 무효가 되므로, 응답의 `refresh_token`도 반드시 업데이트해야 한다.

## 해결 방법

```js
const tokens = await refreshTokenApi(storedRefreshToken);
saveAccessToken(tokens.access_token);
saveRefreshToken(tokens.refresh_token);  // 반드시 교체
```

## 검증 방법

`JWT_EXPIRE_MINUTES=1`로 설정 후 **2회 연속 auto refresh** 성공 여부로 확인.
1회만 성공하면 rotation 저장 누락 가능성 높음.

## 예방책

refresh 응답 처리 코드 리뷰 시 항상 양쪽 토큰 저장 여부 확인.
