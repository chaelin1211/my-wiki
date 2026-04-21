---
type: knowledge
category: troubleshooting
tags: [spring, java, url-encoding, external-api]
created: 2026-04-20
---

# Spring — 외부 API URL 더블 인코딩 / 더블 프리픽스 방지

## 문제 패턴

외부 API 응답의 URL 필드를 그대로 base URL에 붙여 조합할 때, API가 절대 URL / 상대 URL을 혼용 반환하면 다음과 같은 오류가 발생한다:

```
// API가 절대 URL 반환: "https://external.com/path"
String result = baseUrl + apiResponse.getUrl();
// → "https://external.com/https://external.com/path" (더블 프리픽스)
```

URLEncoder를 무조건 적용하는 경우도 마찬가지:
```
// URL이 이미 인코딩된 경우 재인코딩하면 %25xx 형태로 깨짐
URLEncoder.encode(alreadyEncodedUrl, "UTF-8");
```

## 해결책

### 1. startsWith("http") 단순 판별

```java
String fileUrl = apiResponse.getUrl();
if (!fileUrl.startsWith("http")) {
    // 상대 URL → base URL 붙이고 파라미터 인코딩
    fileUrl = baseUrl + "/" + fileUrl + buildEncodedQuery(params);
}
// 절대 URL → 그대로 사용
```

### 2. URI.resolve() 를 이용한 정규화 (권장)

```java
URI base = URI.create(baseUrl + "/");
URI resolved = base.resolve(apiResponse.getUrl());
// 절대 URL이면 그대로, 상대 URL이면 base 기준으로 조합
String finalUrl = resolved.toString();
```

### 3. HttpURLConnection 리다이렉트 수동 처리

`setFollowRedirects(false)` 기본값이거나 프록시 사용 시 자동 리다이렉트가 동작 안 할 수 있음:

```java
int responseCode = conn.getResponseCode();
if (responseCode == HttpURLConnection.HTTP_MOVED_PERM
    || responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {
    String newUrl = conn.getHeaderField("Location");
    conn.disconnect();
    conn = (HttpURLConnection) new URL(newUrl).openConnection();
}
```

## 예방책

외부 API 연동 명세서에서 URL 필드가 절대/상대 혼용 여부를 명시적으로 확인하거나, 수신 즉시 `URI.resolve()`로 정규화하는 유틸 레이어를 둔다.

## 관련 이슈

- [[projects/kacportal/issues/law-url-double-prefix]]
