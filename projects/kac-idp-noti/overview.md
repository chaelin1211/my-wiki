---
type: project-overview
project: kac-idp-noti
created: 2026-04-20
updated: 2026-04-20
status: active
stack: [java, spring, kafka, hibernate, tibero, altibase, mysql, docker]
repo: ""
goal: "Kafka consumer 기반 KAC IDP 알림 발송 서버 (이메일·SMS·카카오·마이페이지)"
---

# kac-idp-noti

## 목표

> kacportal이 Kafka topic으로 발행한 알림 요청을 소비해 이메일·SMS·카카오 알림톡·마이페이지 4가지 채널로 발송하는 독립형 Java 서버. Docker 컨테이너로 운영한다.

## 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| 언어 | Java 9+ | UberJAR (Maven Shade) |
| 프레임워크 | Spring 5.3.37 | DI, 스케줄링 |
| ORM | Hibernate 5.6.15 + HikariCP 3.2.0 | StatelessSession (대량 처리) |
| 메시지 큐 | Apache Kafka 3.7.0 | Consumer (수동 커밋) |
| DB (메인) | Tibero 7 | Portal, ODS, DW 3개 스키마 |
| DB (알림) | Altibase 7.3 | DM 스키마 |
| DB (SMS/Kakao) | MySQL 8.4 | Ppurio 연동 |
| 알림 발송 | Ppurio API | SMS, 카카오 알림톡 |
| 이메일 발송 | 공항공사 EKP REST API | HTTP (Apache HttpClient5) |
| 배포 | Docker, Harbor 레지스트리 | JDK 17 베이스 이미지 |

## 알림 채널

| 코드 | 채널 | 방식 |
|------|------|------|
| 01 | 이메일 | 공항공사 EKP API (HTTP POST) |
| 02 | SMS | Ppurio API → MySQL |
| 03 | 카카오 알림톡 | Ppurio API → MySQL |
| 04 | 마이페이지 | Portal Tibero DB 직접 저장 |

## Kafka Topic

| 환경 | Topic 명 |
|------|---------|
| 로컬 | `kac-idp-noti-request-local-test` |
| 개발 | `kac-idp-noti-request-dev` |
| 운영 | `kac-idp-noti-request-kac` |

## 주요 의사결정

_(ADR 추가 시 갱신)_

## 현재 상태

→ [[projects/kac-idp-noti/status|상세 상태]] 참조

## 관련 지식

- [[projects/kacportal/overview|kacportal]] — 알림 요청을 발행하는 포털 (연동 프로젝트)
