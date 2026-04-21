---
type: architecture
project: dna-sql-agent-web
created: 2026-04-20
updated: 2026-04-20
---

# dna-sql-agent-web — 아키텍처

## 시스템 개요

Next.js 16 App Router 기반의 순수 프론트엔드. 별도 서버 사이드 로직 없이 dna-sql-agent 백엔드의 SSE 스트림을 직접 소비한다. 상태는 React 클라이언트 컴포넌트에서 관리하며, 인증은 이메일 쿠키 기반이다.

## 기술 스택 상세

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| Framework | Next.js (App Router) | 16 | 라우팅, SSR |
| 언어 | TypeScript | — | 타입 안전성 |
| 스타일링 | Tailwind CSS | v4 | 유틸리티 CSS |
| UI 컴포넌트 | shadcn/ui (Radix UI) | — | 접근성 기반 컴포넌트 |
| 차트 | react-plotly.js | — | 인터랙티브 시각화 |
| Markdown | react-markdown + remark-gfm | — | AI 응답 렌더링 |
| 패키지 매니저 | pnpm | — | |

## 디렉토리 구조

```
app/
  page.tsx              # 메인 페이지 (대화 상태 관리)
  layout.tsx            # 앱 레이아웃
  globals.css           # 전역 스타일 & 디자인 토큰

components/
  chat-view.tsx         # 채팅 영역 (메시지 목록 + 입력창)
  chat-message.tsx      # 메시지 말풍선 (step별 렌더링)
  chat-input.tsx        # 메시지 입력창
  chat-header.tsx       # 헤더 (백엔드 연결 상태 표시)
  conversation-list.tsx # 대화 목록 사이드바
  sql-block.tsx         # SQL 코드 블록
  data-table.tsx        # 쿼리 결과 테이블 (검색/정렬)
  chart-block.tsx       # Plotly 차트

lib/
  vanna-api.ts          # SSE 클라이언트 (백엔드 통신)
  types.ts              # TypeScript 타입 정의
  utils.ts              # 유틸리티 함수

hooks/
  use-auth.ts           # 이메일 쿠키 기반 인증
  use-mobile.ts         # 모바일 감지
```

## 데이터 흐름

```
사용자 메시지 입력 (chat-input.tsx)
  │
  ├─ lib/vanna-api.ts
  │   POST /api/vanna/v2/chat_sse
  │   헤더: X-User-Email (쿠키에서 추출)
  │
  └─ SSE 스트림 수신 → 단계별 파싱
      ├─ tool_start  → 로딩 말풍선 표시
      ├─ tool_result (SQL) → sql-block.tsx
      ├─ tool_result (table) → data-table.tsx
      ├─ tool_result (chart) → chart-block.tsx
      └─ message → react-markdown 렌더링
```

## 백엔드 연동

| 엔드포인트 | 설명 |
|-----------|------|
| `POST /api/vanna/v2/chat_sse` | SSE 스트리밍 채팅 |
| `GET /health` | 서버 연결 상태 확인 |

CORS: 백엔드 `allow_origins`에 프론트엔드 origin 등록 필요.

## 외부 의존성

| 서비스 | 용도 |
|--------|------|
| dna-sql-agent | 유일한 백엔드 (SSE API) |

## 관련 의사결정

_(ADR 추가 시 갱신)_
