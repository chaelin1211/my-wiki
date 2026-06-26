---
type: troubleshooting
project: mail2task
date: 2026-06-19
resolved: true
root-cause: "triage scan이 Task 시트만 읽고 Log 시트를 참조하지 않아 이미 처리된 메일이 prep 단계를 통과함"
related: []
tags: [mail2task, dedup, log-sheet, triage]
---

# Log 시트에 기록된 메일이 중복 처리됨

## 증상

`eml_inbox`에 이미 처리된 `.eml`과 동일한 메일제목·발신인·날짜를 가진 파일이 남아 있을 때,
`run_pipeline.py prep`이 이를 신규 메일로 인식하여 파이프라인을 통과시킴.

- `task_EX.xlsx` Task 시트에 EX-1-3 행이 잘못 추가됨
- Log 시트에는 `_dedup_log_rows`가 중복을 감지해 행이 추가되지 않음(Log 쓰기만 막힘)
- Task 행 추가는 `(이슈번호, 트래킹번호)` 기준 dedup이라 새 번호(1-3)가 통과됨

## 근본 원인

`stages/03-triage/scripts/triage.py` `scan` 명령이 **Task 시트만** 읽고 **Log 시트를 참조하지 않음**.

`run_pipeline.py prep`에서 scan 결과를 받아도 Log에 이미 기록된 메일인지 알 수 없어
중복 여부를 판단하지 못한 채 파이프라인을 진행함.

`06-output`의 `_dedup_log_rows`는 Log 쓰기 단계에서 중복을 막지만,
이미 Task 행이 추가된 뒤여서 Task 중복은 막지 못함.

## 해결 방법

**1. `triage.py scan`에 Log 시트 읽기 추가**

`scan` 출력에 `processed_mails` 필드 추가:
```python
# Log 시트에서 (날짜, 시간, 메일제목, 발신인) 목록 추출
out["processed_mails"] = [
    {"date": ..., "time": ..., "subject": ..., "sender": ...}
    for r in ws_log.iter_rows(...)
]
```

**2. `run_pipeline.py prep`에서 진입 전 중복 차단**

scan 직후, `(received_date, subject, sender)`가 `processed_mails`에 있으면
`duplicates` 목록에 추가하고 `mails`에서 제외(`continue`):
```python
dup_entry = next(
    (pm for pm in scan.get("processed_mails", [])
     if pm["date"] == recv_date and pm["subject"] == subj and pm["sender"] == sender),
    None
)
if dup_entry:
    duplicates.append({...})
    continue
```

prep 결과에 `duplicates` 리스트 포함하여 보고.

## 예방책

- Log 시트가 중복 판단의 정본. `_done/` 폴더 이동 여부보다 Log 적재 여부를 기준으로 삼는다.
- `processed_mails`는 `(날짜, 제목, 발신인)` 3-tuple로 대조 (시간은 포워딩 시 달라질 수 있어 제외).
