# my-wiki 운영 규칙

## 목적

이 위키는 Claude Code로 진행하는 모든 프로젝트의 지식을 축적하고 교차 참조하는 개인 지식 베이스이다.
LLM이 위키를 생성·관리하고, 인간은 소싱·탐색·의사결정에 집중한다.

## 3-Layer 구조

| Layer | 경로 | 소유자 | 설명 |
|-------|------|--------|------|
| Raw Sources | `raw/` | 인간 | 불변의 원본. LLM은 읽기만 한다 |
| Wiki | `projects/`, `knowledge/` | LLM | LLM이 생성·갱신·교차참조하는 합성 지식 |
| Schema | `_schema/` | 인간+LLM 공동 | 운영 규칙. 점진적으로 개선 |

## 프론트매터 규약

모든 위키 페이지에 YAML 프론트매터를 포함한다:

```yaml
---
type: <페이지 유형>        # 필수
created: YYYY-MM-DD       # 필수
updated: YYYY-MM-DD       # 필수
project: <프로젝트명>      # 프로젝트 관련 페이지만
tags: []                   # 선택
sources: []                # 근거 소스 링크
status: draft | stable     # 선택
confidence: high | medium | low  # 선택
---
```

### 페이지 유형 (type)

- `project-overview` : 프로젝트 개요 (진입점)
- `session-log` : Claude Code 작업 세션 기록
- `decision-record` : 아키텍처/기술 의사결정 (ADR)
- `troubleshooting` : 문제 해결 기록
- `tool` : 도구·라이브러리 지식
- `pattern` : 재사용 가능한 패턴·기법
- `source-summary` : 소스 요약
- `synthesis` : 주제별 종합 분석
- `query-result` : 질의 결과 보존

## 디렉토리 규약

```
projects/{project-name}/
├── overview.md              ← 프로젝트 진입점
├── architecture.md          ← 기술 스택, 구조 결정 종합
├── status.md                ← 현재 상태, 다음 할 일
├── decisions/               ← ADR (NNN-제목.md)
├── meetings/                ← 회의록 (YYYY-MM-DD 제목.md)
│   └── old/                 ← 정리 전 원본 메모 보관
├── sessions/                ← 세션 로그 (YYYY-MM-DD-주제.md)
├── issues/                  ← 문제 해결 기록
└── raw/                     ← 프로젝트 전용 원본·스냅샷
```

```
knowledge/
├── tools/                   ← 도구·라이브러리별 지식
├── patterns/                ← 반복 발견된 패턴·기법
├── troubleshooting/         ← 프로젝트 횡단 문제 해결
└── prompting/               ← Claude Code 프롬프팅 노하우
```

## 파일명 규칙

- 모든 파일·폴더: **kebab-case**
- 세션 로그: `YYYY-MM-DD-주제.md`
- ADR: `NNN-제목.md` (순번 3자리, 예: `001-nextjs-over-remix.md`)
- 날짜 형식: `YYYY-MM-DD`

## 교차 참조 규칙

- Obsidian wikilink 형식: `[[경로|표시명]]`
- 기술/도구가 **처음** 언급될 때 `knowledge/tools/` 해당 페이지로 링크
- 동일 문제가 **2개 이상** 프로젝트에서 발생하면 `knowledge/troubleshooting/`에 통합 페이지 생성
- 고아 페이지(인바운드 링크 0개)가 발견되면 lint 시 보고

## 충돌 처리 정책

새 소스가 기존 위키 내용과 모순될 때:
1. 해당 페이지에 `> [!warning] 충돌` 콜아웃을 추가
2. 양쪽 소스를 병기
3. `confidence` 필드를 조정
4. log.md에 충돌 발견을 기록

## 핵심 Operations

### Ingest (소스 처리)
1. 새 소스를 `raw/`에 저장 (원본 불변)
2. 소스 요약 페이지 생성
3. 관련 기존 페이지 갱신 (엔티티, 컨셉, 도구 등)
4. `_meta/index.md` 갱신
5. `_meta/log.md`에 기록

### Query (질의)
1. `_meta/index.md`로 관련 페이지 탐색
2. 관련 페이지를 읽고 종합 답변 생성
3. 보존 가치가 있는 답변은 위키에 새 페이지로 저장

### Lint (건강 점검)
주기적으로 확인할 항목:
- 고아 페이지 (인바운드 링크 없음)
- 갱신 필요한 오래된 페이지
- 언급되었지만 자체 페이지가 없는 개념
- 태그 일관성
- 교차 참조 누락
- 빈 프론트매터 필드

## 소스 신뢰성 규칙

- 모든 위키 페이지의 `sources` 필드 필수
- 소스에 명시적으로 나온 내용만 위키에 작성
- 추론/해석은 `> [!note] 해석` 콜아웃으로 구분
- `confidence` 필드로 확신 수준 표시
