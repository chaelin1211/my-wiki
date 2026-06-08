---
type: decision-record
project: dna-sql-agent
date: 2026-05-21
status: accepted
superseded-by: ""
tags: [chat, pin, ux]
---

# ADR-001: 채팅 목록 고정 순서 관리 — pinned_at vs pinned_sn

## 맥락

채팅 목록 상단 고정 기능 구현 시 고정된 항목들의 정렬 순서를 어떻게 관리할지 결정 필요.

## 선택지

### 옵션 A: `pinned_at TIMESTAMPTZ`
- **장점:** 별도 관리 불필요, 고정 시각 자동 기록, 구현 단순
- **단점:** 순서 변경 시 timestamp 인위 조작 필요 (hacky)
- **비용/노력:** 낮음

### 옵션 B: `pinned_sn INTEGER`
- **장점:** drag & drop 수동 순서 변경에 자연스러움
- **단점:** 순서 변경 API(`PATCH /pin/reorder`) + UI(drag&drop) 추가 구현 필요
- **비용/노력:** 높음

## 결정

**옵션 A(`pinned_at`)를 선택한다.**

## 근거

채팅 목록에서 순서를 자주 바꾸는 UX가 아님. 순서 변경을 지원하려면 drag&drop UI와 reorder API까지 구현해야 하는데 배보다 배꼽이 크다. `pinned_at ASC NULLS LAST`로 먼저 고정한 게 위, 새로 고정하면 아래로 붙는 방식으로 충분.

## 결과

- `pinned_at`이 있는 항목은 상단, 없으면 `updated_at` 내림차순
- 정렬: `ORDER BY pinned_at ASC NULLS LAST, updated_at DESC`
- 순서 변경 UX는 미지원 (향후 필요 시 `pinned_sn`으로 마이그레이션)
