---
type: architecture
project: kacportal
created: 2026-04-20
updated: 2026-04-20
---

# kacportal — 아키텍처

## 시스템 개요

Spring MVC + eGovFrame 기반의 전통적인 서버사이드 렌더링 웹 애플리케이션. 사용자 요청은 Tomcat → DispatcherServlet → Controller → MyBatis → Oracle/Tibero 순으로 처리된다. 실시간 데이터는 Kafka를 통해 kac-idp-noti와 이벤트를 주고받고, 전문검색은 Elasticsearch, 대시보드 시각화는 외부 MicroStrategy(MSTR)와 연동한다. 환경(dev/stg/운영)은 Spring Profile과 globals-{env}.properties로 분리된다.

## 기술 스택 상세

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| 언어 | Java | 1.8 | |
| 웹 프레임워크 | Spring MVC | 5.3.27 | DispatcherServlet, MVC |
| 공공 프레임워크 | eGovFrame | 4.2.0 | 공통 서비스 (보안, 세션 등) |
| ORM/SQL | MyBatis | — | XML 매핑, 다중 DB 지원 |
| 빌드 | Maven + Cargo Plugin | — | WAR 빌드, Tomcat 내장 실행 |
| WAS | Tomcat | 8.x | 운영 서버 |
| DB (Primary) | Oracle | ojdbc8 21.5.0.0 | 메인 DB |
| DB (대안) | Tibero 7, Altibase | — | 환경별 전환 가능 |
| DB (개발) | HSQLDB | 2.7.2 | 로컬 인메모리 |
| 커넥션 풀 | Apache Commons DBCP2 | 2.9.0 | |
| 검색 | Elasticsearch | 8.13.4 | 전문검색, 자동완성 |
| 메시지 큐 | Apache Kafka | 3.7.0 | kac-idp-noti 이벤트 연동 |
| 캐싱 | Ehcache | 3.9.7 | 메뉴, 공통 데이터 |
| JSON | Jackson | 2.17.0 | REST 응답 직렬화 |
| 파일 처리 | Apache POI | 5.2.4 | Excel 업로드/다운로드 |
| CSV 파싱 | Deephaven CSV, Univocity | 0.19.0 / 2.8.4 | 대용량 CSV |
| 에디터 | CKEditor | 3.5.3 | 게시판 WYSIWYG |
| 보안 | XSS 필터, SSO | — | 세션 타임아웃 600초 |

## 디렉토리 구조

```
src/main/
├── java/kac/idp/
│   ├── adm/                # 관리자 기능
│   │   ├── authrt/         # 권한 관리
│   │   ├── cmnty/          # 게시판 관리
│   │   ├── data/           # 데이터 관리
│   │   ├── menu/           # 메뉴 관리
│   │   └── stdgcd/         # 표준코드 관리
│   ├── com/                # 공통 기능
│   │   ├── cache/          # Ehcache
│   │   ├── elasticsearch/  # ES 클라이언트
│   │   ├── kafka/          # Kafka 프로듀서/컨슈머
│   │   ├── search/         # 통합검색
│   │   └── util/           # 유틸리티
│   └── frn/                # 프론트엔드 기능 (40+ 모듈)
│       ├── mngmGrp/        # 경영 대시보드
│       ├── arptOd/         # 공항 출도착지 분석
│       ├── widget/         # 대시보드 위젯
│       ├── workHub/        # 업무허브
│       └── ...
├── resources/egovframework/
│   ├── spring/com/         # Spring Bean XML 설정
│   ├── mapper/             # MyBatis SQL 매핑 XML
│   └── egovProps/          # 환경별 properties
└── webapp/
    ├── WEB-INF/
    │   ├── config/         # Spring MVC 설정
    │   └── web.xml
    ├── js/ css/ html/      # 정적 자원
    ├── sso/                # SSO 관련 리소스
    └── report/             # 리포트 자료
```

## 데이터 흐름

```
브라우저
  │ HTTP Request
  ▼
Tomcat (WAR)
  │ DispatcherServlet
  ▼
Controller (frn/ or adm/)
  ├─ 일반 조회 ──→ MyBatis ──→ Oracle/Tibero
  ├─ 검색 요청 ──→ Elasticsearch
  ├─ 이벤트 발행 ──→ Kafka ──→ kac-idp-noti (알림)
  ├─ 대시보드 ──→ MicroStrategy(MSTR) API
  └─ ETL 데이터 ←─ NiFi 파이프라인
```

## 외부 의존성

| 서비스 | 용도 | 대안/비고 |
|--------|------|----------|
| Oracle DB | Primary 데이터 저장소 | Tibero, Altibase 전환 가능 |
| Elasticsearch 8.x | 전문검색, 자동완성 | — |
| Apache Kafka | 알림 이벤트 발행 → kac-idp-noti | — |
| MicroStrategy (MSTR) | 경영진 데이터 대시보드 시각화 | — |
| NiFi | ETL 데이터 파이프라인 (수집/가공) | — |
| SSO 서버 | 사용자 인증 | — |
| 로컬 파일시스템 | 업로드 파일 저장 (`/share_data/idp/portal/upload`) | — |

## 관련 의사결정

_(ADR 추가 시 갱신)_
