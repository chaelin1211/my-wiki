---
type: session-log
project: kacportal
date: 2026-04-20
duration: ~반나절
focus: "법령정보 URL 더블 인코딩 픽스, 공지사항 팝업 내비게이션 수정"
tools-used: [claude-code]
outcome: success
---

# 2026-04-20 — 법령정보 링크 오류 & 공지사항 팝업 수정

## 목표

- 법령정보 파일 다운로드/링크 시 URL이 깨지는 문제 해결
- 공지사항 팝업에서 페이지 이동 시 동작 오류 수정

## 수행한 작업

1. **공지사항 팝업 — POST → GET 방식 변경** (`main.jsp`)
   - 팝업에서 페이지 이동 시 POST 미지원으로 GET 방식으로 전환
   - 커밋: `69588f87c`

2. **공지사항 팝업 — 내부/외부 링크 분기 처리** (`main.jsp`)
   - `http`로 시작하는 URL → 외부 링크(새탭 `_blank`)
   - 그 외 → 내부 링크(현재창 이동)
   - 커밋: `69d139370`

3. **법령정보 더블 인코딩 수정** (`LawSrchController.java`)
   - URL이 이미 `http`로 시작하는 경우(절대 URL) → `lawUrl` prefix를 붙이지 않고 쿼리 파라미터도 재인코딩하지 않도록 분기
   - 상대 URL인 경우에만 `lawUrl` + `/` + `fileUrl` + `?` + 인코딩된 쿼리 조합
   - HTTP 301/302 리다이렉트 응답 처리 추가 (프록시 설정 포함)
   - 커밋: `33ba9fc1e`

4. **법령정보 뷰 링크 보완** (`viewLawInfo.jsp`)
   - 커밋: `a37a75fa2`

## 핵심 결정

- **절대/상대 URL 판별 기준:** `fileUrl.startsWith("http")` 로 단순 판별
  - 외부 법령 API가 상황에 따라 절대 URL / 상대 URL 혼용으로 반환하는 것이 근본 원인
- **공지사항 외부 링크 판별:** `http`로 시작하면 임시로 외부 URL로 간주 (추후 DB 컬럼으로 명시적 구분 검토)

## 배운 것

- Spring MVC `@RequestMapping` 컨트롤러에서 외부 API URL을 조합할 때, 응답값이 이미 절대 URL인지 먼저 확인하지 않으면 더블 프리픽스/더블 인코딩이 발생함
- JSP `form.submit()` → `location.href` GET 방식 변경 시 쿼리 파라미터 처리 주의 필요
- `HttpURLConnection`으로 외부 HTTP 요청 시 301/302 리다이렉트를 자동 처리하지 않는 경우가 있어 수동으로 `Location` 헤더를 따라야 함

## 문제 & 해결

- **문제:** 법령정보 첨부파일 다운로드 URL이 `https://law.go.kr/https://law.go.kr/...` 형태로 더블 프리픽스 발생
- **원인:** 외부 법령 API가 절대 URL / 상대 URL을 혼용 반환하는데 컨트롤러가 무조건 `lawUrl` prefix를 붙임
- **해결:** `fileUrl.startsWith("http")` 분기로 절대 URL은 그대로 사용
  → 이슈: [[issues/law-url-double-prefix]]

- **문제:** 공지사항 팝업에서 링크 클릭 시 페이지 이동 안 됨
- **원인:** POST 방식 사용 중인데 팝업에서는 미지원
- **해결:** GET 방식 `location.href`로 변경
  → 이슈: [[issues/notice-popup-post-navigation]]

## 다음 할 일

- [ ] 공지사항 외부 링크 판별을 DB 컬럼으로 명시적으로 구분하도록 개선 검토
- [ ] 미커밋 설정 파일 검토 (`globals-dev.properties`, `context-properties.xml`, `log4j2.xml`)
- [ ] 법령정보 URL 처리 로직 추가 엣지케이스 테스트 (프로토콜 없는 `//` 상대 URL 등)
