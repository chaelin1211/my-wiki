---
type: troubleshooting
project: dna-sql-agent
date: 2026-06-05
resolved: true
root-cause: "원본 데이터에 역방향 흐름(A→B→A) 존재"
related: [echarts, sankey]
tags: [echarts, sankey, dag, cycle]
---

# ECharts Sankey "DAG has cycle" 오류

## 증상

```
Sankey is a DAG, the original data has cycle!
```

ECharts sankey 차트 렌더 시 콘솔 에러 발생, 차트 미표시.

## 환경

- **관련 패키지:** echarts 5.x, echarts-for-react
- **재현 조건:** sankey 노드 간 역방향 링크가 존재하는 데이터 (A→B→A, 또는 self-loop A→A)

## 시도한 것들

1. ❌ 데이터 전처리 없이 그냥 넘김 → 오류 지속
2. ✅ iterative DFS로 back-edge 감지 후 제거

## 근본 원인

ECharts sankey는 DAG(Directed Acyclic Graph)를 요구한다. 원본 데이터에서:
- 동일 카테고리명이 여러 tier에 걸쳐 등장해 역방향 링크가 생성되거나
- 실제 비즈니스 데이터가 양방향 흐름을 포함하는 경우 (A부서 → B부서 → A부서 인사이동 등)

사이클이 발생한다.

## 해결 방법

`_build_sankey()` 호출 후 `_remove_sankey_cycles(links)` 로 전처리:

```python
def _remove_sankey_cycles(self, links: list) -> list:
    """자기참조 및 사이클 링크를 iterative DFS로 감지해 제거."""
    from collections import defaultdict

    # 1. self-loop 제거
    links = [l for l in links if l["source"] != l["target"]]

    # 2. DFS로 back-edge 감지
    adj = defaultdict(list)
    for i, l in enumerate(links):
        adj[l["source"]].append((l["target"], i))

    nodes = {l["source"] for l in links} | {l["target"] for l in links}
    visited, cycle_edges = set(), set()

    for start in nodes:
        if start in visited:
            continue
        stack = [(start, iter(adj[start]))]
        in_stack = {start}
        visited.add(start)
        while stack:
            node, children = stack[-1]
            try:
                neighbor, idx = next(children)
                if neighbor not in visited:
                    visited.add(neighbor)
                    in_stack.add(neighbor)
                    stack.append((neighbor, iter(adj[neighbor])))
                elif neighbor in in_stack:
                    cycle_edges.add(idx)
            except StopIteration:
                in_stack.discard(node)
                stack.pop()

    return [l for i, l in enumerate(links) if i not in cycle_edges]
```

## 예방책

- 3단 sankey 구성 시 tier 간 노드명 중복 가능성 인지
- 인사이동, 물류 흐름 등 양방향 데이터는 사이클 필연적 → 방어 코드 필수

## 관련 페이지

- [[knowledge/troubleshooting/echarts-sankey-dag-cycle]]
