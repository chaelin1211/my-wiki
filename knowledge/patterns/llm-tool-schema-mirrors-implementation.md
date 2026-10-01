---
type: pattern
tags: [llm-tool, schema, agent, testing]
created: 2026-08-20
---

# LLM 도구: 스키마가 구현을 그대로 비추게 하기

## 문제

에이전트가 쓰는 도구의 **능력이 조건부**일 때가 있다. 설정에 따라 백엔드가 바뀌고,
백엔드마다 할 수 있는 일이 다르다. 차트 엔진, 스토리지 드라이버, 결제 게이트웨이,
DB 방언 — 어느 쪽이든 같은 모양이다.

이때 두 방향으로 어긋난다.

**구현했는데 안 적음** → LLM 이 그 기능을 "지원되지 않는다"고 사용자에게 답한다.
도구를 호출조차 하지 않는다. 모델은 스키마 밖의 능력을 알 방법이 없으므로,
없는 것으로 단정하고 그것을 "기술적 한계"라고 표현한다. 환각이 아니라 정보 부재다.

**안 했는데 적음** → LLM 이 그 값을 요청하고 검증에서 튕긴다. 오류가 불친절하면
같은 호출을 여러 번 반복한다.

특히 잘 놓치는 자리가 **파라미터 설명**이다. 메인 `description` 은 조건부로 만들어
놓고 각 인자의 설명은 정적으로 두면, 지원하지 않는 값이 인자 설명을 통해 새어 나간다.

## 패턴

### 1. 능력 목록 하나를 진실의 출처로 둔다

```python
CAPABILITIES_BY_BACKEND = {
    "a": ["auto", "bar", "line", ...],
    "b": [..., "combo", "sankey"],
}
```

### 2. 설명을 이 목록으로 걸러 조립한다

값별 설명 조각을 데이터로 두고, 현재 백엔드가 가진 것만 골라 문장을 만든다.
같은 문구를 쓰는 값끼리는 렌더링 단계에서 합쳐 압축한다.

```python
HINTS = {
    ("bar", "line", "area"): {"x": "categorical or datetime", "y": "numeric"},
    ("combo",):              {"y": "주축 막대", "value": "보조축 선"},
}

def hints(field, supported):
    groups = {}
    for values, h in HINTS.items():
        if (t := h.get(field)) is None: continue
        if hit := [v for v in values if v in supported]:
            groups.setdefault(t, []).extend(hit)
    return "".join(f"{'/'.join(v)}: {t}; " for t, v in groups.items())
```

중복 제거를 **테이블이 아니라 렌더링에서** 하는 것이 요점이다. 테이블은
"한 값 = 한 줄"로 단순하게 두고, 출력만 압축된다. 새 값을 넣을 때 어느 묶음에
넣을지 고민할 필요가 없다.

### 3. 검증은 느슨하게, 오류는 친절하게

`Literal`/`Enum` 으로 막으면 위반 시 직렬화 계층의 원본 오류가 나간다. 정보가 없어
LLM 이 못 고치고 맹목적으로 재시도한다.

`enum` 은 JSON 스키마에 남겨 유도하되 검증은 통과시키고, 실행 시점에 **사유와
선택지**를 담아 돌려준다.

```python
Field(default="auto", json_schema_extra={"enum": list(types)})
```
```
chart_type 'combo' is not available on the current chart engine (plotly).
Supported types: auto, bar, line, ... Pick the closest supported type and call once more.
```

한 턴에 복구된다.

### 4. 대신 처리하지 않는다

지원 밖 요청을 도구가 근사값으로 바꿔 처리하면, LLM 이 그 안내를 실패로 읽고
재시도해 **사용자에게 같은 결과물이 여러 개 뜬다.** 무엇으로 대체할지는 의도를
아는 LLM 이 정하게 두고, 도구는 실패하되 아무것도 만들지 않는다.

### 5. 결과 문구는 실제로 한 일을 말한다

요청과 결과가 다르면 그 사실을 명시한다. `Created bar chart` 라고만 하면 이중 축을
요청한 모델은 반영되지 않았다고 판단한다.

### 6. 테스트로 양방향을 고정한다

```python
def test_documented_where_implemented():   # 구현했는데 안 적음 방지
def test_not_advertised_where_missing():   # 안 했는데 적음 방지
def test_listed_backends_actually_do_it(): # 적었는데 구현 안 함 방지
```

미지원 값이 **메인 설명과 모든 파라미터 설명** 어디에도 없는지 교차 검사한다.
전체 합집합에서 현재 목록을 뺀 나머지가 어느 문자열에도 나오면 안 된다.

## 함정

- **부분 문자열 오탐** — `area` 가 산문의 `fill areas by value` 에 걸린다. 단어 경계를 쓴다.
- **한글 인접** — `\bsankey\b` 는 `sankey에서는` 을 못 잡는다. 한글이 `\w` 라 경계가 생기지 않는다. `\bsankey(?![A-Za-z])` 처럼 뒤쪽만 ASCII 로 막는다.
- **스키마 캐싱 오해** — 대개 요청마다 새로 만들어진다. "설정을 바꿨는데 반영이 안 된다"면 캐시보다 설명 누락을 먼저 의심한다.

## 완전 강제가 필요하다면

provider 의 strict function calling(제약 디코딩)을 켜면 모델이 `enum` 밖 값을
생성조차 못 한다. 다만 전 프로퍼티 `required`·`additionalProperties: false` 등
스키마 제약이 커서 공용 LLM 어댑터를 손봐야 하고, 전 도구가 영향을 받는다.
provider 별 지원도 갈린다. 위 6단계로 대부분 잡히므로 재발이 잦을 때만 검토한다.

## 사례

- [[projects/dna-sql-agent/decisions/037-engine-capability-gating-in-tool-schema]]
- [[projects/dna-sql-agent/issues/llm-denies-capability-missing-from-tool-schema]]
