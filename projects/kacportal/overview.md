---
type: project-overview
project: kacportal
created: 2026-04-20
updated: 2026-04-20
status: active
stack: [java, spring, egovframe, mybatis, oracle-db, kafka, elasticsearch, tomcat]
repo: ""
goal: "KAC 공항공사 통합데이터플랫폼 포털 — 공항 운영 데이터 통합 분석 및 경영진 대시보드 웹 서비스"
---

# kacportal

## 목표

> 공항공사 운영 데이터를 통합하여 실시간 현황 조회, 데이터 분석, 경영진 대시보드를 제공하는 포털 웹 애플리케이션 (http://www.airportal.go.kr)

## 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| Backend | Java 1.8, Spring 5.3.27, eGovFrame 4.2.0 | WAR 패키징 |
| ORM/SQL | MyBatis | XML 매핑 |
| Frontend | JSP, JavaScript, CKEditor 3.5.3 | 반응형 웹 (모바일 지원) |
| DB | Oracle (Primary), Tibero, Altibase | 멀티 DB 지원, DBCP2 커넥션 풀 |
| 검색 | Elasticsearch 8.13.4 | 전문검색, 자동완성 |
| 메시지 큐 | Apache Kafka 3.7.0 | 비동기 이벤트 처리 |
| 캐싱 | Ehcache 3.9.7 | 메뉴 등 공통 데이터 |
| Infra/Deploy | Tomcat 8x, Maven, Cargo Plugin | dev/stg/운영 profile 분리 |

## 주요 기능

**공항 운영 현황**
- 실시간 항공기 위치 & NOTAM 정보
- 공항별 여객 혼잡도 / 날씨 / 주차 현황
- 항공기 지상 이동 정보

**데이터 분석**
- 공항 이용객 출도착지 분석 (GIS)
- 악기상 결항 예측, 여객흐름 분석, 공항별 수요 예측
- AI X-ray 실적 현황, AI BiM 데이터센터

**경영진 대시보드**
- 운항현황·매출·예산, 스마트기기 이용현황
- 경영진 일정 & 대면보고 예약

**포털 서비스**
- 공항 유실물 조회 (PC/Mobile)
- 법령 정보 검색, 통합 검색 & 자동완성
- Work Hub (자료요청/제출), 데이터 알리미
- 커뮤니티 (게시판, 공지사항)

## 외부 의존성

| 서비스 | 용도 |
|--------|------|
| Oracle / Tibero / Altibase | Primary DB |
| Elasticsearch | 전문검색 |
| Kafka | 비동기 이벤트 (kac-idp-noti 연동) |
| MicroStrategy (MSTR) | 데이터 대시보드 |
| NiFi | ETL 데이터 파이프라인 |
| SSO | 인증 |

## 환경 설정

| 환경 | Profile | 설정 파일 |
|------|---------|-----------|
| 로컬 개발 | dev | globals-dev.properties |
| 스테이징 | stg | globals-stg.properties |
| 운영 | (기본) | globals.properties |

로컬 실행: `./run-tomcat.sh` (port 8081) / `./run-tomcat-debug.sh`

## 주요 의사결정

_(ADR 추가 시 갱신)_

## 현재 상태

→ [[projects/kacportal/status|상세 상태]] 참조

## 관련 지식

- [[projects/kac-idp-noti/overview|kac-idp-noti]] — Kafka 알림 서버 (연동 프로젝트)
