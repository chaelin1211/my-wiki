---
type: troubleshooting
tags: [python, bcrypt, auth, password]
---

# bcrypt 72바이트 제한 — 5.0부터 초과 입력에 예외

## 증상

긴 비밀번호로 회원가입·비밀번호 변경·로그인을 하면 500 오류가 난다. 한글은 한 글자가 UTF-8 3바이트라 **한글 약 25자**만 넣어도 발생한다.

```
ValueError: password cannot be longer than 72 bytes, truncate manually if necessary (e.g. my_password[:72])
```

`hashpw` 뿐 아니라 `checkpw` 도 같은 예외를 던진다. 그래서 로그인에서 "비밀번호 틀림(401)"이 아니라 500이 된다.

## 원인

bcrypt 알고리즘은 원래 비밀번호의 앞 72바이트만 쓴다. 예전 `bcrypt` 패키지는 넘는 부분을 조용히 잘랐지만, **5.0부터는 예외를 던진다.** DB 칼럼 길이와는 무관하다(해시는 항상 60자).

## 해결

- **새 비밀번호를 정하는 입력**(가입·변경·관리자 초기화)은 UTF-8 기준 72바이트 이내로 검증한다. 화면에서도 `new TextEncoder().encode(pw).length > 72` 로 같은 제한을 둔다.
- **확인(`checkpw`)은 앞 72바이트로 비교**한다. 예전 버전이 잘라서 저장한 긴 비밀번호 계정도 계속 로그인된다.

```python
PASSWORD_MAX_BYTES = 72

def _check_password_bytes(v: str) -> str:
    if len(v.encode("utf-8")) > PASSWORD_MAX_BYTES:
        raise ValueError("password must be at most 72 bytes")
    return v

async def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8")[:72], password_hash.encode("utf-8"))
```

- 최대 길이를 안내 문구에 적어도 보안상 문제는 거의 없다(공격 범위를 줄이지 않음).

## 관련

- [[projects/dna-sql-agent/sessions/2026-10-19-auth-enhancement-signup-reset-account-management]]
