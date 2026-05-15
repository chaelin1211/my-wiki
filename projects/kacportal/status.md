---
type: project-status
project: kacportal
updated: 2026-05-15
phase: active
---

# kacportal — 현재 상태

## 현재 단계

🚀 **활성 개발** 단계

## 완료된 것

- [x] 위키 프로젝트 폴더 생성
- [x] 법령정보 URL 더블 인코딩 / 더블 프리픽스 수정 (`LawSrchController.java`)
- [x] 법령정보 뷰 링크 보완 (`viewLawInfo.jsp`)
- [x] 공지사항 팝업 페이지 이동 POST → GET 변경 (`main.jsp`)
- [x] 공지사항 팝업 내부/외부 링크 분기 처리 (`main.jsp`)
- [x] 인포그래픽 여객 수 산출식 확인 요청 처리 (KAC 보완요청)
- [x] 여객 수 산출식 결정 — 유임+무임+환승으로 확정 (실장님 확인)

## 진행 중

- [ ] 미커밋 설정 파일 검토 (`globals-dev.properties`, `context-properties.xml`, `log4j2.xml`)

## 다음 할 일

- [ ] 공지사항 외부 링크 판별을 DB 컬럼으로 명시적 구분 검토 (현재 `http` 시작 여부로 임시 판별)
- [ ] 법령정보 URL 엣지케이스 확인 (`//` 프로토콜 상대 URL 등)
- [ ] 인포그래픽 여객 수 산출식 수정 반영 (추후 공사 방문 후)
- [ ] V_IFIS_ANL_FLY_INFO 테이블 활용 여부 확인 (내부망 DDL 확인 필요)

## 블로커

_(없음)_

## 메모

- 브랜치: `dev`
- 마지막 세션: [[sessions/2026-04-20-law-search-encoding-notice-popup]]

