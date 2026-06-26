---
type: troubleshooting
project: project-nova
date: 2026-06-19
resolved: true
root-cause: "finish 채번 루프가 요청 순서대로 처리해 our_reply가 같은 스레드 new보다 먼저 돌면, our_reply의 추정 matched_issue_no가 batch_scan을 오염시킴"
related: [mail2task, 채번, our_reply, run_pipeline, batch]
tags: [mail2task, numbering, batch, our_reply, orchestration]
---

# mail2task 같은 배치 new + our_reply 스레드 채번 어긋남

> 대상: mail2task 스킬 `scripts/run_pipeline.py` (finish)
> 선행: [[projects/project-nova/issues/batch-issue-numbering-duplicate|배치 이슈번호 중복 채번 버그]] (버그 #1). 그 문서가 미해결 주의로 남긴 "same-batch our_reply 결과 점검"이 바로 이 버그(#2).

## 채번 정의 (정본)

- **new** → 새 이슈 + 트래킹 1
- **customer_addition** → 기존 이슈 + 그 이슈 내 max 트래킹 +1
- **our_reply** → 기존 이슈·트래킹 재사용 (새 행 X, 기존 행 처리내용 갱신)

같은 스레드의 고객 요청(`new`)과 우리측 회신(`our_reply`)이 **한 배치에 함께** 들어오면, our_reply는 그 new가 만든 이슈·트래킹을 가리켜야 한다.

## 증상

2026-06-19 KAC 배치: 같은 스레드 "디지털정보 UI/UX 준수 체크리스트"의 고객 요청(new)과 모비젠 회신(our_reply)을 함께 처리했더니

```
new (요청)      → 이슈 6·트래킹 1   ← 5를 건너뛴 갭 발생
our_reply (회신) → 이슈 5·트래킹 1 갱신 시도 → updates_applied=0 (해당 행 없음)
```

기대: 둘 다 **같은 이슈·트래킹**, our_reply가 그 행의 처리내용(LLM)을 갱신. 실제로는 이슈번호가 어긋나고 회신 처리이력이 누락됨.

## 환경

- **재현 조건:** 한 배치에 같은 스레드의 `new`(또는 customer_addition)와 `our_reply`가 함께 있고, 그 our_reply가 **아직 시트에 없는** 이슈(= 같은 배치 new가 만들 이슈)를 참조.
- 빠른경로 `prep` → `finish` 흐름.

## 시도한 것들

1. ❌ (즉시 대응) 시트를 손으로 정정 — 이슈 6→5 되돌리고 처리내용 채움. 일회성, 재발 방지 안 됨.
2. ✅ `run_pipeline.py` finish에 **처리 순서 정렬 + 스레드 자동 연결** 추가.

## 근본 원인

`finish`의 **출력 루프**는 이미 new를 our_reply보다 먼저 정렬(같은 이슈 행을 선생성하려고)했으나, **채번을 결정하는 assign 루프는 요청 순서대로** 돌았다.

요청 순서가 우연히 `[our_reply, new]`였던 탓에:
1. our_reply가 먼저 처리됨. LLM이 추정한 `matched_issue_no`(아직 안 만들어진 이슈를 가리킴)를 assign에 넘김.
2. assign이 그 번호를 실재 이슈로 보고 `batch_scan`에 등록 → `next_issue_no`를 끌어올림.
3. 뒤이어 new가 그 다음 번호로 밀려 채번됨 (둘이 어긋남).
4. 출력 단계에서 our_reply는 자신이 가리킨(존재하지 않는) 이슈 행을 못 찾아 `updates_applied=0`.

> 관심사: 채번 *계산* = `triage.py` 정상. 배치 내 **처리 순서·스레드 연결** = `run_pipeline.py` finish 책임. 버그 #1과 같은 계열(오케스트레이터 누적/순서 누락).

## 해결 방법 (2026-06-19)

`scripts/run_pipeline.py` 3곳 수정:

**1. 정규화 제목 헬퍼** — Re:/Fwd:/FW: 접두어(반복)·공백 제거 + 소문자.

```python
def _norm_subj(s):
    import re
    s = (s or "").strip()
    while True:
        m = re.match(r'^\s*(re|fwd|fw|답장|전달)\s*[:：]\s*', s, re.I)
        if not m: break
        s = s[m.end():]
    return re.sub(r'\s+', '', s).lower()
```

**2. 채번 루프도 new 우선 정렬** (출력 루프와 동일):

```python
def _assign_order(item):
    _mid, _rm = item
    return 1 if (jmap.get(_mid) or {}).get("nature") == "our_reply" else 0
for mid, rm in sorted(rmap.items(), key=_assign_order):
```

**3. 스레드 자동 연결** — new가 실제 할당받은 (이슈,트래킹)을 정규화 제목으로 기록하고, 같은 배치 our_reply는 LLM 추정 대신 이 맵으로 강제 연결:

```python
batch_threads = {}  # proj -> {정규화제목: (issue_no, tracking_no)}
# (our_reply) assign 전:
ov_issue = jm.get("matched_issue_no"); ov_track = jm.get("matched_tracking_no")
if nature == "our_reply":
    linked = batch_threads.get(proj, {}).get(_norm_subj(inp.get("subject", "")))
    if linked: ov_issue, ov_track = linked
# (new/customer_addition) assign 후:
if nature in ("new", "customer_addition") and segs:
    sn = _norm_subj(inp.get("subject", ""))
    if sn: batch_threads.setdefault(proj, {})[sn] = (segs[0]["issue_no"], segs[0]["tracking_no"])
```

## 검증

빈 시트 기준 회귀 — our_reply의 `matched_issue_no`를 **고의로 틀린 5**로 넣어도:

```
new (요청)      → 이슈 2·트래킹 1   (행 추가)
our_reply (회신) → 이슈 2·트래킹 1   (updates_applied=1, 처리내용 반영)
```

둘이 같은 이슈로 정렬·연결되고 갭 없음. 처리 순서도 new → our_reply로 정렬됨.

## 예방책 · 주의

- 같은 배치 동일 스레드 new+our_reply는 이제 **코드가 자동 연결**(정규화 제목 매칭). judgments의 our_reply `matched_issue_no`가 빗나가도 보정된다.
- **과거 이슈를 참조하는 our_reply**(이번 배치에 new 없음)는 종전처럼 LLM `matched_issue_no` 사용 — 영향 없음.
- 한 배치에 **제목이 같은 서로 다른 스레드**가 섞이면 오연결 가능(희박). 그 경우만 결과 점검.

## 관련 페이지

- [[projects/project-nova/issues/batch-issue-numbering-duplicate|배치 이슈번호 중복 채번 (버그 #1)]]
- [[projects/project-nova/issues/batch-received-time-ordering|배치 채번 수신 시각순 정렬 (버그 #3)]]
- [[projects/project-nova/issues/fwd-sender-our-reply-misclassification|FWD 회신을 고객 요청으로 오인]]
- [[projects/project-nova/troubleshooting/mail2task-re-mail-our-reply-misdetection|Re 메일 our_reply 오판정]]
- [[projects/project-nova/status|project NOVA 상태]]
