---
type: troubleshooting
project: project-nova
date: 2026-06-19
resolved: true
root-cause: "finish 루프가 메일마다 prep scan을 독립 시드로 사용해 배치 내 이슈번호 누적이 안 됨"
related: []
tags: [mail2task, 채번, 배치처리]
---

# mail2task 배치 처리 시 이슈번호 중복 채번

## 증상

`run_pipeline.py finish`를 여러 메일 배치로 실행했을 때 모든 new 메일이 이슈번호 1로 동일하게 채번됨.

KAC 3건(인포그래픽 오류·예산 정합성·예측모델 보정) 처리 시 전부 이슈 1-1로 들어간 것이 발견 계기.

## 환경

- **관련 스크립트:** `scripts/run_pipeline.py` (finish 명령), `stages/03-triage/scripts/triage.py` (assign)
- **재현 조건:** 기존 task 시트가 없는 상태에서 new 메일 2건 이상을 한 배치로 처리

## 시도한 것들

1. ✅ `finish` 루프 앞에 `batch_scan = {}` 딕셔너리 추가 → assign 후 `next_issue_no_after`를 되먹여 다음 메일이 이어받도록 수정

## 근본 원인

`finish` 루프가 메일마다 `triage.py assign`을 독립적으로 호출하면서, 각 호출이 prep 시점의 scan 결과(`next_issue_no=1`)를 그대로 시드로 사용. 앞 메일이 이슈 1을 발급했다는 누적 정보가 다음 메일 호출로 전달되지 않았음.

`triage.py assign` 자체는 정상(한 호출 내 세그먼트 증번 처리). **오케스트레이터 루프에 누적 로직이 없던 것**이 원인.

## 해결 방법

`scripts/run_pipeline.py` finish 루프 앞에 `batch_scan = {}` 추가.

```python
batch_scan = {}  # project_id → 누적 scan 상태

for mail in mails:
    proj = mail["project"]
    scan = batch_scan.get(proj) or mail["scan"]   # 첫 메일은 prep scan 사용
    result = triage_assign(scan, ...)
    batch_scan[proj] = result["next_scan"]         # 다음 메일로 전달
```

검증: KAC 3건 new → 이슈 1·2·3 / 트래킹 1로 정상 채번 확인.

## 채번 정의 (정본)

| 번호 | 의미 | 증번 기준 |
|------|------|----------|
| 이슈번호 | 업무 단위의 고유 식별자 | new/mixed 메일마다 +1 (our_reply는 기존 이슈 참조) |
| 트래킹번호 | 이슈 내 가지번호 | 같은 이슈 내 세그먼트가 여럿일 때만 +1, 단건이면 1 |

## 예방책

- 배치 처리 후 task 시트를 열어 이슈번호 중복 여부를 간단히 확인
- same-batch `our_reply`: 같은 배치에 new와 그것을 참조하는 our_reply가 있으면 **new를 먼저** finish에 넘길 것

## 부수 주의사항 (같은 세션에서 발견)

- **prep `--eml` 인자**: `nargs="*"`이므로 한 플래그 뒤에 경로를 나열(`--eml a.eml b.eml`). 플래그를 반복하면 마지막 값만 남음
- **회신 초안 recipient_title**: 템플릿이 이름 뒤 "님"을 자동 추가 → `judgments.json`에 "님"을 쓰면 "윤혜영님님" 중복. 비우거나 직책("담당자")만 입력
