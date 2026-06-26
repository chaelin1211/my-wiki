---
type: troubleshooting
project: project-nova
date: 2026-06-19
resolved: true
root-cause: "FWD 메일의 input.sender가 인용된 원문 발신자(고객)라, 본문 서명이 우리측인 회신을 sender만 보고 고객 요청으로 오인"
related: [mail2task, triage, nature, our_reply, FWD]
tags: [mail2task, triage, nature, classification, fwd]
---

# mail2task FWD 회신을 고객 요청으로 오인 (our_reply 미인식)

> 대상: mail2task 스킬 `stages/03-triage/STAGE.md` (성격 판정) · `SKILL.md` (빠른 경로 판단)

## 증상

2026-06-19 KAC 배치 처리 중, **모비젠이 보낸 회신 메일**("Re: 디지털정보 UI/UX 준수 체크리스트 관련")을 **고객의 신규 요청으로 오인**해 별도 이슈를 새로 만들었다.

```
이슈5-1 | UI/UX 체크리스트 점검·증적   ← 고객(김강우) 원 요청 (정상)
이슈5-2 | UI/UX 체크리스트(xlsx) 점검   ← 우리(이광진) 회신인데 새 행으로 중복 생성 ❌
```
(기대: 이슈5 한 건 + 우리 회신은 그 행의 처리내용 갱신)

## 환경

- **재현 조건:** 전달(FWD)된 `.eml` 중 우리측이 보낸 회신. 한 스레드의 원 요청(고객)과 우리 회신을 한 배치에 함께 받았을 때.
- 같은 건: 메일6(우리 회신, 제목 `Re:`, 본문 서명 `이광진 / 모비젠 DX개발2팀`) vs 메일7(고객 김강우 원 요청).

## 근본 원인

00-ingest가 뽑은 `input.sender`가 **실제 작성자가 아니라 전달 안에 인용된 원문 헤더의 발신자**(원 요청 고객)로 찍혔다. 성격 판정이 `sender` 도메인을 주신호로 보다 보니, 본문 서명은 우리측(모비젠 도메인)이고 제목이 `Re:`인데도 **고객 발신 = 고객 요청**으로 판정해 `new`/`customer_addition`이 됐다.

> `sender` 도메인과 **본문 끝 서명 도메인이 엇갈리는데** sender만 신뢰한 것이 화근. FWD 메일에선 sender가 실제 작성자를 보장하지 않는다.

## 해결 방법 (2026-06-19)

성격 판정 단서에 "FWD 시 sender보다 서명 우선" 규칙을 추가. 단계 문서와 빠른 경로 두 곳 모두에 반영(빠른 경로는 STAGE.md를 읽지 않으므로).

- **`stages/03-triage/STAGE.md`** — "발신자 도메인" 단서에 한 문장:
  > FWD 메일은 `input.sender`가 인용된 원문 발신자(고객)일 수 있으니 **본문 끝 서명 도메인과 엇갈리면 서명(실제 작성자)을 우선** — `Re:`+서명이 우리측이면 회신을 고객 요청으로 오인하지 않는다.
- **`SKILL.md`** 빠른 경로 ② 판단 단계 — 같은 취지 한 문장:
  > ★ `nature`: FWD 메일은 `sender`가 인용된 고객 발신자일 수 있으니 서명 도메인과 엇갈리면 서명을 우선 — `Re:`+우리측 서명이면 `our_reply`로 묶고 새 이슈로 만들지 않는다.

**판정 규칙 요약**

| 신호 | 판정 |
|------|------|
| `sender`=우리 도메인 | 우리측(our_reply 후보) |
| `sender`=고객, **서명=우리 도메인** | **서명 우선 → 우리측 회신** (sender는 인용된 원문) |
| 제목 `Re:`/`회신` + 본문이 "처리·답" 어투 | our_reply 강한 신호 |

**검증:** 같은 7건 재처리 → 메일7=`new`(이슈5), 메일6=`our_reply`(이슈5-1 처리내용 갱신). 중복 이슈5-2 사라지고 Task 5행/Log 7행 정상.

## 예방책 · 주의

- **same-batch 순서 주의:** our_reply가 자기 이슈를 만드는 new보다 mail_id가 작으면, finish 루프(낮은 id 먼저)가 회신을 먼저 처리해 채번이 밀린다. → 판단요청의 메일 배열에서 **원 요청을 회신 앞으로 재배치**하거나, prep `--eml` 입력 순서를 원 요청 우선으로 둔다.
- 본문 서명이 요청문처럼 보여도(전달·정리 어투) 작성자가 우리측이면 our_reply다. **요청문 여부보다 작성자 도메인**을 본다.

## 후속 — 구조적 해결

이 문서의 "서명 우선" 규칙은 **판단 레이어 밴드에이드**다. 근본은 ingest가 demo FWD에서 `top_comment`(이번 턴)를
버리고 `body_main`(옛 메일)만 `input.body`로 쓰는 데이터 손실이다. 이를 "두 턴 보존 + 최신 턴 기준"으로 고치는
설계 결정: [[projects/project-nova/decisions/003-fwd-두턴-보존-최신턴-기준|ADR-003]].

## 관련 페이지

- [[projects/project-nova/decisions/003-fwd-두턴-보존-최신턴-기준|ADR-003 FWD 두 턴 보존 + 최신 턴 기준]]
- [[projects/project-nova/issues/batch-issue-numbering-duplicate|배치 이슈번호 중복 채번 버그]]
- [[projects/project-nova/status|project NOVA 상태]]
