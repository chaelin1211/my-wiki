---
type: session-log
project: dna-sql-agent-web
date: 2026-10-01
duration: 2일 (2026-09-30 ~ 2026-10-01)
focus: "개인 데이터셋 관리 화면 정리·지식화 상태 안정화, 관리자 설정 저장/적용 흐름 바로잡기"
tools-used: [claude-code]
outcome: success
---

# 2026-10-01 — 개인 데이터셋 관리 정리와 관리자 설정 저장·적용 흐름

## 목표

- PR #96(개인 데이터셋 업로드) 이후 남은 화면·동작 문제 정리
- 개인 데이터셋 지식화(벡터화) 단계 표시가 실제 상태와 어긋나는 원인 규명
- 관리자 화면에서 개인 데이터셋이 노출되는 문제 해결
- 관리자 설정 "저장 → 적용" 흐름이 의도대로 동작하는지 점검

## 수행한 작업

1. **채팅 헤더** — PR #96에서 `ml-auto` 가 빠져 북마크 버튼이 제목 옆으로 밀린 사이드이펙트 복구. 분석보고서 버튼 `title` → 하단 툴팁. 공통 툴팁 꼬리에 테두리 추가
2. **데이터셋 관리 다이얼로그** — 앱 톤앤매너로 스타일 통일(`*-500/10` 상태색, 다크 모드, 이모지 제거), `map` 내부 `useState` 훅 위반 분리, 단계 칩 상태(진행 중 스피너·완료·대기·실패·취소) 구분, 구축 중 테이블 삭제 차단(프론트 비활성 + 백엔드 409), 목록 제목 고정
3. **지식화 상태 (백엔드)** — 이번 실행 job만 응답(최근 `doc_table` 생성 시각 기준), `relation_info` job 사전 생성, 중단 시 남은 pending 정리, 관계 FAQ SQLite 스레드 오류·검증 쿼리 타임아웃, 업로드/재구축 진입점 통일(이전 실행 취소 → 관계 정보 취소 플래그 초기화 → 새 실행)
4. **관리자 화면 개인 데이터셋 제외** — `connections.owner_user_id` 추가(기존 6건 해시로 채움), 목록 API `exclude_personal`, 사용자 시스템 권한 API 제외
5. **관리자 목록 검색·정렬 복구** — PR #160 머지에서 빠진 `/connections/paged`·`/systems/paged` 의 `search`·`sort` 복구, 권한 시스템 목록 이름순 정렬
6. **관리자 설정** — 저장만 해도 자동 적용되던 문제 수정(백엔드), 배너 버튼 4개(전체 저장·설정 리셋 │ 설정 적용·재시작)로 정리, 전체 탭 기준 저장/리셋, RAG 카드별 변경 점, 미저장 변경의 반영 방식 안내(※, 경고색)
7. **문서** — 백엔드 `architecture-review.md`(개인 데이터셋 구분·지식화 흐름·재시작 제약·사용자 비활성화 시 보존 정책), `server-settings-design.md` §9(저장 → 적용 흐름, 멀티 워커 전파), `settings-ui-design.md` §10(배너·에러 처리 현행화)
8. **PR** — 백엔드 #170(머지), #172(관계 FAQ SQLite·재구축 실패), 웹 #97. 설정 관련 백엔드 `fix/settings-apply-timing`·웹 `refactor/settings-save-banner` 는 push 전

## 핵심 결정

- **개인 데이터셋 구분은 `connections.owner_user_id`** — 이름 prefix(`sqlite-`)는 관리자 등록 BIRD 연결 11건과 겹쳐 사용 불가
  → ADR: [[projects/dna-sql-agent/decisions/045-connections-owner-user-id-personal-dataset]]
- **설정 리로드 신호는 "적용" 시점에만** — 멀티 워커 전파용 신호를 저장 시점에 쓰면 저장=적용이 되어 2단계 설계가 무너짐
  → ADR: [[projects/dna-sql-agent/decisions/046-settings-reload-signal-on-apply-only]]
- **설정 배너는 전체 탭 기준 단일 저장 + 반영 방식 안내** — 변경 표시는 전역인데 저장이 탭 단위라 놓치던 문제
  → ADR: [[decisions/017-settings-banner-global-save-and-apply-hint]]
