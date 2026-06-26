---
type: knowledge
category: troubleshooting
tags: [python, pip, venv, pyenv, dependency, ModuleNotFoundError]
created: 2026-06-22
---

# Python — pip install이 .venv가 아닌 pyenv 전역에 설치되는 문제

## 문제 패턴

`requirements.txt`에 분명히 패키지가 있고 `pip install -r requirements.txt`도 성공했는데,
서버 실행 시 `ModuleNotFoundError: No module named 'xxx'` 가 계속 발생한다.

예시 (실제 발생):
```
Report generation failed: 500 - Document generation failed: No module named 'docx'
```

`python-docx>=1.2.0` 가 requirements.txt에 있고 `pip3 install`도 했는데도 못 찾음.

## 원인

`pip3` / `python3` 가 가리키는 환경과 **서버가 실제로 도는 환경(.venv)이 다름.**

- `pip3 --version` → `/Users/.../.pyenv/versions/3.10.20/...` (pyenv 전역)
- 프로젝트엔 `.venv` 가 따로 있고 서버는 `.venv/bin/python` 으로 실행됨
- 즉 패키지는 pyenv 전역에 깔렸고, `.venv` 안엔 없는 상태

`.venv` 활성화(`source .venv/bin/activate`) 없이 맨손으로 `pip3`를 쓰면
shims가 전역 환경을 가리켜 엉뚱한 곳에 설치된다.

## 진단

```bash
pip3 --version                              # 어느 환경의 pip인지 경로 확인
.venv/bin/python -c "import docx"           # .venv에 실제로 있는지 직접 확인
.venv/bin/pip show python-docx              # .venv 기준 설치 여부
```

## 해결책

`.venv` 인터프리터를 명시해서 설치한다.

```bash
# 방법 1: 활성화 후 설치
source .venv/bin/activate
pip install -r requirements.txt

# 방법 2: 활성화 없이 .venv의 pip 직접 호출 (권장 - 실수 방지)
.venv/bin/pip install -r requirements.txt
```

설치 후 `.venv/bin/python -c "import 모듈"` 로 검증하고 서버를 재시작한다.

## 교훈

- 패키지 관련 명령은 항상 **어느 인터프리터/pip를 쓰는지 경로로 확인**할 것.
- pyenv + .venv 조합에서는 `pip3` 단독 사용이 함정. `.venv/bin/pip` 를 쓰거나 활성화 먼저.
