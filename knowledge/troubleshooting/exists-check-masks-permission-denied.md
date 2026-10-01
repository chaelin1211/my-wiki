---
type: troubleshooting
tags: [python, permissions, debugging, docker]
created: 2026-08-26
---

# 존재 확인 API 가 권한 오류를 "없음" 으로 뭉갠다

## 증상

- 파일이 분명히 있는데 프로그램은 "없다" 고 한다
- 로그에는 "찾을 수 없어 기본 동작으로 넘어간다" 만 찍히고 권한 이야기는 없다
- 같은 경로를 `ls` 로 보면 멀쩡하다 (단, **다른 계정으로** 봤다)

## 원인

존재 확인 계열 API 는 대부분 **권한 부족을 예외로 올리지 않고 `False` 를 돌려준다.**

```python
os.path.isfile(path)   # 권한 없으면 False (예외 아님)
os.path.exists(path)   # 마찬가지
os.path.isdir(path)    # 마찬가지
```

`stat()` 이 `EACCES` 로 실패한 것을 "없다" 로 번역해버리는 것이다. 그래서
**"파일이 없음" 과 "읽을 수 없음" 이 호출부에서 구분되지 않는다.**

디렉터리는 특히 함정이다. 파일 자체가 `644` 여도 **상위 디렉터리에 `x`(통과)
권한이 없으면** 그 아래는 통째로 안 보인다.

같은 함정이 다른 언어에도 있다.

| 언어 | 함수 | 권한 부족 시 |
|---|---|---|
| Python | `os.path.exists/isfile/isdir` | `False` |
| Node.js | `fs.existsSync` | `false` |
| Go | `os.Stat` + `os.IsNotExist(err)` | `EACCES` 를 "없음" 으로 오판하기 쉬움 |
| Shell | `[ -f "$f" ]` | 거짓 |

## 해결 방법

### 진단 — 반드시 "그 프로세스의 계정" 으로 확인

`ls` 가 되는 것은 근거가 되지 않는다. 내 계정이 아니라 **앱 계정**으로 봐야 한다.

```bash
# 컨테이너라면 (exec 는 entrypoint 를 안 거쳐 root 로 들어간다)
docker compose exec -u <앱UID> <서비스> ls -l /경로/파일
docker compose exec -u 0        <서비스> ls -l /경로/파일   # 대조군

# 실제 실행 UID 는 exec ... id 가 아니라 프로세스에서 봐야 한다
docker compose exec <서비스> ps -o uid,cmd | head
```

`-u <앱UID>` 는 실패하고 `-u 0` 은 성공하면 권한 문제 확정이다.

파이썬에서 직접 갈라보려면:

```python
import os, errno
try:
    os.stat(path)
except PermissionError:
    ...  # 못 읽는 것
except FileNotFoundError:
    ...  # 진짜 없는 것
```

### 코드 — 두 상태를 다른 로그로 남긴다

```python
if os.path.isfile(target):
    logger.info("로컬 사용: %s", target)
elif os.path.isdir(os.path.dirname(target)):
    # 폴더는 보이는데 파일이 안 보이면 권한을 의심할 근거가 된다
    logger.warning("폴더는 있으나 %s 를 볼 수 없습니다. 권한을 확인하십시오.", target)
else:
    logger.warning("%s 없음 — 대체 경로로 진행", target)
```

한 줄이라도 갈라두면 원격 고객사 로그만으로 원인이 좁혀진다.

## 왜 이게 폐쇄망/납품에서 특히 아픈가

폴백이 "인터넷에서 받는다" 인 경우, 권한 문제가 **네트워크 오류로 위장**된다.
실제로 찍히는 것은 DNS 실패이고, 진짜 원인인 권한은 어디에도 안 나온다.

```
[APP] /models/... 에 모델이 없어 huggingface.co 에서 내려받습니다   ← 권한 문제가 여기 숨는다
Failed to resolve 'huggingface.co' [Errno -3]                      ← 눈에 띄는 건 이것
```

## 예방책

- 존재 확인 결과로 **동작을 바꾸는 분기**에는 권한 케이스를 따로 로깅한다
- 설치 스크립트의 사전 점검은 **설치 계정이 아니라 실행 계정 기준**으로 한다.
  `[ -f ... ]` 를 설치자로 돌리면 이 상황을 그대로 통과시킨다
- 개발 환경이 맥이면 이 부류는 아예 재현되지 않는다
  → [[knowledge/tools/colima]]

## 관련 페이지

- [[knowledge/troubleshooting/docker-bind-mount-uid-mismatch]]
- [[knowledge/troubleshooting/absence-of-log-is-not-evidence]]
- 사례: [[projects/dna-sql-agent-deploy/issues/embedding-model-not-found-despite-correct-mount]]
