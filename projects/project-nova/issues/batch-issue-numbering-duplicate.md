---
type: troubleshooting
project: project-nova
date: 2026-06-19
resolved: true
root-cause: "오케스트레이터 finish 루프가 메일 간 채번 누적 상태를 전달하지 않음 (계산 로직 triage는 정상)"
related: [mail2task, 채번, triage, run_pipeline]
tags: [mail2task, numbering, batch, orchestration]
---

# mail2task 배치 처리 시 이슈번호 중복 채번 버그

> 대상: mail2task 스킬 `scripts/run_pipeline.py` (finish) · `stages/03-triage/scripts/triage.py`

## 채번 정의 (정본)

| 번호 | 의미 | 증번 기준 |
|------|------|----------|
| **이슈번호** | 성격별 고유 태스크 번호 (업무 단위) | 새 업무(new/mixed)마다 +1. our_reply·customer_addition은 기존 이슈 참조 |
| **트래킹번호** | 이슈 **내부의** 가지번호 (한 태스크의 부 태스크) | 같은 이슈 안에서만 +1. 단건이면 1 |

핵심: 트래킹은 **이슈에 종속**된다. 이슈마다 트래킹은 1부터 따로 센다.

성격별:
- **new** → 새 이슈 + 트래킹 1
- **customer_addition** → 기존 이슈 + 그 이슈 내 max 트래킹 +1 (새 행)
- **our_reply** → 기존 이슈·트래킹 재사용 (새 행 X, 기존 행 처리내용 갱신)

## 증상

`run_pipeline.py finish`를 여러 메일 배치로 실행하면, 서로 다른 신규 업무인데도 **모든 new 메일이 이슈번호 1로 동일하게 채번**됨.

```
이슈1·트래킹1 | 인포그래픽 오류
이슈1·트래킹1 | 예산 정합성     ← 별개 업무인데 이슈1 중복
이슈1·트래킹1 | 예측모델 보정    ← 별개 업무인데 이슈1 중복
```
(기대: 이슈 1·2·3 / 각 트래킹 1)

## 환경

- **재현 조건:** 한 배치에 `nature=new` 메일이 2건 이상. 2026-06-19 KAC 3건(윤혜영 발신)에서 발생.

## 시도한 것들

1. ❌ `triage.py`의 assign 수정 — 반영 안 됨. assign은 **한 호출 안에서는** 세그먼트마다 `next_issue += 1` 하지만, new는 메일당 세그먼트 1개라 증번 코드가 발동할 일이 없음.
2. ✅ 오케스트레이터(`run_pipeline.py`) finish 루프에 배치 채번 누적 추가.

## 근본 원인

finish 루프가 메일마다 `triage.py assign`을 **독립 호출**하면서, 각 호출에 **prep 시점의 고정 `scan`**(빈 시트면 `next_issue_no=1`)을 그대로 시드로 넘김. 앞 메일이 이슈 1을 발급했다는 누적 정보가 다음 호출로 전달되지 않아 매번 1로 리셋됨.

**`triage.py` assign 자체는 정상**이었고(호출 내 세그먼트 증번 + `_max_tracking_of`로 매칭 트래킹 처리), **메일 사이 누적을 이어주는 로직이 오케스트레이터에 없던 것**이 문제.

> **관심사 분리:** 채번 *계산·규칙* = `triage.py` (정본). 배치 내 scan *누적·전달* = `run_pipeline.py` finish (오케스트레이션). triage만 고쳐선 배치 버그를 못 잡는다.

## 해결 방법 (2026-06-19)

`scripts/run_pipeline.py` finish 루프 앞에 `batch_scan = {}`(proj별 누적 scan) 추가:

- **첫 메일:** prep scan 결과를 그대로 시드.
- **이후 메일:** assign이 돌려준 `next_issue_no_after`와 할당된 이슈/트래킹번호를 `batch_scan[proj]`에 되먹임 → 다음 메일이 이어받아 채번.

```python
bs = batch_scan.get(proj)
if bs is None:
    base_scan = rm.get("scan") or {}
    bs = {"exists": base_scan.get("exists", False),
          "next_issue_no": int(base_scan.get("next_issue_no") or 1),
          "issues": [dict(it) for it in (base_scan.get("issues") or [])]}
    batch_scan[proj] = bs
assign_in = {"nature": nature, "scan": bs}  # ← prep scan 대신 누적 scan
...
assign = jrun([TRIAGE, "assign"], stdin=...)
# 되먹임: 이번 할당을 batch_scan 에 반영
if assign.get("next_issue_no_after") is not None:
    bs["next_issue_no"] = max(int(bs["next_issue_no"]), int(assign["next_issue_no_after"]))
for seg in assign["segments"]:
    ino, tno = seg.get("issue_no"), seg.get("tracking_no")
    if ino is None: continue
    ino, tno = int(ino), int(tno or 1)
    ent = next((it for it in bs["issues"] if int(it.get("issue_no", -1)) == ino), None)
    if ent is None: bs["issues"].append({"issue_no": ino, "max_tracking": tno})
    else: ent["max_tracking"] = max(int(ent.get("max_tracking") or 0), tno)
    if ino >= int(bs["next_issue_no"]): bs["next_issue_no"] = ino + 1
```

**검증:** 같은 3건 new → 이슈 **1·2·3 / 각 트래킹 1** 정상.

## 예방책 · 주의

- **prep 1회 + finish 1회**가 정상 흐름. finish는 재스캔 안 하고 prep scan을 시드로만 쓴다.
- **same-batch our_reply:** ~~그 our_reply의 `matched_issue_no`를 미리 알 수 없으니 결과 점검~~ → 후속 버그 #2로 실제 어긋남이 확인돼 **코드로 해결**됨(new 우선 정렬 + 정규화 제목 스레드 자동 연결). [[projects/project-nova/issues/batch-same-thread-new-our-reply-ordering|버그 #2 문서]] 참조.
- **prep `--eml` 인자:** `nargs="*"` → 한 플래그 뒤에 경로 **나열**(`--eml a.eml b.eml`). 플래그를 반복하면 마지막 값만 남는다.
- **회신 초안 `recipient_title`:** 템플릿이 이름 뒤 "님"을 자동 추가 → `judgments.json`의 `recipient_title`에 "님"을 쓰면 "윤혜영님님" 중복. 비우거나 직책("대리"/"책임")만 입력.

## 관련 페이지

- [[projects/project-nova/issues/batch-same-thread-new-our-reply-ordering|같은 배치 new+our_reply 스레드 채번 (버그 #2)]]
- [[projects/project-nova/issues/batch-received-time-ordering|배치 채번 수신 시각순 정렬 (버그 #3)]]
- [[projects/project-nova/decisions/002-공통경로-로컬클라우드-타입|ADR-002 공통 경로 타입]]
- [[projects/project-nova/status|project NOVA 상태]]
