---
type: decision-record
project: dna-sql-agent
date: 2026-05-21
status: accepted
superseded-by: ""
tags: [bookmark, database, design]
---

# ADR-002: 북마크 컴포넌트 데이터 저장 — 참조 vs 스냅샷

## 맥락

채팅 결과 카드(chart/dataframe/artifact) 북마크 시 컴포넌트 데이터를 bookmarks 테이블에 복사할지, messages 테이블을 참조할지 결정 필요.

## 선택지

### 옵션 A: 스냅샷 저장 (`component_data JSONB`)
- **장점:** 대화 삭제 후에도 북마크 데이터 보존, JOIN 불필요
- **단점:** 데이터 중복, 차트/테이블 데이터 크기에 따라 스토리지 부담
- **비용/노력:** 중간

### 옵션 B: 참조 (`message_id` + `component_id`)
- **장점:** 중복 없음, messages 기존 데이터 활용
- **단점:** 대화 삭제 시 북마크도 삭제됨 (CASCADE)
- **비용/노력:** 낮음

## 결정

**옵션 B(참조)를 선택한다.**

## 근거

컴포넌트 데이터는 `messages.components` JSONB에 이미 저장되어 있어 중복 저장이 불필요하다. 대화 삭제 시 관련 북마크도 함께 삭제되는 것이 자연스러운 UX다 (삭제한 대화의 차트를 모아보기에서 계속 보는 것은 혼란스러움).

## 결과

- `bookmarks(message_id FK → messages.id ON DELETE CASCADE)`
- 모아보기 조회 시 `LATERAL jsonb_array_elements(m.components)` + `elem->>'id' = b.component_id`로 단일 컴포넌트 추출
- asyncpg에서 LATERAL JOIN 결과가 str/dict 혼재할 수 있어 `_parse_component()` 헬퍼로 방어 처리 필요
