---
type: decision-record
project: dna-sql-agent
date: 2026-10-01
status: accepted
superseded-by: ""
tags: [settings, hot-reload, multi-worker]
---

# ADR-046: 설정 리로드 신호는 "설정 적용" 시점에만 쓴다

## 맥락

관리자 설정은 `ApplyMode` 로 즉시/설정 적용/재시작이 나뉘고, 서버 설계서에는 "저장과 적용을 분리한
의도된 동작"이라고 적혀 있다. 그런데 9/08 커밋(f41fc995)의 멀티 워커 전파 로직 때문에 저장만 해도
다음 요청에서 자동 적용됐다.

- 저장 API 가 리로드 스탬프(`.hot_reload_stamp`)를 씀
- 따라잡기 조건에 "자기 워커의 미적용 표식"과 "미적용 파일 설정"이 포함
- 화면은 저장 직후 `GET /pending` 을 부르고, 그 요청 앞단 미들웨어가 적용까지 실행 → "적용 필요" 배너가 보이지 않음

## 선택지

### 옵션 A: 저장 = 적용으로 확정하고 UI 의 적용 단계 제거
- **장점:** 코드 변경 최소
- **단점:** 여러 설정을 모아 한 번에 반영하는 설계 의도가 사라짐. 배너·문서 전면 수정

### 옵션 B: 신호 시점을 적용으로 옮기고 표식을 공유 파일로
- **장점:** 원래 설계 복원 + 멀티 워커 전파 유지
- **단점:** 신호 종류를 나눠야 함(프롬프트 캐시 무효화가 같은 신호를 쓰고 있었음)

## 결정

**옵션 B를 선택한다.**

- `.hot_reload_stamp` 는 `hot_reload()` 만 쓴다. 따라잡기는 스탬프가 이 워커의 마지막 적용 시각보다 새로울 때만
- DB 설정 미적용 표식은 워커 메모리 대신 `config/.pending_db_changes` 공유 파일. `hot_reload()` 가 삭제
- 시스템 프롬프트 수정·삭제는 별도 `.prompt_cache_stamp` 로 프롬프트 캐시만 비움

## 근거

- `_apply_reload()` 는 파일의 **현재 저장값**을 읽는다. 어떤 이유로든 리로드 신호가 나가면 저장만 해둔 설정까지 반영된다. 그래서 신호는 "적용" 의미 하나로만 쓴다
- 표식이 워커 메모리에만 있으면 멀티 워커에서 배너가 응답 워커에 따라 달라진다
- 2워커 시뮬레이션 6개 시나리오(저장·DB 저장·적용·프롬프트 변경·재기동)로 검증

## 결과

- 배포 후 관리자는 저장 뒤 "설정 적용"을 눌러야 반영된다(그동안 저장만으로 반영되던 것에 익숙한 사용자는 변화 체감)
- 요청이 없는 워커는 다음 요청 전까지 이전 설정 유지. 컨테이너를 늘리면 `DNA_CONFIG_DIR` 공유 필요
- 웹 배너 개선(ADR-017)과 함께 배포해야 의도대로 보임

## 참고 자료

- 백엔드 `docs/design/platform/server-settings-design.md` §9
- 웹: [[projects/dna-sql-agent-web/decisions/017-settings-banner-global-save-and-apply-hint]]
- [[knowledge/patterns/cross-worker-settings-signal-on-apply]]
