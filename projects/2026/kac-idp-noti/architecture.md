---
type: architecture
project: kac-idp-noti
created: 2026-04-20
updated: 2026-04-20
---

# kac-idp-noti — 아키텍처

## 시스템 개요

Spring 기반의 독립형 Java 애플리케이션(UberJAR). Kafka Consumer가 알림 요청 메시지를 폴링하고, 채널(이메일/SMS/카카오/마이페이지)에 따라 발송 로직을 분기한다. 5개 DB(Tibero×3, Altibase×1, MySQL×1)를 Hibernate StatelessSession으로 연결하며, 배치 프로세서가 병렬 발송 및 재시도를 처리한다. Docker 컨테이너로 운영되며 프로필(`-p` 인자)로 환경을 전환한다.

## 기술 스택 상세

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| 언어 | Java | 9 | |
| 프레임워크 | Spring | 5.3.37 | DI, 스케줄링 |
| ORM | Hibernate | 5.6.15 | StatelessSession (대량 처리 최적화) |
| 커넥션 풀 | HikariCP | 3.2.0 | 풀 사이즈 3 (DB별) |
| 메시지 큐 | Kafka Clients | 3.7.0 | Consumer, poll 1000ms, max 100건 |
| DB (Portal) | Tibero | 7 | 발송 내역/템플릿/대기 테이블 |
| DB (ODS) | Tibero | 7 | 직원 정보 조회 |
| DB (DW) | Tibero | 7 | DW 데이터 조회 |
| DB (DM) | Altibase | 7.3 | DM 데이터 조회 |
| DB (Ppurio) | MySQL | 8.4 | SMS/카카오 발송 연동 |
| 템플릿 엔진 | Thymeleaf | 3.0.15 | 알림 메시지 렌더링 |
| HTTP 클라이언트 | Apache HttpClient5 | 5.3.1 | 이메일 API, Ppurio API |
| 설정 | Typesafe Config | 1.4.3 | app-{profile}.conf |
| 빌드 | Maven Shade Plugin | 3.6.0 | UberJAR 생성 |
| 배포 | Docker (JDK 17) | — | Harbor 레지스트리 |

## 디렉토리 구조

```
src/main/java/kac/idp/noti/
├── AppMain.java                  # 진입점 (-p 프로필 인자)
├── AppContext.java               # 전역 컨텍스트 & 리소스 관리
├── common/                       # DB 연결 지속성, 리소스 리셋
├── service/
│   ├── send/                     # 알림 발송 서비스
│   │   ├── KafkaReceiveService   # Kafka 메시지 파싱 & 검증
│   │   ├── CommonSendProcessor   # 발송 공통 로직
│   │   ├── EmailSendService      # 이메일 (EKP API)
│   │   ├── SmsSendService        # SMS (Ppurio)
│   │   ├── KakaoSendService      # 카카오 알림톡 (Ppurio)
│   │   ├── MyPageSendService     # 마이페이지 (DB 저장)
│   │   ├── PpurioSendService     # Ppurio 통합 서비스
│   │   ├── SendResultUpdateService # 발송 결과 폴링 갱신
│   │   ├── dto/                  # 요청/결과 DTO
│   │   └── entity/               # Hibernate Entity (발송내역, 대기 등)
│   ├── notice/                   # 데이터 알림 스케줄
│   └── report/                   # 대면보고 알림 스케줄
├── util/
│   ├── kafka/                    # KafkaFactory, ReceiverRunner
│   └── batch/                    # 병렬/단일 배치 프로세서
└── ex/

src/main/resources/
├── app-local.conf
├── app-dev.conf
├── app-kac.conf                  # 운영 환경
└── app-mobigen.conf
```

## 데이터 흐름

```
kacportal (Kafka Producer)
  │  topic: kac-idp-noti-request-{env}
  ▼
KafkaReceiverRunner (poll 1000ms, max 100건)
  │
  ▼
KafkaReceiveService
  ├─ JSON 파싱 → NoticeSendReceive DTO
  ├─ JSR-303 검증
  ├─ 60분 초과 메시지 → 폐기
  └─ DB 저장 (대기 → 내역 → 상세)
       │
       ▼
AppContext.transferSender(SendTarget)
  ├─ 01(이메일) → EmailSendService → 공항공사 EKP API
  ├─ 02(SMS)    → SmsSendService → PpurioSendService → MySQL
  ├─ 03(카카오) → KakaoSendService → PpurioSendService → MySQL
  └─ 04(마이페이지) → MyPageSendService → Portal Tibero
       │
       ▼
QueueSingleBatchProcessor
  ├─ Regular: 신규 발송 (배치 100건)
  ├─ Retry:   실패건 재시도 (최대 3회)
  └─ Monitor: 결과 로깅
       │
       ▼
SendResultUpdateService (폴링, 3일 제한)
  └─ 발송 상태 갱신 → Portal Tibero
```

## 외부 의존성

| 서비스 | 용도 | 비고 |
|--------|------|------|
| Kafka (3대 클러스터) | 알림 요청 수신 | Consumer Group: `kac-idp-noti` |
| Portal Tibero | 발송 내역·템플릿·직원정보 저장 | 5개 테이블 |
| Altibase (DM) | DM 데이터 조회 | 커스텀 Hibernate Dialect |
| MySQL (Ppurio) | SMS/카카오 발송 내역 | Ppurio 연동 전용 |
| 공항공사 EKP API | 이메일 발송 | `gwdev.airport.co.kr:7443` |
| Ppurio API | SMS·카카오 발송 | 발신번호: `02-2660-2258` |
| Harbor 레지스트리 | Docker 이미지 저장소 | `harbor.kacinfra.com:12404` |

## 배포

```
mvn clean package → uberjar/idp-noti-shade-1.0.0.jar
  │
  ▼
docker-script/buildAndPush.sh
  └─ docker build → Harbor push (타임스탬프 + latest 태그)
       │
       ▼
docker-script/remoteRun.sh
  └─ Harbor pull → docker run -p ... kac_idp_noti <profile> <log_level>
```

로컬 실행: `java -jar idp-noti-shade-1.0.0.jar -p=local`

## 관련 의사결정

_(ADR 추가 시 갱신)_
