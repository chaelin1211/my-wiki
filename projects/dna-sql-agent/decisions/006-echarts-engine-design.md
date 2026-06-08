---
type: decision-record
project: dna-sql-agent
date: 2026-06-02
status: accepted
tags: [echarts, chart, frontend, schema]
---

# ADR-006: ECharts 차트 엔진 설계 — table 처리 및 동적 스키마

## 맥락

ECharts를 세 번째 차트 엔진으로 추가하면서 두 가지 설계 결정이 필요했다.

1. **table 타입 처리**: ECharts에는 native table 차트가 없음. DevExtreme의 DataGrid를 재활용할지, FE에서 별도 처리할지.
2. **LLM 툴 스키마**: 엔진마다 지원하는 차트 타입이 다른데, LLM에게 고정 타입 목록을 줄지 동적으로 줄지.

## 선택지 — table 처리

### 옵션 A: DX 포맷 그대로 반환 (래핑 없음)
- **장점:** 즉시 DX DataGrid로 렌더링 가능
- **단점:** FE bookmark 감지가 `payload?.dataSource` → DevExtreme으로 오분류

### 옵션 B: `{"option": {"dataSource": ...}}` 래핑 후 FE 분기
- **장점:** ECharts 엔진으로 정확히 감지, FE에서 `option.dataSource` 여부로 table/chart 분기
- **단점:** FE에서 EChartsBlock 내부 분기 구현 필요

## 결정 — table

**옵션 B를 선택한다.**

## 근거

FE 감지 규약 (`payload?.option` → ECharts, `payload?.dataSource` → DX)을 깨지 않기 위해 B 선택. ECharts 엔진에서 table을 DX로 오분류하면 추후 엔진별 스타일 분리가 불가능해진다.

---

## 선택지 — LLM 스키마

### 옵션 A: 전체 타입 고정 Literal
- **장점:** 단순
- **단점:** DX 엔진에서 sankey 요청 시 엉뚱한 결과

### 옵션 B: 엔진별 동적 Literal (`create_model`)
- **장점:** LLM이 현재 엔진의 유효한 타입만 요청 가능
- **단점:** `get_args_schema()` 호출마다 SettingsManager I/O

## 결정 — 스키마

**옵션 B를 선택한다.**

## 근거

LLM에게 잘못된 타입을 노출하면 잘못된 차트 요청이 발생한다. `get_args_schema()`는 매 LLM 호출마다 실행되므로 엔진 전환 즉시 반영된다.

## 결과

- ECharts table: FE `EChartsBlock`에서 `config.option?.dataSource` 감지 후 React table로 렌더링 필요
- 엔진 전환 시 기존 대화 컨텍스트에 이전 스키마가 남을 수 있음 (새 대화 시작 권장)
- 팔레트 하드코딩 3곳 → 추후 공통 config로 추출 예정
