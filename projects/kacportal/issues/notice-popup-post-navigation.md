---
type: troubleshooting
project: kacportal
date: 2026-04-14
resolved: true
root-cause: "팝업 창에서 form POST 방식으로 페이지 이동 시도 — 팝업 환경에서 미지원"
related: [sessions/2026-04-20-law-search-encoding-notice-popup]
tags: [jsp, popup, navigation, http-method]
---

# 공지사항 팝업 — 페이지 이동 안 되는 문제

## 증상

```
공지사항 팝업에서 링크 클릭 시 페이지 이동이 되지 않음
(화면 변화 없음, 오류 없이 무반응)
```

## 환경

- **관련 파일:** `src/main/webapp/WEB-INF/jsp/main/main.jsp`
- **재현 조건:** 공지사항 팝업 내 링크 클릭

## 시도한 것들

1. ❌ `form.submit()` POST 방식 — 팝업 컨텍스트에서 동작 안 함
2. ✅ `location.href` GET 방식으로 변경

## 근본 원인

팝업 창에서 `<form method="POST">` submit으로 페이지 이동을 시도했으나, 팝업 환경(또는 해당 엔드포인트)에서 POST 방식이 지원되지 않아 무반응 처리됨.

## 해결 방법

```javascript
// 변경 전
document.querySelector('form').submit(); // POST

// 변경 후
location.href = url; // GET
```

추가로 내부/외부 링크 분기 처리:
```javascript
if (url.startsWith("http")) {
    window.open(url, '_blank'); // 외부 → 새탭
} else {
    location.href = url;        // 내부 → 현재창
}
```

## 예방책

팝업에서의 페이지 이동은 기본적으로 GET(`location.href`) 사용. POST가 꼭 필요하면 hidden form을 동적 생성 후 body에 append하여 submit.

## 관련 페이지

- (없음)