- **서버 재시작 시 고아 job 자동 정리는 보류** — 단일 프로세스에선 안전하지만 멀티 워커·롤링에선 살아 있는 작업까지 취소. 생존 판단(하트비트) 구조 개선 때 함께 처리, 문서에 제약으로 기록

## 배운 것

- 상태를 "시스템 단위"로만 저장하면 실행끼리 독립성이 없다(취소 플래그·최근 job 조회·관계 정보 결과). 실행 ID가 근본 해법
- `run_mode` 는 실행 종류일 뿐 실행 식별자가 아니다. 값 프로파일링 자동 실행은 job 이 아닌 관계 정보 기록의 `run_mode` 로 판단
- 전역 워커 루프(`Orchestrator.start()`)는 코드상 기동하는 곳이 없다. 실행 주체는 요청 프로세스의 메모리 태스크뿐
- 운영 배포는 단일 프로세스(`python src/main.py`, uvicorn 워커 1개). 코드 주석·옛 설계 문서의 "gunicorn 멀티 워커" 전제를 그대로 믿지 말고 배포 설정으로 확인할 것
- 화면에 `running` 스피너가 보여도 실제 실행 중인지는 `updated_at`·진행률 갱신으로 확인해야 한다

## 문제 & 해결

- **문제:** 관계 FAQ 생성 시 `SQLite objects created in a thread can only be used in that same thread`
  **원인:** 이벤트 루프 스레드에서 연 연결을 보조 스레드에서 사용 + SQLite 는 DB 단 타임아웃 없음
  **해결:** `check_same_thread=False` + progress handler 타임아웃
  → 이슈: [[projects/dna-sql-agent/issues/relation-faq-sqlite-cross-thread]]
- **문제:** 취소 후 파일 업로드로 다시 구축하면 관계 정보가 시작도 못 하고 실패
  **원인:** 메모리 취소 플래그가 업로드 경로에서 초기화되지 않음
  **해결:** 진입점 통일
  → 이슈: [[projects/dna-sql-agent/issues/stale-relation-info-cancel-flag-on-upload-rebuild]]
- **문제:** 관리자 설정이 저장만 해도 적용됨
  → 이슈: [[projects/dna-sql-agent/issues/settings-auto-applied-on-save]]
- **문제:** 관리자 연결·시스템 목록 검색·정렬 미동작
  → 이슈: [[projects/dna-sql-agent/issues/admin-list-search-sort-lost-in-merge]]
- **문제:** 채팅 헤더 북마크 버튼 위치 변경
  → 이슈: [[issues/chat-header-bookmark-shifted-by-dataset-pr]]

## 다음 할 일

- [ ] 백엔드 `fix/settings-apply-timing`(3커밋)·웹 `refactor/settings-save-banner`(3커밋) push 후 PR, 서로 `## 관련` 링크 (함께 배포 필요)
- [ ] PR #172 리뷰·머지 후 서버 재시작으로 실제 업로드 → 취소 → 재업로드 흐름 확인
- [ ] 관계 정보가 실제로 실패하면 관계 FAQ 건너뛰기 (한 줄 수정, 미반영)
- [ ] 지식화 실행 ID(`run_id`) + DB 기준 취소 + 실제 멈춤 대기 구조 개선 (관리자 "모두 시작"과 체인 통합 검토)
- [ ] 개인 데이터셋 값 프로파일링 미실행(관계 정보 기록 `run_mode` 미설정) 의도 확인
- [ ] 설정 `PATCH` Pydantic 검증 실패가 500 으로 응답 → 422 + 읽을 수 있는 detail
- [ ] `get_table_info` 가 상태 조회마다 전 테이블 `COUNT(*)` — 폴링 부하 개선
- [ ] 관계 FAQ 가 Qdrant 에서 `doc_column` 을 못 찾아 extractor fallback 을 탄 원인 확인
- [ ] PR #160 머지에서 다른 기능도 되돌아갔는지 점검

## 효과적이었던 프롬프트

```
"면밀히 검토 해봐 그런 오류들은 안 일어나는데? 재현 방법대로 해도"
→ 코드상 가능성을 실제 발생처럼 과장한 목록을 재현성·가시성 기준으로 재분류하게 만듦
```

```
"아니 너가 생각해봐 멀티 워커면 문제가 되겠니 안 되겠니"
→ "시작 시각 이전 job = 죽은 job" 이 단일 프로세스에서만 성립한다는 전제를 드러냄
```
