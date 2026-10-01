---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-29
resolved: false
root-cause: "JWT 서명키가 소스에 하드코딩. 2026-08-19 df1998c 이후로는 환경변수 경로마저 없어 재정의 자체가 불가"
related: []
tags: [security, auth, jwt]
---

# JWT 서명키가 소스에 하드코딩 — 환경변수로 덮을 수도 없음

## 증상

`src/dna/auth/jwt_utils.py:15` (현재):

```python
def _get_secret() -> str:
    return "vanna-chat-jwt-secret-key-2025-secure-change-in-prod"
```

서명키가 소스에 그대로 있고, 배포처가 이를 바꿀 수단이 없다.

> 2026-08-26 재확인. 최초 기록(2026-07-29) 시점에는
> `os.getenv("JWT_SECRET_KEY", "default-secret-change-me")` 로 환경변수를 먼저 보고
> 없을 때만 기본값으로 떨어지는 형태였다. 2026-08-19 `df1998c`
> ("cleaning up unused environment configurations") 가 그 `getenv` 를 지우면서
> 조용한 fallback 이 아니라 **재정의 불가능한 하드코딩**이 됐다. 증상이 완화된 게
> 아니라 악화된 쪽이다.

## 환경

- `dna-sql-agent`, JWT 발급/검증 전체 (`src/dna/auth/jwt_utils.py`)

## 근본 원인

암호학적으로 중요한 서명 키를 소스에 둔 탓에, 레포에 접근 가능한 모두가 그 값을 안다.
값을 아는 사람은 누구나 유효한 JWT 를 위조해 인증을 우회할 수 있다. 모든 배포처가 같은
키를 쓰므로 한 곳에서 유출되면 전 배포처가 함께 뚫린다.

`JWT_SECRET_KEY` 가 실제로 어디에도 설정돼 있지 않아 "미사용 환경변수" 로 분류돼 정리
대상에 들어간 것이 직접적 계기다. 쓰이지 않는 상태 자체가 문제였는데, 그 신호를 "필요
없다" 로 읽었다. → [[knowledge/patterns/empty-state-ambiguity-record-dont-infer]]

## 해결 방법

미해결. 다음 방향으로 수정 필요:

```python
def get_jwt_secret_key() -> str:
    key = os.getenv("JWT_SECRET_KEY")
    if not key:
        raise RuntimeError("JWT_SECRET_KEY 환경변수가 설정되지 않았습니다.")
    return key
```

설정 누락 시 기동 자체를 실패시켜서, 약한 기본값으로 조용히 운영되는 상황을 원천 차단.

## 예방책

- 시크릿·서명 키류는 기본값 fallback 금지 원칙 — 없으면 즉시 실패가 안전, 조용한
  기본값은 위험
- "안 쓰이는 환경변수" 를 지우기 전에, 안 쓰이는 이유가 설정 누락인지부터 확인
- 기동 시 필수 환경변수 검증 단계를 두고(예: `main.py` 초입에서 required env 체크), 여기
  걸리게 하는 것도 방법

## 관련 페이지

- [[decisions/027-nuitka-source-compilation]]
