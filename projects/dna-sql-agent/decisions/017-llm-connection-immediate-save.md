---
type: decision-record
project: dna-sql-agent
date: 2026-06-25
status: accepted
superseded-by: ""
tags: [settings, llm, dirty-save, ux]
---

# ADR-017: LLM 연결 관리는 즉시 저장으로 통일

## 맥락

에이전트 설정 화면은 대부분 dirty-save 패턴(값을 staging → 상단 SaveBanner의 "변경사항 저장"을 눌러야 DB 반영)을 쓴다.
그러나 LLM 연결 관리(foundation 탭)는 **하이브리드**였다:

- 연결 추가/수정/삭제 → 다이얼로그에서 **즉시 DB 저장**(별도 테이블, 별도 API)
- 활성 연결 선택(활성화)만 **dirty-save**(`pendingActiveId` staging → SaveBanner 저장 시 `activate()`)

같은 메뉴 안에서 일부는 즉시 저장, 일부는 staged라 사용자·코드 모두 혼란.

## 선택지

### 옵션 A: 활성화도 즉시 저장
- **장점:** CRUD(추가/수정/삭제)와 일관. 라디오 선택 즉시 반영. dirty/saveRef/imperativeHandle 제거로 단순.
- **단점:** foundation 탭에선 SaveBanner의 저장/리셋 버튼이 의미 없어짐(헤더 대체 필요).

### 옵션 B: 전체를 dirty-save로 통일
- **장점:** SaveBanner 패턴과 일관.
- **단점:** 추가/수정/삭제를 draft로 staging해야 함 → 별도 테이블 CRUD를 임시상태로 다루는 건 부자연스럽고 구현 복잡/위험.

## 결정

**옵션 A — 활성화도 즉시 저장.**

- 라디오 선택 시 즉시 `activate()` 호출 + 토스트, 진행 중 비활성화.
- foundation 탭은 SaveBanner 대신 "연결 추가·수정·삭제 및 사용 연결 선택은 바로 적용됩니다." 안내 바 표시(동일 sticky 스타일).
- `foundationSaveRef`/`foundationDirty` 및 관련 dirtyCount·탭 표식 배선 제거.

## 근거

- LLM 연결은 ctx 설정 섹션이 아니라 별도 테이블/API(`useLlmConnections`)다. dirty-save의 "한 번에 모아 저장"은 단일 config 편집에 맞는 패턴이지, 행 단위 CRUD에는 맞지 않는다.
- 활성화는 단일 행 토글이라 즉시 반영이 자연스럽고, 잘못 눌러도 다시 선택하면 됨(되돌리기 비용 낮음).

## 관련

- 세션: [[projects/dna-sql-agent/sessions/2026-06-25-system-exclude-tables-table-access-control]]
- 리셋 동작 관련: [[issues/settings-reset-not-restoring-saved]]
