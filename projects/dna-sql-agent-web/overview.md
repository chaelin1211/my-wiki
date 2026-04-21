---
type: project-overview
project: dna-sql-agent-web
created: 2026-04-20
updated: 2026-04-20
status: active
stack: [nextjs, typescript, tailwindcss, shadcn-ui, plotly, docker]
repo: ""
goal: "dna-sql-agent 백엔드와 SSE로 연동하는 Text-to-SQL AI 챗봇 웹 프론트엔드"
---

# dna-sql-agent-web

## 목표

> dna-sql-agent 백엔드의 SSE 스트림을 실시간으로 수신해 단계별 응답(SQL, 테이블, 차트)을 렌더링하는 챗봇 프론트엔드.

## 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| Framework | Next.js 16 (App Router) | |
| 언어 | TypeScript | |
| 스타일링 | Tailwind CSS v4 | |
| UI 컴포넌트 | shadcn/ui (Radix UI) | |
| 차트 | Plotly.js (react-plotly.js) | |
| Markdown | react-markdown + remark-gfm | |
| 패키지 매니저 | pnpm | |

## 주요 기능

- **SSE 스트리밍**: 백엔드 응답을 Server-Sent Events로 실시간 수신
- **단계별 말풍선**: 툴 실행 상태(SQL 생성 → 실행 → 결과)를 순서대로 표시
- **SQL 코드 블록**: 실행된 SQL 쿼리 표시
- **데이터 테이블**: 쿼리 결과 검색·정렬 가능한 테이블
- **Plotly 차트**: 시각화 결과 인터랙티브 차트
- **다중 대화**: 여러 대화 생성 및 전환
- **권한 기반 UI**: admin/user 역할에 따라 서버가 컴포넌트 제어
- **인증**: 이메일 쿠키(`vanna_email`) 기반, 모든 요청에 `X-User-Email` 헤더 전송

## 환경 설정

| 파일 | 용도 |
|------|------|
| `.env.development` | `NEXT_PUBLIC_API_BASE_URL=http://localhost:8000` |
| `.env.production` | `NEXT_PUBLIC_API_BASE_URL=http://192.168.101.129:18000` |

## 주요 의사결정

_(ADR 추가 시 갱신)_

## 현재 상태

→ [[projects/dna-sql-agent-web/status|상세 상태]] 참조

## 관련 지식

- [[projects/dna-sql-agent/overview|dna-sql-agent]] — 연동 백엔드
