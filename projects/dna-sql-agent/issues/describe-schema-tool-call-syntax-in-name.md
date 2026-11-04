---
type: troubleshooting
project: dna-sql-agent
date: 2026-10-21
resolved: false
root-cause: "모델이 프롬프트·도구 설명의 호출 문장 예시를 도구 호출 형식으로 베껴 vLLM Gemma 해석기가 문장 전체를 도구 이름으로 넘김"
related: [vllm, gemma, tool-calling, prompt]
tags: [llm, tool-call, describe_schema, prompt]
---

# describe_schema 호출이 문장째 도구 이름으로 들어가 "not found"

## 증상

```
도구 실패 : Tool 'describe_schema(search="작전")<tool_call|>' not found
```

로그에는 `ToolCall(name='describe_schema(group="작전 임무 및 대응 방책 수립")<tool_call|>', arguments={})`처럼 남는다. 깨진 호출과 "not found" 응답이 같은 대화에 여러 번 반복된다.

## 환경

- **모델:** `google/gemma-4-26B-A4B-it` (vLLM, 스트리밍, `temperature 0`, `REASONING_EFFORT=none`, `BENCHMARK_MODE=True`)
- **관련 코드:** `dna_system_prompt_builder.py` 스키마 조회 안내, `tools/describe_schema.py` 도구 설명
- **재현 조건:** "describe schema 툴 써봐"처럼 새 대화에서 단순히 부르면 정상이다. 깨진 호출이 이미 쌓인 대화("작전 임무 및 대응 방책 관련 정보")에서는 계속 깨진다.

## 시도한 것들

1. ❌ **로그 상관관계로 원인 추정.** 메모리 안내가 프롬프트에 들어간 턴에서 깨짐 비율이 67%, 들어가지 않은 턴은 3%였다. 하지만 표본이 6턴이었다.
2. ❌ **직접 만든 질문으로 비교.** 메모리 도구 유무, 스트리밍 여부를 바꿔 12번씩 보냈지만 모두 정상이었다. 짧은 문맥에서는 재현되지 않는다.
3. ✅ **실패한 요청을 로그에서 그대로 복원해 재전송.** 시스템 프롬프트, 대화 5개, 도구 9개를 복원했고 3/3 재현됐다.
4. ✅ **요소를 하나씩 빼며 재전송.**
   - 메모리 문구만 빼면 여전히 깨졌다.
   - STEP 0/3만 빼거나 저장 도구 설명을 원래대로 돌리면 모델이 다른 도구를 골라서 판단할 수 없었다.
   - **`describe_schema` 호출 문장 예시만 설명형으로 바꾸면** 같은 판단(같은 테이블 조회)을 정상 형식으로 3/3 호출했다.
   - 다른 실패 요청에도 같은 수정을 적용하자 정상으로 호출했다.

## 근본 원인

- **모델이 예시를 베낍니다.** Gemma는 자기 고유 형식(`call:describe_schema{group:…}`) 대신, 프롬프트와 도구 설명에 있는 파이썬 호출 문장 예시를 그대로 출력합니다. 해당 예시는 `describe_schema()`, `describe_schema(group="cluster name")`, `describe_schema("TABLE_NAME")`, `describe_schema(["A.T1","A.T2"])`이고, 도구 설명에도 `group="cluster name"`, `search="keyword"`가 있습니다.
- **해석기가 문장째 이름으로 넘깁니다.** vLLM의 Gemma 해석기는 중괄호 인자를 찾지 못하면 남은 문장 전체(끝 표시 `<tool_call|>` 포함)를 이름으로 넘기고 인자는 `{}`로 둡니다.
- **기록에 쌓이면 계속 따라 합니다.** 깨진 호출이 대화 기록에 남으면 모델이 같은 형식을 반복합니다.
- **`describe_schema`만 깨지는 이유:** 호출 문장 예시가 이 도구에만 많아서입니다.

## 해결 방법

아직 고치지 않았습니다. 수정 방향은 두 가지입니다.

1. **원인 수정:** 프롬프트 스키마 조회 안내 5곳과 도구 설명 2곳의 호출 문장 예시를 설명형으로 바꿉니다. 예: `` `describe_schema` with `group` set to the cluster name ``. 재현 실험에서 효과를 확인했습니다.
2. **안전장치:** `ResponseSanitizerMiddleware`에서 `도구이름(인자=값)<tool_call|>` 형태를 알아보고, 등록된 도구라면 정상 호출로 바꿉니다. 명확화 도구의 깨진 호출을 복구하는 기존 로직과 같은 자리입니다.

## 예방책

- 도구 설명과 시스템 프롬프트에 호출 문장 모양의 예시를 넣지 않습니다. 인자는 이름과 뜻을 말로 설명합니다.
- 프롬프트를 바꾼 뒤에는, 문제가 됐던 요청을 로그에서 복원해 다시 보내 보는 회귀 확인을 합니다.

## 관련 페이지

- [[knowledge/prompting/llm-copies-template-placeholders]]
- [[knowledge/troubleshooting/llm-behavior-replay-ablation]]
- [[decisions/052-tool-access-vs-ui-display-separation|ADR-052]] 범위 밖 문제
