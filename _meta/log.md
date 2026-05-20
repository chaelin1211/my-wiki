---
type: log
---

# my-wiki — Log

시간순 작업 기록. 각 항목은 `## [YYYY-MM-DD] 유형 | 제목` 형식.

---

## [2026-04-20] init | my-wiki 초기 설정

- Obsidian Vault 생성
- 디렉토리 구조, 템플릿, 스키마 초기화 완료

## [2026-04-20] init | dna-sql-agent 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/dna-sql-agent
- 목표: 자연어 질문을 SQL로 변환하여 Oracle DB 결과를 반환하는 온프레미스 AI 에이전트
- 스택: python, fastapi, vanna, ollama, oracle-db, qdrant

## [2026-04-20] init | dna-sql-agent-web 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/dna-sql-agent-web
- 목표: dna-sql-agent 백엔드와 연동하는 Text-to-SQL AI 챗봇 웹 프론트엔드
- 스택: nextjs, typescript, tailwindcss, shadcn-ui, plotly

## [2026-04-20] init | kac-idp-noti 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/kac-idp-noti
- 목표: Kafka consumer 기반 KAC IDP 알림 발송 서버
- 스택: java, spring, kafka, hibernate, altibase, docker

## [2026-04-20] init | kacportal 프로젝트 생성

- 위키 프로젝트 폴더 생성: projects/kacportal
- 목표: KAC 공항공사 통합데이터플랫폼 포털 웹 애플리케이션
- 스택: java, spring, egovframe, oracle-db, tomcat

## [2026-05-14] session | dna-sql-agent-web — docker --network host 적용 & 시스템 선택 팝업 디버깅

## [2026-05-19] session | dna-sql-agent-web — 마이페이지 커밋/PR 생성, 어드민 인증 가드 추가

## [2026-05-20] session | dna-sql-agent-web — 이전 대화 단순 응답 메시지 누락 버그 수정

## [2026-04-20] session | kacportal — 법령정보 URL 더블 인코딩 픽스 & 공지사항 팝업 내비게이션 수정

- 법령정보 첨부파일 다운로드 URL 더블 프리픽스/더블 인코딩 수정 (`LawSrchController.java`)
- 공지사항 팝업 POST → GET 방식 변경, 내부/외부 링크 분기 추가 (`main.jsp`)
- 이슈 기록: law-url-double-prefix, notice-popup-post-navigation
- 지식 기록: knowledge/troubleshooting/spring-url-double-encoding
