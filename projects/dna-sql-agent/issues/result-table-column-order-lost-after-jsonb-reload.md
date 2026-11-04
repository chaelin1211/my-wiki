---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-19
resolved: true
root-cause: "대화 기록 JSONB 저장 시 행 객체 키가 재정렬되고, 웹이 첫 행의 키 순서로 컬럼을 정함"
related: [dna-sql-agent-web]
tags: [postgres, jsonb, web, data-table, chat-history]
---

# 다시 연 대화의 결과 표 컬럼 순서가 SQL과 다름

## 증상

질문 직후(실시간)에는 결과 표 컬럼이 SQL 순서인데, 대화를 새로고침하거나 다시 열면 순서가 바뀐다. 한글 컬럼에서 주로 눈에 띈다.

```
SQL      : 위치명, 최대수량, 현재재고, 여유공간
다시 열면 : 위치명, 여유공간, 최대수량, 현재재고
```

## 환경

- **런타임:** 웹 Next.js(react-markdown), 백엔드 PostgreSQL `messages.components`(JSONB)
- **재현 조건:** 결과 표가 있는 대화를 다시 열기

## 시도한 것들

1. ❌ 인코딩 문제로 의심 — DOM의 헤더 코드포인트는 정상
2. ✅ 저장된 컴포넌트 확인 — `data.columns`는 SQL 순서, 행 객체 키는 뒤섞임

## 근본 원인

JSONB는 객체 키를 "키 바이트 길이 → 바이트값" 순으로 재정렬해 저장한다. 웹 `DataTable`이 `Object.keys(rows[0])`로 컬럼 순서를 정해서, 다시 불러온 표는 순서가 바뀐다. 영문 컬럼은 길이순이 우연히 맞는 경우가 많다.

## 해결 방법

백엔드가 이미 함께 보내는 `columns` 배열(배열은 JSONB에서도 순서 보존)을 데이터 단계(`kind: 'data'`)까지 전달하고, 표·엑셀 다운로드(`json_to_sheet`의 `header`)·엑셀 반영에서 우선 사용한다. 없으면 기존 방식으로 대체한다. 웹 PR #105.

## 예방책

- 순서가 의미 있는 값은 JSON 객체 키 순서에 의존하지 말고 배열로 따로 보관·사용
- 실시간 화면과 기록 재생 화면을 둘 다 확인

## 관련 페이지

- [[knowledge/troubleshooting/postgres-jsonb-object-key-order]]
- [[sessions/2026-10-19-altibase-korean-columns-dna-ask-links]]
