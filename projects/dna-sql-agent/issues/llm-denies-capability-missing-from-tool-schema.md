---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-20
resolved: true
root-cause: "구현한 기능을 도구 스키마(설명·파라미터)에 반영하지 않아 LLM 이 없는 기능으로 단정"
related: [decisions/037-engine-capability-gating-in-tool-schema]
tags: [llm-tool, schema, chart]
---

# LLM 이 구현된 기능을 "지원되지 않는다"고 답함

## 증상

기능을 구현하고 서버를 재기동했는데도 LLM 이 사용자에게 이렇게 답한다.

```
현재 시스템에서 제공하는 시각화 도구(Plotly 기반)의 기능적 제한으로 인해,
하나의 차트 안에 두 개의 서로 다른 Y축을 생성하는 '이중 축(Dual Axis)' 기능은
지원되지 않습니다.
```

```
현재 제가 사용하는 시각화 엔진이 combo (Bar + Line) 타입을 지원하지 않는 제약이 있어,
요청하신 형태를 완벽하게 구현하는 데 어려움이 있습니다.
```

도구를 호출조차 하지 않고 거절한다. 사용자가 특정해서 짚어주기 전에는 시도하지 않는다.

## 환경

- **런타임:** Python 3.10, `src/dna/tools/dna_visualize_data.py`
- **재현 조건:** 기능은 구현돼 있으나 `description` 또는 파라미터 `Field(description=...)` 에 그 기능이 적혀 있지 않을 때

## 시도한 것들

1. ❌ 서버 재기동 — 코드는 최신이었다. 스키마는 요청마다 `tool_registry.get_schemas()` 로 새로 만들어지므로 캐시 문제도 아니었다.
2. ❌ 설정 확인 — 엔진 설정은 정상이었고, `chart_type` 의 `enum` 에도 해당 타입이 들어 있었다.
3. ✅ LLM 에게 실제로 가는 스키마를 덤프해서 대조 — 해당 기능이 어느 설명에도 없음을 확인.

## 근본 원인

**LLM 은 도구 스키마에 적힌 것만 안다.** 구현 여부를 추론할 방법이 없으므로, 설명에 없는 능력은 "없는 것"으로 단정하고 그것을 "기술적 한계"라고 표현한다. 없는 사실을 지어내는 게 아니라 모르는 것을 없다고 말하는 쪽이다.

이 세션에서 같은 원인으로 세 번 반복됐다.

| 모델의 주장 | 실제 | 빠진 곳 |
|---|---|---|
| combo 지원 안 함 | echarts 에 있었음 | `chart_type` 목록에는 있었으나 `description` 에 유도 문구 없음 |
| 이중 축 지원 안 함 | 방금 구현 | 결과 문구가 `Created bar chart` 라고만 함 |
| 모두-막대+우측 눈금 지원 안 함 | 구현돼 있었음 | `value` 설명에서 해당 항목을 뺐음 |

특히 위험한 형태는 **파라미터 설명만 정적으로 남는 경우**다. `chart_type` 만 엔진별로 동적 생성하고 `x`/`y`/`value`/`color` 는 base 모델에 하드코딩돼 있어, 지원하지 않는 타입이 `value` 설명으로 새어 나가 반대 방향의 오류(없는 타입을 요청)도 함께 일으켰다.

## 해결 방법

구현과 설명이 함께 움직이도록 **테스트로 고정**한다. 설명은 사람이 잊지만 테스트는 잊지 않는다.

```python
def test_documented_where_implemented(self, monkeypatch):
    for engine in DUAL_AXIS_BAR_ENGINES:
        assert "bar: 보조 y축" in self._value_desc(monkeypatch, engine)

def test_not_advertised_where_unimplemented(self, monkeypatch):
    for engine in CHART_TYPES_BY_ENGINE:
        if engine not in DUAL_AXIS_BAR_ENGINES:
            assert "bar: 보조 y축" not in self._value_desc(monkeypatch, engine)

def test_engines_listed_actually_render_it(self, monkeypatch):
    """목록에 넣었으면 실제로 보조축이 나와야 한다."""
    ...
    assert fig["layout"]["yaxis2"]["side"] == "right"
```

세 번째가 반대 방향(적었는데 구현 안 함)을 막는다.

미지원 항목이 새는지는 **툴 설명 + 모든 파라미터 설명**을 훑어 교차 검사한다. 이 검사를 넣자마자 `color` 설명의 타입 나열과 `sankey` 언급이 새고 있던 것이 추가로 잡혔다.

```python
for engine, types in CHART_TYPES_BY_ENGINE.items():
    missing = set().union(*CHART_TYPES_BY_ENGINE.values()) - set(types)
    texts = {"description": desc, **field_descriptions}
    for where, text in texts.items():
        for t in missing:
            assert not re.search(rf"\b{t}(?![A-Za-z])", text)
```

정규식 두 가지 함정이 있었다.

- `\barea\b` 가 산문의 `fill areas by value` 에 걸림 → 단어 경계 필요
- `\bsankey\b` 가 `sankey에서는` 을 못 잡음 → 한글이 `\w` 라 경계가 생기지 않는다. `(?![A-Za-z])` 로 대체

## 예방

- 파라미터 설명을 base 모델에 하드코딩하지 않는다. 능력이 조건부라면 설명도 조건부로 조립한다.
- 도구 결과 문구는 **실제로 한 일**을 말한다. 요청과 결과가 다르면 그 사실을 명시한다.
- 새 기능을 구현하면 같은 커밋에서 스키마 설명과 테스트를 함께 넣는다.

→ 범용 정리: [[knowledge/patterns/llm-tool-schema-mirrors-implementation]]
