---
type: troubleshooting
project: project-nova
date: 2026-06-19
resolved: true
root-cause: "prep이 .eml 파일명 정렬 순서로 mail_id를 부여해, 같은 스레드가 동시 포워딩되면 파일명 알파벳순이 수신 시각순과 어긋나 채번이 뒤집힘"
related: [mail2task, 채번, run_pipeline, prep, batch, ingest]
tags: [mail2task, numbering, batch, ordering, prep]
---

# mail2task 배치 채번이 수신 시각순이 아니라 파일명순으로 매겨짐

> 대상: mail2task 스킬 `scripts/run_pipeline.py` (prep)
> 계열: 배치 채번/순서 버그 #3. 선행 — [[projects/project-nova/issues/batch-issue-numbering-duplicate|#1 중복 채번]], [[projects/project-nova/issues/batch-same-thread-new-our-reply-ordering|#2 new+our_reply 스레드 연결]].

## 채번 정의 (정본)

- **new** → 새 이슈 + 트래킹 1
- **customer_addition** → 기존 이슈 + 그 이슈 내 max 트래킹 +1
- **our_reply** → 기존 이슈·트래킹 재사용 (행 갱신)

같은 스레드의 초기본·업데이트본이 한 배치에 들어오면 **수신 시각이 빠른 쪽**이 트래킹 1, 늦은 쪽이 트래킹 2여야 한다.

## 증상

2026-06-19 EX 배치: 같은 "상품현황" 스레드 2건(초기본 13:43, 업데이트본 17:51)을 처리했더니 채번이 시간순과 반대로 뒤집힘.

```
이슈1·트래킹1 | 상품현황 업데이트본 (17:51)   ← 늦게 온 게 1번
이슈1·트래킹2 | 상품현황 초기본 (13:43)       ← 먼저 온 게 2번
```

기대: 초기본(13:43)=1-1, 업데이트본(17:51)=1-2.

## 환경

- **재현 조건:** 한 배치에 같은 스레드가 여러 통(초기본 + 업데이트/재전달). 특히 **동시에 포워딩**돼 `.eml` 파일명 앞부분(포워딩 타임스탬프)이 동일할 때.
- 이번 케이스: 두 파일명이 모두 `20260618_064813_…`로 시작 → 뒤 제목으로 알파벳 정렬되어 `FW_ 상품현황…(업데이트)`가 `상품현황…`보다 먼저 옴(영문 `F` < 한글).

## 시도한 것들

1. ❌ (즉시 대응) prep `--eml`에 초기본을 먼저 명시해 재처리 — 일회성, 재발 방지 안 됨.
2. ✅ prep이 **mail_id 부여 전에 수신 시각순으로 정렬**하도록 수정.

## 근본 원인

`list_emls()`가 `sorted(glob(...*.eml))` — **파일명 알파벳순**으로 목록을 만들고, prep 루프가 그 순서로 `mail_id = 1,2,…`를 곧장 부여했다. finish의 채번은 mail_id(=처리) 순서를 따르므로, 파일명순이 시간순과 어긋나면 트래킹 번호가 뒤집힌다.

받은 시각(`received_date`/`received_time`)은 **ingest를 해야** 알 수 있는데, 기존 루프는 ingest와 동시에 mail_id를 부여해 정렬 기회가 없었다.

> 관심사: 채번 *계산* = `triage.py` 정상. *처리 순서 결정* = `run_pipeline.py` (버그 #1·#2는 finish, 이번 #3은 prep의 mail_id 부여 단계).

## 해결 방법 (2026-06-19)

`scripts/run_pipeline.py` prep을 **2단계**로 분리(ingest는 메일당 1회 유지):

1. **ingest 먼저** 한 바퀴 — mail_id 없이 받은 시각만 확보.
2. `(빈 시각은 뒤, 받은날짜, 받은시각, 원래순서)` 키로 **stable sort** → 그 순서로 mail_id 부여·채번.

```python
ingested = []
for idx, eml in enumerate(emls):
    _, full_out, _ = run([INGEST, "--eml", eml, "--attachments-dir", att_dir, "--emit"])
    ingest_result = json.loads(full_out)
    state = jrun([PIPELINE, "--new", "--stdin"],
                 stdin=json.dumps(ingest_result["input"], ensure_ascii=False, indent=2))
    rd = str(state.get("received_date", "")).strip()
    rt = str(state.get("received_time", "")).strip()
    ingested.append((eml, ingest_result, state, rd, rt, idx))
ingested.sort(key=lambda t: (t[3] == "", t[3], t[4], t[5]))  # 빈 시각 뒤로, 동일 시각은 파일명순 유지

for i, (eml, ingest_result, state, recv_date, recv_time, _idx) in enumerate(ingested, 1):
    mid = str(i)
    ...  # 기존 처리(state 저장·첨부파싱·게이트·라우터·scan·dup) 그대로
```

## 검증

`.eml`을 **고의로 업데이트본 먼저**로 입력해도 정렬 후 mail_id가 시각순으로 잡힘:

```
입력 순서:  [업데이트본(17:51), 초기본(13:43)]
정렬 결과:  mail_id 1 = 초기본 13:43,  mail_id 2 = 업데이트본 17:51
```

실제 산출(task_EX.xlsx)도 초기본=1-1, 업데이트본=1-2로 보정 완료.

## 예방책 · 주의

- 같은 스레드 다건은 이제 prep이 **받은 시각순으로 자동 채번**. 파일명 타임스탬프(포워딩 시각)와 무관.
- **받은 시각이 같거나 비면** 파일명순(stable)으로 떨어진다 — 그 경우만 결과 점검.
- ingest를 2단계로 분리했지만 **메일당 ingest는 여전히 1회**(시각 확보용 1패스 + 처리 1패스로 나눈 게 아니라, 1패스 결과를 정렬 후 재사용).

## 관련 페이지

- [[projects/project-nova/issues/batch-issue-numbering-duplicate|배치 이슈번호 중복 채번 (#1)]]
- [[projects/project-nova/issues/batch-same-thread-new-our-reply-ordering|같은 배치 new+our_reply 스레드 채번 (#2)]]
- [[projects/project-nova/status|project NOVA 상태]]
