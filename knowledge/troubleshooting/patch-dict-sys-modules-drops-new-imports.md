---
type: troubleshooting
tags: [python, pytest, mock, testing]
---

# `patch.dict(sys.modules, ...)` 가 테스트 중 새로 import된 모듈까지 지운다

## 증상

무거운 모듈(예: 서비스 초기화를 하는 `agent_service`)을 가짜 모듈로 바꿔 끼우려고 `mocker.patch.dict(sys.modules, {"pkg.heavy": fake})` 를 썼다. 테스트를 하나씩 돌리면 통과하는데, 같은 클래스의 여러 테스트를 이어서 돌리면 뒤쪽 테스트에서 다른 패치(`mocker.patch("pkg.viz.Tool.method")`)가 먹지 않는다.

## 원인

`patch.dict` 는 끝날 때 딕셔너리를 **시작 시점의 내용으로 통째로 되돌린다.** 테스트 도중 새로 import된 모듈(`pkg.viz` 등)도 `sys.modules` 에서 지워진다. 다음 테스트에서 그 모듈이 다시 import되면 새 모듈 객체가 생긴다. 이미 다른 모듈이 옛 객체를 잡고 있으면, 패치한 쪽과 실제로 쓰이는 쪽이 서로 다른 객체가 된다.

## 해결

바꿔 끼울 키 하나만 넣고 되돌리는 `monkeypatch.setitem` 을 쓴다.

```python
def test_x(monkeypatch):
    fake = types.ModuleType("pkg.heavy")
    fake.database_pool = ...
    monkeypatch.setitem(sys.modules, "pkg.heavy", fake)
```

`setitem` 은 그 키만 원래 값으로 복원하고(없었으면 삭제), 다른 모듈은 건드리지 않는다.

## 관련

- [[projects/dna-sql-agent/sessions/2026-10-12-tool-display-name-map-region-widget-refresh-error]] — 북마크 렌더 API 테스트(`tests/chat/test_bookmarks.py`)
