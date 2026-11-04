---
type: decision-record
project: dna-sql-agent
date: 2026-10-08
status: accepted
superseded-by: ""
tags: [tools, admin, i18n, config]
---

# ADR-047: 도구 표시명은 dna 쪽 고정 enum 한 곳에서 관리

## 맥락

채팅 카드는 도구를 한글명("쿼리 실행")으로 보여주는데, 관리자 도구 접근 제어 표는 `tool_access.json` 의 키인 영어 클래스명(`ValidatedRunSqlTool`)을 그대로 보여줬다. 한글 매핑은 `dadap` 의 `agent.py` 에 `TOOL_DISPLAY_NAMES` 로 있었고, 키가 도구 이름(`run_sql`)이라 관리자 화면에서는 쓸 수 없었다. 영어 식별자가 클래스명과 도구 이름 두 벌인 상태다.

요구는 "표시명은 오로지 한 곳에서 관리"였고, 설정(운영자가 바꾸는 값)과 표시명(바꾸지 않는 고정 문구)은 성격이 다르다.

## 선택지

### 옵션 A: `tool_access.json` 스키마에 `display_name` 필드 추가
- **장점:** 관리자 화면이 이미 받는 설정 응답에 같이 실려 옴.
- **단점:** 설정 파일은 서버마다 복사본이 생겨 실제로는 여러 벌. 문구를 바꿀 때마다 마이그레이션 필요. 운영자가 바꾸는 설정에 고정 문구가 섞임.
- **비용/노력:** 스키마·기본값·마이그레이션 수정.

### 옵션 B: 각 도구 클래스에 `display_name` 클래스 변수
- **장점:** 도구를 만들 때 표시명도 같은 자리에서 정함.
- **단점:** `dadap`(공통 프레임워크)의 `Tool` 기본 클래스에 서비스 문구용 필드가 들어감. 표시명이 파일마다 흩어짐. 꺼진 도구는 인스턴스가 없어 클래스를 따로 찾아야 함.
- **비용/노력:** 기본 클래스·도구 클래스 전부 수정, `TOOL_CLASS_MAP` 정리.

### 옵션 C: `dna` 쪽 별도 enum (키는 설정 키)
- **장점:** 한 파일에서 전부 보임. 서비스 문구가 서비스 계층에만 있음. 관리자 API는 enum만 돌면 됨. 설정과 분리.
- **단점:** 도구를 추가할 때 enum에도 한 줄 넣어야 함(빠뜨리면 영어 이름이 그대로 보일 뿐 깨지지 않음).
- **비용/노력:** enum 모듈, 조회 API, 에이전트에 조회 함수 주입.

## 결정

**옵션 C를 선택한다.** `src/dna/tools/display_names.py` 의 `ToolDisplayName` enum. 키는 `tool_access.json` 설정 키(클래스명), 값은 한글 표시명이다.

## 근거

- 표시명은 고정 문구라 운영 설정과 분리해야 하고, 실제 복사본이 하나여야 한다. A는 복사본이 서버마다 생긴다.
- 서비스 문구는 서비스 계층(`dna`)에 둬야 한다. B는 프레임워크에 문구를 넣는다.
- 키를 클래스명으로 두면 도구 이름(`run_sql`)을 enum에 다시 적지 않아도 된다. 채팅은 등록된 도구에서 클래스명을 얻어 같은 enum을 찾는다.

## 결과

- 채팅 카드: `dadap` 에이전트는 `tool_display_name_resolver` 를 주입받고, `dna/agent_service.py` 가 도구 이름 → 클래스명 → enum으로 찾는다. `dadap` 이 `dna` 를 직접 import하지 않는다.
- 관리자 화면: `GET /api/v1/settings/tool-display-names` 로 받아 한글명 + 작은 클래스명 표시. 설정 응답에 섞지 않는 것은 웹이 설정을 그대로 되돌려 저장하기 때문(섞으면 다시 설정 파일에 복사본이 생김).
- 기본 설정의 도구가 enum에서 빠지면 `test_every_default_tool_has_display_name` 이 실패.
- 영어 식별자 두 벌(클래스명, 도구 이름) 자체는 그대로다. 합치려면 설정 파일과 그룹 권한 데이터 마이그레이션이 필요해 범위 밖.

## 참고 자료

- 세션: [[projects/dna-sql-agent/sessions/2026-10-12-tool-display-name-map-region-widget-refresh-error]]
- PR: 백엔드 #176, 웹 #101
