---
type: troubleshooting
project: dna-sql-agent
date: 2026-09-03
resolved: false
root-cause: "sql example 을 few-shot 으로 준다고 설명하지만, 프롬프트에 실리는 것은 설명과 SQL 뿐이고 등록된 질의문은 벡터 검색 키로만 쓰인다"
related: [sql-example, rag, retriever]
tags: [rag, prompt, few-shot, doc-gap]
---

# SQL Example few-shot 에 정작 질의문이 빠져 있다

## 증상

기능 설명 문서에 이렇게 적혀 있다.

> - 케이스 별 대표 질의문과 대응하는 SQL 예시 쌍 사전 등록하여 관리
> - SQL 생성 시, 등록된 예시를 참조(few-shot)
> - 실제 실행된 쿼리를 수집하여 SQL 예시 생성

1번과 3번은 구현과 일치한다. **2번이 실제 동작과 다르다.**

## 환경

- **관련 파일:** `src/dna/enhancers/retriever.py` (`_search_sql_examples()` `:528`, `_format_prompt_context()` `:1477`), `src/dna/settings/defaults/rag.json`
- **확인 시점:** 2026-09-03, 기능 설명 문구를 코드와 대조하던 중

## 근본 원인

프롬프트 조립부가 검색 결과에서 `description` 과 `sql` 만 꺼내 쓴다. `question` 은 정규화 단계(`:555`)에서 꺼내놓고도 프롬프트에 넣지 않는다.

```python
for idx, sql_item in enumerate(sql_examples, 1):
    description = sql_item.get("description", "")
    sql = sql_item.get("sql", "")
    prompt.append(f"{idx}. [SQL Example] (relevance_score=...)")
    if description:
        prompt.append("[REFERENCE NOTES]"); prompt.append(description)
    if sql:
        prompt.append("[REFERENCE SQL]"); prompt.append(sql)
```

등록된 질의문(`v_question`)은 임베딩되어 **유사도 검색의 키로만** 쓰이고, LLM 눈에는 보이지 않는다. 그래서 LLM이 받는 것은 "질문 → SQL" 쌍이 아니라 "설명 + SQL" 조각이다. 통상적인 few-shot(입력–출력 쌍 제시)과 구조가 다르다.

함께 어긋나는 것 셋:

| 문서의 함의 | 실제 |
|---|---|
| 여러 예시를 few-shot 으로 | `search_limit` 기본값이 **1** (`rag.json`) — 사실상 one-shot |
| 등록하면 참조된다 | Qdrant 벡터 검색이라 **벡터화 잡이 돌아야** 검색 대상이 된다 |
| 등록된 예시 전부 | `status='active'` 인 것만 (`:540`) |

## 해결 방법

둘 중 하나를 골라야 한다.

**(A) 구현을 문서에 맞춘다** — `_format_prompt_context()` 에 질의문 한 줄을 추가한다. 한 줄짜리 변경이고, few-shot 의 효과는 입력–출력 대응을 보여주는 데서 나오므로 이쪽이 자연스럽다.

```python
question = sql_item.get("question", "")
if question:
    prompt.append("[REFERENCE QUESTION]")
    prompt.append(question)
```

**(B) 문서를 구현에 맞춘다** — 아래처럼 고쳐 쓴다.

> - 케이스별 대표 질의문과 대응하는 SQL 예시 쌍을 사전 등록·관리 (활성/비활성 상태 관리 포함)
> - 등록된 예시를 임베딩해 벡터DB에 적재
> - SQL 생성 시 사용자 질문과 의미가 유사한 활성 예시를 검색해 참조 SQL·설명으로 프롬프트에 주입
> - 실제 실행된 쿼리를 수집하고 LLM으로 질의문을 생성해 예시를 자동 확충

**미결정.** 어느 쪽이 의도였는지 확인 필요.

## 예방책

- **검색 키와 프롬프트 재료를 구분해서 문서에 쓴다.** RAG 에서 "참조한다"는 말은 두 가지를 뭉갠다 — 무엇으로 찾는지(임베딩 대상)와 무엇을 보여주는지(프롬프트 주입 대상)는 다르며, 이 코드처럼 서로 다를 수 있다.
- **기본값을 문서 표현에 반영한다.** `search_limit: 1` 인 채로 "few-shot" 이라 쓰면 읽는 사람이 여러 예시를 기대한다.

## 관련 페이지

- [[projects/dna-sql-agent/overview]]
