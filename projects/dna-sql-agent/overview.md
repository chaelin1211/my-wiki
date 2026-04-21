---
type: project-overview
project: dna-sql-agent
created: 2026-04-20
updated: 2026-04-20
status: active
stack: [python, fastapi, vanna, vllm, ollama, oracle, postgres, qdrant, docker]
repo: ""
goal: "자연어 질문을 SQL로 변환하여 Oracle/Postgres DB 결과를 반환하는 온프레미스 AI 에이전트"
---

# dna-sql-agent

## 목표

> Vanna 2.0 프레임워크 기반의 Text-to-SQL AI 에이전트. 자연어 질문 → SQL 생성 → DB 실행 → 결과/시각화 반환. 완전 온프레미스로 동작하며 데이터가 외부로 나가지 않는다.

## 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| AI 프레임워크 | Vanna 2.0 | Text-to-SQL 엔진 |
| LLM | vLLM (기본), Ollama, Anthropic, Gemini, OpenAI | 환경변수로 전환 |
| 임베딩 | SentenceTransformers (bge-m3-korean) | 한국어 특화 |
| 벡터 DB | Qdrant | 메모리 + 메타데이터 검색 |
| Backend | Python, FastAPI | SSE/WebSocket 스트리밍 |
| DB | Oracle, PostgreSQL | 환경변수로 전환 |
| 관찰성 | Langfuse | 트레이싱, 로그 |
| Infra/Deploy | Docker, GitHub Actions (self-hosted runner) | 수동 트리거 배포 |

## 주요 기능

- **Text-to-SQL**: 자연어 → SQL 자동 생성 (Oracle/Postgres 방언 지원)
- **벡터 메모리**: FAQ·테이블·컬럼 메타데이터를 Qdrant에 저장, 검색 컨텍스트로 활용
- **SQL 가드레일**: SELECT 전용, ROWNUM 자동 제한, 데이터 마스킹
- **데이터 시각화**: 쿼리 결과 Plotly 차트 자동 생성
- **역할 기반 접근제어**: admin(메모리 관리 포함) / user

## 외부 의존성

| 서비스 | 용도 | 포트 |
|--------|------|------|
| vLLM 서버 | LLM 추론 (OpenAI 호환 API) | 10000 |
| Qdrant | 벡터 메모리 저장소 | 6333 |
| Oracle / PostgreSQL | 쿼리 대상 DB | — |
| Langfuse | 트레이싱 & 관찰성 대시보드 | 3000 |

## 주요 의사결정

_(ADR 추가 시 갱신)_

## 현재 상태

→ [[projects/dna-sql-agent/status|상세 상태]] 참조

## 관련 지식

- [[projects/dna-sql-agent-web/overview|dna-sql-agent-web]] — 연동 프론트엔드
