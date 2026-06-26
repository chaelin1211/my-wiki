---
type: troubleshooting
project: mail2task
date: 2026-06-19
resolved: true
root-cause: "run_pipeline.py prep이 ingest를 --emit-input으로만 호출해 envelope를 버렸고, demo 모드에서 input.sender가 forwarded_origin.sender로 교체되어 LLM이 실제 발신자(우리측)를 볼 수 없었음"
related: []
tags: [mail2task, our-reply, ingest, envelope, demo-mode]
---

# Re: 메일이 our_reply 대신 customer_addition으로 오인식됨

## 증상

`Re:` 접두어가 붙은 `.eml` 파일을 처리할 때, 실제 발신자가 우리측(예: mobigen.com)임에도
LLM이 `nature = customer_addition`으로 판단.

- 고객이 보낸 원본 메일과 우리측 회신 메일이 각각 별도 `.eml`로 inbox에 있을 때 발생
- Task 시트에 이슈번호 None인 customer_addition 행이 추가됨
- Log 시트에도 고객 메일 내용이 두 줄 중복 기록됨

## 근본 원인

두 가지 구조적 원인이 겹쳤음.

**① demo 모드에서 input.sender가 교체됨**

`ingest.py`의 `build_input()`에서 `mode == "demo"`이고 `forwarded_origin.sender`가 있으면
`input.sender`를 원본 발신자(고객)로 교체한다. Re: 메일의 경우 인용된 원본이 고객 메일이므로
`input.sender`가 고객 이름으로 바뀐다.

```python
# ingest.py build_input()
meta = origin if (mode == "demo" and origin.get("sender")) else envelope
return { "sender": meta.get("sender", ""), ... }  # demo면 원본 발신자가 됨
```

**② prep이 envelope를 버림**

`run_pipeline.py prep`이 ingest를 `--emit-input`(input dict만 출력)으로 호출해서
실제 봉투 헤더(`envelope.sender` = 이광진, `top_comment` = 우리측 회신 본문)를
judgment_request에 포함하지 않았음. LLM은 `input.sender`(김강우)만 보고 판단.

## 해결 방법

**`run_pipeline.py prep` 수정 (2026-06-19 적용)**

```python
# 변경 전
_, inp_out, _ = run([INGEST, "--eml", eml, ..., "--emit-input"])
state = jrun([PIPELINE, "--new", "--stdin"], stdin=inp_out)

# 변경 후
_, full_out, _ = run([INGEST, "--eml", eml, ..., "--emit"])   # 전체 결과 수신
ingest_result = json.loads(full_out)
inp_json = json.dumps(ingest_result["input"], ensure_ascii=False, indent=2)
state = jrun([PIPELINE, "--new", "--stdin"], stdin=inp_json)  # input만 pipeline에 넘김
```

mails 항목에 `envelope`, `top_comment`, `forwarded` 추가:
```python
mails.append({
    ...
    "envelope": ingest_result.get("envelope"),    # 실제 봉투 From/To/Subject
    "top_comment": ingest_result.get("top_comment"),  # 우리측 회신 본문
    "forwarded": ingest_result.get("forwarded"),
    ...
})
```

judgment_template `_note`에 our_reply 판단 기준 명시:
> `input.sender`가 아닌 `envelope.sender` 기준으로 our_reply 판단.  
> `envelope.sender`가 우리측 도메인이고 subject에 `Re:`가 있으면 `our_reply`.  
> `mail_summary`는 envelope 기준, `processing_note`는 `top_comment` 요약.

## 예방책

- Re: 메일의 `nature` 판단은 반드시 `envelope.sender`를 본다. `input.sender`는 demo 모드에서 원본 발신자로 바뀌어 있을 수 있음.
- our_reply이면 Task 신규 행 추가 없이 기존 `(이슈, 트래킹)` 행의 처리내용(LLM)만 갱신.
- Log는 `envelope.sender`와 `envelope.received_time`(실제 발신 시각) 기준으로 기록.

## 후속 — 구조적 해결

여기 해결책(prep이 envelope/top_comment를 judgment_request에 동봉)은 **판단 레이어 보정**이라, prep을 안 거치는
결정론 스크립트나 `pipeline --new` 경로는 여전히 `top_comment`를 잃는다. ingest 자체에서 두 턴을 보존하도록 고치는
설계 결정: [[projects/project-nova/decisions/003-fwd-두턴-보존-최신턴-기준|ADR-003 FWD 두 턴 보존 + 최신 턴 기준]].
