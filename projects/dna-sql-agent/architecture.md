---
type: architecture
project: dna-sql-agent
created: 2026-04-20
updated: 2026-04-20
---

# dna-sql-agent — 아키텍처

## 시스템 개요

FastAPI + Vanna 2.0 기반의 Text-to-SQL 에이전트 서버. 사용자 메시지가 들어오면 Qdrant에서 관련 FAQ·테이블·컬럼 메타데이터를 벡터 검색으로 가져와 LLM 컨텍스트를 강화한 뒤 SQL을 생성한다. SQL은 가드레일 검사 후 Oracle/Postgres에서 실행되고, 결과는 SSE 스트림으로 프론트엔드(dna-sql-agent-web)에 전달된다. 모든 LLM 추론은 내부 vLLM 서버에서 처리해 완전 온프레미스를 유지한다.

## 기술 스택 상세

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| AI 프레임워크 | Vanna | 2.0.2 | Text-to-SQL 핵심 엔진 |
| Backend | FastAPI | — | SSE/WebSocket API 서버 |
| LLM (기본) | vLLM | — | OpenAI 호환 API, 내부 서버 |
| LLM (대안) | Ollama, Anthropic, Gemini, OpenAI | — | 환경변수 `LLM_SERVICE_TYPE`으로 전환 |
| 임베딩 | SentenceTransformers | — | 모델: `upskyy/bge-m3-korean` |
| 벡터 DB | Qdrant | — | 메모리 저장 + 메타데이터 검색 |
| DB (Primary) | Oracle | cx_Oracle | 운영 환경 |
| DB (대안) | PostgreSQL | psycopg2 | 개발/테스트 환경 |
| 관찰성 | Langfuse | — | 트레이싱, 대화 로그 |
| 배포 | Docker + GitHub Actions | — | self-hosted runner, 수동 트리거 |

## 디렉토리 구조

```
src/
├── main.py                      # FastAPI 서버 진입점
├── dna/                         # DNA 커스텀 레이어
│   ├── agent_service.py         # Agent 초기화, 도구/미들웨어 등록
│   ├── integrations/            # LLM & DB 연동 팩토리
│   ├── enhancers/               # LLM 컨텍스트 강화 (벡터 검색)
│   ├── tools/                   # 커스텀 도구 (SQL 실행, 시각화)
│   ├── vectorstores/            # Qdrant 클라이언트 래퍼
│   ├── prompt_builders/         # Oracle 방언 + 한국어 시스템 프롬프트
│   ├── middlewares/             # 요청/응답 처리 (로깅, Langfuse, 정제)
│   ├── hooks/                   # 라이프사이클 훅 (파일 로그, Langfuse)
│   ├── filters/                 # 대화 필터
│   ├── workflow_handlers/       # 특수 메시지 처리
│   ├── loggers/                 # 감사 로그 (audit.log)
│   └── utils/                   # 마스킹, SQL 가드레일, 추정기
└── vanna/                       # Vanna 프레임워크 코어 (수정 버전)
    ├── core/                    # Agent, LLM 인터페이스, 메모리
    └── servers/fastapi/         # FastAPI 라우트 정의
```

## 데이터 흐름

```
사용자 메시지 (POST /api/vanna/v2/chat_sse)
  │
  ├─ 1. 유저 해석 (이메일 쿠키 → admin/user 역할)
  │
  ├─ 2. 벡터 검색 (Qdrant)
  │     └─ 메시지 임베딩 → FAQ / 테이블 / 컬럼 메타데이터 검색
  │
  ├─ 3. 시스템 프롬프트 구성
  │     └─ Oracle 방언 규칙 + 한국어 응답 규칙 + 검색 결과 주입
  │
  ├─ 4. LLM 호출 (vLLM :10000)
  │     └─ SQL 생성 또는 일반 응답
  │
  ├─ 5. 도구 실행 (SQL인 경우)
  │     ├─ SQL 가드레일 검사 (SELECT 전용, ROWNUM 제한)
  │     ├─ 데이터 마스킹
  │     ├─ Oracle/Postgres 실행 → DataFrame
  │     └─ Plotly 시각화 (옵션)
  │
  ├─ 6. Qdrant 메모리 저장 (질문-SQL-결과 쌍)
  │
  └─ 7. SSE 스트림으로 응답 반환
        └─ Langfuse 트레이싱, audit.log 기록
```

## API 엔드포인트

| Method | Path | 설명 |
|--------|------|------|
| POST | `/api/vanna/v2/chat_sse` | SSE 스트리밍 채팅 |
| WebSocket | `/api/vanna/v2/chat_websocket` | WebSocket 채팅 |
| GET | `/health` | 헬스체크 |

외부 포트: **18000** (Docker) → 내부 8000 (FastAPI)

## 외부 의존성

| 서비스 | 용도 | 주소 |
|--------|------|------|
| vLLM | LLM 추론 | `192.168.101.129:10000` |
| Qdrant | 벡터 메모리 | `192.168.101.129:6333` |
| Oracle / PostgreSQL | 쿼리 대상 DB | 환경별 상이 |
| Langfuse | 관찰성 | `192.168.101.129:3000` |

## 주요 환경변수

| 변수 | 예시값 | 설명 |
|------|--------|------|
| `LLM_SERVICE_TYPE` | `vllm` | vllm\|ollama\|anthropic\|gemini\|openai |
| `LLM_URL` | `http://....:10000/v1` | LLM API 주소 |
| `DB_DIALECT` | `postgres` | oracle\|postgres |
| `QDRANT_URL` | `http://....:6333` | Qdrant 주소 |
| `EMBEDDING_MODEL` | `upskyy/bge-m3-korean` | 한국어 임베딩 모델 |
| `LANGFUSE_BASE_URL` | `http://....:3000` | Langfuse 주소 |

## 관련 의사결정

_(ADR 추가 시 갱신)_
