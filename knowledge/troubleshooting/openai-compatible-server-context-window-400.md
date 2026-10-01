---
type: troubleshooting
tags: [llm, vllm, llama-cpp, context-window, api]
created: 2026-09-03
---

# OpenAI 호환 서버의 400 은 대부분 컨텍스트 문제다

## 증상

- 자체 호스팅한 OpenAI 호환 엔드포인트(`/v1/chat/completions`)가 `400 Bad Request` 를 돌려준다
- 같은 코드가 상용 API(OpenAI·Azure)에서는 잘 돌아간다
- `max_tokens` 를 빼고 재시도하는 폴백이 있는데도 여전히 400 이다
- 서버 응답 본문에 `exceeds the available context size` / `exceed_context_size_error` 같은 문구가 있다

## 원인

400 이 두 가지 서로 다른 초과를 같은 코드로 알린다.

| 무엇이 넘쳤나 | 전형적 문구 | 고치는 곳 |
|---|---|---|
| **출력** 요청량이 모델 한도 초과 | `max_tokens too large`, `max_tokens must be <= N` | 클라이언트의 `max_tokens` |
| **입력** 프롬프트가 가용 컨텍스트 초과 | `request (N tokens) exceeds the available context size (M tokens)` | 서버의 컨텍스트 설정, 또는 프롬프트 크기 |

상용 API는 컨텍스트가 넉넉해 앞쪽만 겪지만, 자체 호스팅에서는 뒤쪽이 훨씬 흔하다. **`max_tokens` 를 빼는 폴백은 앞쪽만 고친다.** 입력이 넘쳤다면 폴백이 성공할 수 없다.

가용 컨텍스트가 예상보다 작게 나오는 흔한 이유:

- **슬롯 분할** — llama.cpp 는 `-c` 로 준 컨텍스트를 `--parallel` 슬롯 수로 나눈다. `-c 8192 --parallel 4` 면 요청 하나가 쓸 수 있는 건 2048 이다. `2816`, `1365` 같은 어중간한 숫자가 나오면 거의 이 경우다.
- **출력 예약** — 서버에 따라 `max_tokens` 만큼을 컨텍스트에서 미리 떼고 남은 것을 입력 한도로 계산한다. 그래서 큰 `max_tokens` 가 입력 한도를 잠식한다.
- `--max-model-len`(vLLM)을 모델의 실제 한도보다 작게 지정한 채 잊음

## 해결

1. **서버 설정을 먼저 본다.** 모델 카드의 컨텍스트가 아니라 **기동 옵션**이 실제 한도를 정한다.
   ```
   vLLM       --max-model-len 16384
   llama.cpp  -c 16384 --parallel 1     # 슬롯을 늘리면 슬롯당 컨텍스트가 준다
   ```
2. **`max_tokens` 를 모델별 설정으로 뺀다.** 코드에 박힌 큰 상수(`65536` 등)는 다른 모델로 갈아끼우는 순간 깨진다.
3. **프롬프트를 쪼갠다.** 스키마·문서를 한 번에 싣는 배치 크기를 줄인다. 다만 컨텍스트가 2~3k 수준이면 시스템 프롬프트만으로도 벅차서 이걸로는 못 넘긴다.

## 진단 요령

- **서버 응답 본문을 반드시 로그에 남긴다.** `raise_for_status()` 가 만드는 `400 Client Error: Bad Request for url: ...` 만으로는 두 초과를 구분할 수 없다. 원인은 본문에만 있다.
- **폴백은 결과까지 기록한다.** "재시도한다"만 남기고 재시도 결과를 안 남기면, 한 요청의 연쇄가 별개 사고 두 건으로 보인다.
- 토큰 수를 세어 확인한다 — 요청 본문을 그대로 `/tokenize`(있으면) 나 로컬 토크나이저에 넣어 실제 크기를 재보면 추측이 끝난다.

## 관련 페이지

- [[projects/dna-sql-agent/issues/relation-info-llm-context-size-400]]
