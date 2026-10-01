---
type: troubleshooting
project: kacportal
date: 2026-04-15
resolved: true
root-cause: "외부 법령 API가 절대 URL / 상대 URL 혼용 반환 — 컨트롤러가 조건 없이 lawUrl prefix 붙힘"
related: [sessions/2026-04-20-law-search-encoding-notice-popup]
tags: [url-encoding, spring-mvc, external-api]
---

# 법령정보 다운로드 URL 더블 프리픽스 & 더블 인코딩 오류

## 증상

```
법령정보 첨부파일 다운로드 URL이
https://law.go.kr/https://law.go.kr/DRF/fileDownload.do?...
형태로 생성되어 404 발생
```

## 환경

- **런타임:** Java 1.8, Spring 5.3.27, Tomcat 8
- **관련 파일:** `LawSrchController.java` — `downloadLawFile()` 메서드
- **재현 조건:** 외부 법령 API가 절대 URL(`https://...`)을 `attFileDownloadUrl`에 반환할 때

## 시도한 것들

1. ❌ URL 전체를 `URLDecoder.decode` 후 재조합 — 이미 인코딩된 파라미터가 깨짐
2. ✅ `fileUrl.startsWith("http")` 분기 — 절대 URL이면 prefix/인코딩 생략, 상대 URL만 처리

## 근본 원인

외부 법령 API(law.go.kr)가 상황에 따라 응답 필드 `attFileDownloadUrl`에:
- **절대 URL** (`https://law.go.kr/DRF/...`) 반환 → prefix 붙이면 더블
- **상대 경로** (`/DRF/...`) 반환 → prefix 필요

컨트롤러가 이를 구분하지 않고 항상 `lawUrl + fileUrl`로 조합.

## 해결 방법

```java
if ("URL".equals(fileType)) {
    if (!fileUrl.startsWith("http")) {
        // 상대 URL: prefix + 파라미터 인코딩 조합
        StringBuilder query = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            query.append(URLEncoder.encode(entry.getKey(), "UTF-8"))
                 .append("=")
                 .append(URLEncoder.encode(entry.getValue(), "UTF-8"))
                 .append("&");
        }
        fileUrl = lawUrl + "/" + fileUrl + "?" + query.toString();
    }
    // 절대 URL: fileUrl 그대로 사용
}
```

HTTP 301/302 리다이렉트도 수동 처리 추가:
```java
if (responseCode == HttpURLConnection.HTTP_MOVED_PERM
    || responseCode == HttpURLConnection.HTTP_MOVED_TEMP) {
    String newUrl = conn.getHeaderField("Location");
    conn = (HttpURLConnection) new URL(newUrl).openConnection();
}
```

## 예방책

외부 API 연동 시 응답 URL 필드가 절대/상대 혼용인지 문서로 확인하거나, 수신 즉시 정규화(`URI.create(base).resolve(received)`)하는 유틸 메서드 사용 검토.

## 관련 페이지

- [[knowledge/troubleshooting/spring-url-double-encoding]]
