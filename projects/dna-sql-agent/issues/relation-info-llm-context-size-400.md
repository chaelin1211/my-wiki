---
type: troubleshooting
project: dna-sql-agent
date: 2026-09-03
resolved: false
root-cause: "배포된 LLM 서버의 가용 컨텍스트(2816토큰)가 관계정보 프롬프트(4873토큰)보다 작다. max_tokens=65536 하드코딩은 1차 400의 원인일 뿐 본질이 아니다"
related: [relation-info, llm, vllm]
tags: [llm, context-window, timeout, 400]
---

# 관계정보 생성이 400 Bad Request 로 실패한다

## 증상

관계정보(FK 추론) 생성 중 서버 로그에 경고가 뜨고, 이어서 같은 요청이 다시 400 으로 떨어진다.

```
LLM request rejected with max_tokens=65536; retrying without max_tokens:
400 Client Error: Bad Request for url: http://172.30.2.185:8081/1/chat/completions
```

```
request (4873 tokens) exceeds the available context size (2816 tokens), try increasing it',
'type': 'exceed_context_size_error'
```

두 줄이 별개 사고로 보이지만 **한 요청의 연쇄**다. 앞줄은 폴백 재시도를 알리는 정상 로그이고, 뒷줄이 그 재시도마저 실패한 진짜 이유다.

## 환경

- **관련 파일:** `src/dna/database/relation_info_generator.py` (`_call_llm()` `:392`, 페이로드 `:407`, 폴백 `:412-425`)
- **LLM 서버:** `http://172.30.2.185:8081` (OpenAI 호환 엔드포인트)
- **재현 조건:** 컨텍스트가 작은 모델이 올라간 서버를 활성 LLM 연결로 지정하고 관계정보 생성 실행

## 시도한 것들

1. ❌ 엔드포인트에 직접 요청해 응답 본문 확인 — 작업 환경에서 해당 사설망으로 접근이 안 돼 타임아웃
2. ✅ 두 로그 줄을 한 요청의 1차 실패 → 폴백 재시도 실패로 해석. 코드의 폴백 분기와 정확히 일치
3. ✅ 프롬프트 크기 결정 지점 추적 — 테이블 12개 단위 청크(`POSTGRES_MAX_CHUNK_TABLES` / `ORACLE_MAX_CHUNK_TABLES`, `:88-89`)

## 근본 원인

`_call_llm()` 이 페이로드에 `max_tokens: 65536` 을 하드코딩한다. 참조 스크립트 값을 그대로 옮긴 것으로, 서버가 400/422 로 거부하면 `max_tokens` 를 빼고 한 번만 재시도한다.

```python
payload = {..., "temperature": 0.1, "max_tokens": 65536}
...
except requests.HTTPError as exc:
    if response.status_code not in {400, 422}:
        raise
    payload.pop("max_tokens", None)
    response = requests.post(url, headers=headers, json=payload, timeout=timeout)
```

폴백 자체는 설계대로 동작했다. 문제는 그 다음이다. **프롬프트 본문(4873토큰)이 서버의 가용 컨텍스트(2816토큰)보다 커서** `max_tokens` 를 빼도 통과할 수 없다. 즉 출력 한도 문제가 아니라 입력 크기 문제이고, 코드가 아니라 LLM 서버 설정이 원인이다.

`2816` 이라는 어중간한 값은 llama.cpp·vLLM 계열에서 `n_ctx` 를 동시 처리 슬롯 수로 나눴을 때 나오기 쉬운 숫자다.

## 해결 방법

**정본은 서버 쪽이다.** 컨텍스트를 최소 16k 이상으로 올린다. 관계정보 프롬프트는 테이블 12개를 한 번에 싣기 때문에 2816토큰에서는 청크를 아무리 줄여도 시스템 프롬프트만으로 벅차다.

```
# vLLM
--max-model-len 16384
# llama.cpp — --parallel 로 슬롯을 나누면 슬롯당 컨텍스트가 그만큼 줄어든다
-c 16384 --parallel 1
```

코드 쪽 완화책(근본 해결 아님, 컨텍스트가 8k쯤 될 때 의미 있음):

- `POSTGRES_MAX_CHUNK_TABLES` / `ORACLE_MAX_CHUNK_TABLES` 를 12 → 4~6 으로 낮춰 프롬프트 축소
- `max_tokens` 65536 하드코딩을 환경변수로 분리해 모델 한도에 맞추기 (`RELATION_INFO_LLM_TIMEOUT` 이 이미 같은 방식으로 분리돼 있다)

**미적용.** 서버 설정 변경 권한이 있는 쪽 확인 대기.

## 곁가지 — URL 이 `/v1` 이 아니라 `/1` 로 찍힌다

로그의 요청 URL 이 `http://172.30.2.185:8081/1/chat/completions` 다. `_call_llm()` 은 `llm_connections.url` 뒤에 `/chat/completions` 만 붙이므로(`:410`), DB에 저장된 URL 이 `.../8081/v1` 이 아니라 `.../8081/1` 로 들어가 있을 가능성이 있다. 붙여넣기 과정의 오타가 아니라면 LLM 연결 설정도 같이 고쳐야 한다. 미확인.

## 예방책

- **모델 한도에 의존하는 상수를 코드에 박지 않는다.** `max_tokens` 는 배포된 모델마다 달라지는 값이라 설정으로 빼야 한다.
- **폴백 성공 여부를 로그로 구분한다.** 지금은 "재시도한다"는 경고만 남고 재시도 결과가 같은 맥락에 남지 않아, 두 로그 줄이 별개 사고처럼 보였다. 폴백은 실패를 숨기는 게 아니라 기록해야 한다.
- **LLM 연결 등록 시 `/v1` 경로와 모델 컨텍스트를 함께 검증한다.** 등록 시점에 `/models` 를 한 번 호출해보면 경로 오타와 서버 미가동을 같이 걸러낼 수 있다.

## 관련 페이지

- [[knowledge/troubleshooting/openai-compatible-server-context-window-400]]
- [[projects/dna-sql-agent/overview]]
