---
type: workflow
project: project-nova
created: 2026-06-19
updated: 2026-06-19
---

# mail2task — 현재 워크플로우 (구현 기준)

> 초기 PoC 구상([[projects/project-nova/architecture|architecture]] — n8n·GitLab 이슈)에서
> **Claude Code 스킬 기반 파이프라인**으로 구현 방향이 바뀐 현재 상태를 정리한다.
> 산출물은 GitLab 이슈가 아니라 `task_<코드>.xlsx`(Task/Log 시트) + 회신초안 `.txt`이며,
> AI는 **확정하지 않고 Task 후보만** 만들고 사람이 검토 후 등록·발송한다.

## 스킬 구성

| 스킬 | 역할 |
|------|------|
| **mail2task** | 오케스트레이터. 메일 입력을 받아 흐름(00~06)을 순서대로 제어·실행 |
| **mail2task-config** | 프로젝트 `config_<코드>.yml`·공통경로 `mail2task_paths.yml` 생성/수정/삭제 |

- 흐름 정의 정본: `assets/flow.yml` · 계약(파일명·표·경로): `assets/interface.md` · 용어: `assets/glossary.md`
- 각 단계의 *판단*은 `stages/NN-<이름>/STAGE.md`에 위임, 오케스트레이터는 **흐름·분기·전달·취합**만 담당.

## 파이프라인 (00 → 06)

```
[전제] 설정      mail2task-config 로 config_<코드>.yml·공통경로 1회 세팅 (메일마다 X)
 00 인입·정규화   .eml 파싱·FWD 분리·히스토리 제외·demo/pilot 고정 → state.json 생성
 01 보안 게이트    차단키워드 검사 → 차단(중단) / 검토(되묻기) / 통과
 02 프로젝트 분류  발신도메인·서명기관·키워드·말머리로 프로젝트 판정 (신뢰도 표기)
 03 메일 구분·채번  성격 판정 + 메타 추출 + 이슈/트래킹 채번 + 라우팅
   ├ new/customer_addition/mixed → 04 로
   └ our_reply (우리측 Reply)     → 05 로 점프 (04 건너뜀)
 04 업무 정의      업무단위·중/소분류·우선순위·담당자·요약 (첨부 연결)
 05 질문·회신 초안  모호점·명확화 질문·메일요약·회신 초안
 06 아웃풋         task_<코드>.xlsx(Task/Log) + 회신초안 txt 저장
```

### 단계별 요점

| 단계 | 입력 | 핵심 판단 | 산출(state 섹션) |
|------|------|----------|-----------------|
| 00 ingest | `.eml`/텍스트/이미지 | (코드) 헤더·본문·첨부·FWD 분리, mode 고정 | `input` |
| 01 gate | 본문·첨부 | 비업무 노이즈(광고·스팸·피싱) 차단 / 업무 민감어(견적·예산 등)는 통과 | `security` |
| 02 router | 발신·서명·키워드 | 프로젝트 식별 (단서 약하면 추정+신뢰도↓) | `project` |
| 03 triage | input·첨부 | 성격(new/our_reply/customer_addition/mixed)·메타·**채번** | `triage` |
| 04 define | input·첨부 | 업무단위·중/소분류·우선순위·담당자·요약 | `define` |
| 05 respond | input·첨부 | 모호점·질문·회신 초안 | `reply` |
| 06 output | 누적 state | (코드) 시트 행 작성·회신 txt 생성·저장 | `output` |

## 채번 규칙 (03-triage)

> 자세히: [[projects/project-nova/issues/batch-issue-numbering-duplicate|배치 채번 이슈]]

| 번호 | 의미 | 증번 |
|------|------|------|
| **이슈번호** | 성격별 고유 태스크 번호 (업무 단위) | new/mixed마다 +1 |
| **트래킹번호** | 이슈 **내부** 가지번호 | 같은 이슈 안에서만 +1, 단건이면 1 |

- **계산은 triage** (`triage.py` scan→assign), **배치 내 누적은 오케스트레이터** (`run_pipeline.py` finish의 `batch_scan`).
- 채번은 메일만 보고 매기지 않고 **실제 `task_<코드>.xlsx`를 scan**해 계산한다.

## 실행 경로

### 빠른 경로 (권장) — `scripts/run_pipeline.py`
결정론 글루를 **두 번의 호출**로 관통, LLM 판단은 **한 패스**.

```bash
# ① prep — ingest·첨부·키워드게이트/라우터·scan → judgment_request.json
python scripts/run_pipeline.py prep --run-id <id> --config-dir "<Config>" \
    --eml <f1> <f2> ... --paths <mail2task_paths.yml> --dest-path "<Task_List>"
# ② LLM 판단(도구 0): judgment_request 읽고 judgments.json 작성 (메일당 1개)
# ③ finish — 판단을 build·merge·06-output 에 먹임
python scripts/run_pipeline.py finish --run-id <id> --judgments /tmp/m2t/<id>/judgments.json
```
- `--config-dir`는 워크터 밖. `--dest-path`는 채번 정확도에 필수(실제 시트 scan).
- `--eml`은 `nargs="*"` → **한 플래그 뒤 경로 나열**(반복하면 마지막만).

### 수동 경로 (단계별)
빠른 경로가 막히거나 단일 단계만 손볼 때 `--plan` → `--workdir` → 00 ingest → 01~06 단계별 실행.

## 입력 소스 우선순위 (입력 미지정 시)
1. 인자/`/mnt/user-data/uploads`의 `.eml`·텍스트
2. **`mail2task_paths.yml`의 `eml_inbox` 폴더** 루트 미처리 `.eml` (`_done/`·첨부·.DS_Store 제외)
3. 둘 다 없을 때만 사용자에게 되묻기

처리 완료 후 입력 `.eml`은 `_done/`으로 이동(차단/검토 건은 남김).

## 저장 (06-output)
- 위치 정본: `mail2task_paths.yml` (6키: config·task_results·reply_drafts·except_results·logs·eml_inbox).
- 키별 `type: local|cloud` — local은 마운트 경로 직접 in-place 쓰기, cloud는 드라이브 업로드.
  (→ [[projects/project-nova/decisions/002-공통경로-로컬클라우드-타입|ADR-002]])
- `task_<코드>.xlsx`: Task 시트(채번·분류·담당자·우선순위·Task·요약) + Log 시트(날짜·제목·발신·요약).
- 회신은 드라이브 `.txt` 초안으로만 (Gmail 초안 자동 생성 안 함).

## 원칙
1. 판단은 단계 문서에 위임, 흐름·분기·전달·취합은 오케스트레이터.
2. 흐름은 데이터 — 단계 정의·순서는 `flow.yml`. 미개발 단계는 건너뛰고 보고.
3. **AI는 후보만** — 사람 검토 없이 운영 등록·메일 발송·권한 변경 금지. `처리내용(수기등록)`·`완료여부` 빈칸.
4. 보고는 핵심만 (프로젝트/분류/담당자/우선순위/업무단위/모호점/회신/산출물).
5. 도구 호출 최소화 · 되묻는 곳은 게이트 soft 검토 단 하나.

## 관련 페이지
- [[projects/project-nova/architecture|아키텍처(초기 PoC 구상)]]
- [[projects/project-nova/decisions/002-공통경로-로컬클라우드-타입|ADR-002 공통경로 타입]]
- [[projects/project-nova/issues/batch-issue-numbering-duplicate|배치 채번 이슈]]
- [[projects/project-nova/status|프로젝트 상태]]
