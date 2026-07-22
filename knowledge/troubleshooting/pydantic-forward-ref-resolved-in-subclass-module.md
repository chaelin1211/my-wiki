---
type: knowledge
category: troubleshooting
date: 2026-07-20
tags: [pydantic, python, fastapi, forward-ref, inheritance]
---

# Pydantic v2: 부모 모델의 forward-ref 필드를 다른 모듈의 서브클래스가 상속하면 스키마 빌드 실패

## 문제 패턴

```python
# database/models.py
class SystemResponse(BaseModel):
    vectorization_jobs: list["JobStatus"] = []   # forward ref (문자열 타입)

class JobStatus(BaseModel):
    ...
```

```python
# group_admin/models.py — 다른 모듈
from dna.database.models import SystemResponse

class SystemScopeResponse(SystemResponse):
    exclusively_owned: bool
```

`SystemResponse`는 정상 동작하지만(같은 모듈 안에 `JobStatus`가 있어서), `SystemScopeResponse`를 실제로 인스턴스화하는 순간 다음 에러가 난다:

```
pydantic.errors.PydanticUserError: `SystemScopeResponse` is not fully defined;
you should define `JobStatus`, then call `SystemScopeResponse.model_rebuild()`.
```

## 원인

Pydantic v2는 forward-ref(문자열 타입 어노테이션)를 **그 필드가 상속되어 쓰이는 클래스가 정의된 모듈**의 네임스페이스에서 찾는다. 부모 클래스의 모듈 네임스페이스가 아니다.

`ConnectionResponse`처럼 forward-ref 필드가 없는 부모는 어느 모듈에서 상속해도 문제없다 — 이 문제는 **부모가 forward-ref 필드를 갖고 있을 때만** 서브클래스 쪽에서 터진다. 그래서 같은 패턴(부모 상속 + 서브클래스에 필드 추가)이어도 어떤 모델은 되고 어떤 모델은 안 되는 것처럼 보여 헷갈리기 쉽다.

## 해결

서브클래스가 정의된 모듈에 forward-ref가 가리키는 타입을 import만 해두면 된다 (직접 쓰지 않아도 네임스페이스에 존재하기만 하면 pydantic이 찾음):

```python
# group_admin/models.py
from dna.database.models import JobStatus, SystemResponse  # noqa: F401 — forward ref 해석용
```

## 진단 팁

- 에러 메시지의 `model_rebuild()` 안내를 곧이곧대로 따라 매 요청마다 rebuild를 부르는 임시방편보다, import 하나로 근본 해결하는 게 낫다.
- 같은 파일에 정의된 모델은 항상 되고, 다른 모듈에서 상속한 모델만 이 에러가 나면 백발백중 이 패턴이다.
- syntax check(`ast.parse`)나 `tsc`류 정적 검사로는 못 잡는다 — 실제로 그 모델을 인스턴스화하는 코드 경로(요청 1번)를 태워봐야 드러난다.

## 실제 사례

- [[projects/dna-sql-agent/sessions/2026-07-20-group-admin-db-tabs-unification]]
