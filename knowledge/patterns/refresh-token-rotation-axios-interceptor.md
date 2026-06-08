---
type: pattern
tags: [auth, jwt, refresh-token, axios, interceptor, frontend]
---

# Refresh Token Rotation — axios 401 인터셉터 패턴

## 핵심 규칙

Rotation 방식(refresh마다 새 토큰 쌍 발급)에서는 **access_token + refresh_token 둘 다** 교체 저장해야 한다.
refresh_token만 빠뜨리면 다음 401에서 무효 토큰으로 재시도 → 실패 → 강제 로그아웃.

## 구현

```js
let isRefreshing = false;
let queue = [];

axiosInstance.interceptors.response.use(
  res => res,
  async err => {
    const originalRequest = err.config;
    if (err.response?.status !== 401 || originalRequest._retry) {
      return Promise.reject(err);
    }

    if (isRefreshing) {
      return new Promise((resolve, reject) => {
        queue.push({ resolve, reject });
      }).then(token => {
        originalRequest.headers['Authorization'] = `Bearer ${token}`;
        return axiosInstance(originalRequest);
      });
    }

    originalRequest._retry = true;
    isRefreshing = true;

    try {
      const { access_token, refresh_token } = await refreshTokenApi(getRefreshToken());

      // ✅ 둘 다 저장
      saveAccessToken(access_token);
      saveRefreshToken(refresh_token);

      queue.forEach(({ resolve }) => resolve(access_token));
      queue = [];

      originalRequest.headers['Authorization'] = `Bearer ${access_token}`;
      return axiosInstance(originalRequest);
    } catch (e) {
      // ✅ 큐에 쌓인 요청도 reject
      queue.forEach(({ reject }) => reject(e));
      queue = [];
      logout();
      return Promise.reject(e);
    } finally {
      isRefreshing = false;
    }
  }
);
```

## 주의사항

- `refreshTokenApi()` · `logoutApi()` 자체는 이 인터셉터가 붙은 axiosInstance가 아닌 일반 fetch/axios로 호출해야 무한루프 방지
- 큐의 catch 절에서 반드시 reject 처리 — 누락 시 대기 중인 요청이 영원히 pending

## 검증법

`JWT_EXPIRE_MINUTES=1` 임시 설정 후 **2회 연속 auto refresh** 통과 여부 확인.
