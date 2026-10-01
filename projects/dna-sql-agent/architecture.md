---
type: architecture
project: dna-sql-agent
created: 2026-04-20
updated: 2026-09-22
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
| 소스 보호 | Nuitka | — | `dna`/`vanna` 자체 코드만 파일 단위 `.py`→`.so` 컴파일 (ADR-027) |

## 디렉토리 구조

```
src/
├── main.py                      # 진입 shim (실제 부트스트랩은 dna/app)
├── dna/                         # DNA 커스텀 레이어
│   ├── app/                     # 서버 부트스트랩 (CLI, 팩토리) — 컴파일 대상
│   ├── settings/                # 설정 로드·검증 (defaults/*.json = 초기값 겸 스펙)
│   ├── agent_service.py         # Agent 초기화, 도구/미들웨어 등록
│   ├── integrations/            # LLM & DB 연동 팩토리
│   ├── enhancers/               # LLM 컨텍스트 강화 (벡터 검색)
│   ├── tools/                   # 커스텀 도구 (SQL 실행, 시각화)
│   ├── vectorstores/            # Qdrant 클라이언트 래퍼
│   ├── prompt_builders/         # Oracle 방언 + 한국어 시스템 프롬프트
│   ├── middlewares/             # 요청/응답 처리 (로깅, Langfuse, 정제)
│   ├── hooks/                   # 라이프사이클 훅 (파일 로그, Langfuse)
│   ├── filters/                 # 대화 필터
│   ├── workflow_handlers/       # LLM 호출 전 메시지 가로채기 (슬래시 커맨드 분기)
│   ├── commands/                # 슬래시 커맨드 — DB 정의 조회·권한·실행, 조회·관리 API
│   ├── components/              # DnA 전용 응답 컴포넌트 (명확화 카드, item_list)
│   ├── loggers/                 # 감사 로그 (audit.log)
│   └── utils/                   # 마스킹, SQL 가드레일, 추정기
└── dadap/                       # 에이전트 프레임워크 코어 (구 vanna, 2026-09 리네임)
    ├── core/                    # Agent, LLM 인터페이스, 메모리
    └── servers/fastapi/         # FastAPI 라우트 정의
```

## 데이터 흐름

```
사용자 메시지 (POST /api/vanna/v2/chat_sse)
  │
  ├─ 1. 유저 해석 (이메일 쿠키 → admin/user 역할)
  │
  ├─ 1-1. 슬래시 커맨드 해석 (첫 글자 `/`)
  │     ├─ builtin·text: LLM 없이 응답하고 턴 저장 → 종료
  │     └─ skill: 지시문 스냅샷을 메타데이터로 붙여 아래 LLM 경로로 진행 ([[042-skill-turn-snapshot-and-llm-expansion]])
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
  │     └─ 차트 시각화 (옵션) — ECharts / DevExtreme / Plotly
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
| GET | `/api/v1/commands` | 사용자가 쓸 수 있는 슬래시 커맨드 목록 |
| GET·POST·PATCH·DELETE | `/api/v1/commands/admin` | 슬래시 커맨드 관리 (관리자) |

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

- [[027-nuitka-source-compilation]] — 배포 이미지 소스 보호, Nuitka로 자체 코드만 파일 단위 컴파일
- [[034-defaults-as-config-validation-spec]] — `defaults/*.json` 이 초기값이자 `config/*.json` 검증 스펙, 기동 시 대조해 불일치면 중단
- [[041-slash-commands-db-registry]] — 슬래시 커맨드 정의는 DB에, 실행 로직만 코드에
- [[043-command-result-dedicated-component]] — 항목별 동작이 있는 커맨드 결과는 전용 컴포넌트로
