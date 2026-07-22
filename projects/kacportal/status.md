---
type: project-status
project: kacportal
updated: 2026-07-15
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
- [x] 인포그래픽 쿼리 수정 반영 (실장님 방문 — 2026-06-01)
- [x] 스마트기기 이용통계 엑셀 다운로드 오류 수정 — `sheetName` 누락 (`smDevcSmartStatistics.js`, `dev` 브랜치 커밋 완료)
- [x] 로컬 Tomcat(cargo-maven3-plugin) 디버그 실행 스크립트 작성 (`run-tomcat.sh`, `run-tomcat-debug.sh`, 로컬 전용)

## 진행 중

- [ ] 미커밋 설정 파일 검토 (`globals-dev.properties`, `context-properties.xml`, `log4j2.xml`)
- [ ] `pom.xml`의 cargo-maven3-plugin `<property>` 문법 오류 수정 커밋 여부 결정 (진짜 버그, 현재 로컬에만 존재)

## 다음 할 일

- [ ] 공지사항 외부 링크 판별을 DB 컬럼으로 명시적 구분 검토 (현재 `http` 시작 여부로 임시 판별)
- [ ] 법령정보 URL 엣지케이스 확인 (`//` 프로토콜 상대 URL 등)
- [ ] V_IFIS_ANL_FLY_INFO 테이블 활용 여부 확인 (내부망 DDL 확인 필요)
- [ ] Altibase 내부망(127.0.0.1:1721) 접속 터널링 방법 확인 — 로컬에서 DB 연동 화면 완전 테스트하려면 필요
- [ ] `.vscode/`, `run-tomcat*.sh`를 팀 공유용으로 git에 추가할지 개인 전용으로 둘지 결정
- [ ] `test-excel-sample.html` 임시 테스트 파일 정리

## 블로커

- Altibase DB(`127.0.0.1:1721`)가 로컬에서 접속 불가 — 이 포트로 붙는 내부망 터널/VPN 설정이 없으면 DB 연동이 필요한 report 화면은 로컬에서 완전히 테스트하기 어려움.

## 메모

- 브랜치: `dev`
- 원격: `mobigen` (`192.168.105.45:12401`, 접속 가능) / `origin` (`14.35.255.226:12401`, 세션 중 접속 불가 확인됨)
- 로컬 Tomcat: cargo-maven3-plugin embedded, 기본 포트는 `pom.xml` 기준 8080 (로컬에서는 8081 + 루트 컨텍스트로 임시 변경해 사용 중, 미커밋)
- 마지막 세션: [[sessions/2026-07-15-excel-download-sheetname-bug-tomcat-debug-setup]]
