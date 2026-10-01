---
type: troubleshooting
tags: [docker, docker-compose, 로그, timezone]
created: 2026-08-18
---

# docker compose logs --since 가 옛날 로그를 계속 다시 뱉을 때

## 증상

- 대기 루프에서 `--since` 로 "새 줄만" 가져오려 했는데 매 회차 같은 로그가 통째로 다시 나온다
- 반대로 아무것도 안 나오는 경우도 있다

## 원인

`--since` 에 **타임존 없는** 타임스탬프를 주면 도커가 그 값을 **호스트의 지역 시간**으로
해석한다. UTC 로 만든 값을 그대로 넘기면 시차만큼 어긋난다.

```bash
since="$(date -u +%Y-%m-%dT%H:%M:%S)"   # ← Z 가 없다
```

한국(UTC+9)에서는 이 값이 9시간 **과거**로 읽혀 지난 9시간치를 매번 다시 출력한다.
UTC 보다 뒤진 지역에서는 미래로 읽혀 아무것도 안 나온다.

## 해결

UTC 임을 명시한다.

```bash
since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"    # UTC
since="$(date +%Y-%m-%dT%H:%M:%S%:z)"     # 지역 시간 + 오프셋
```

## 곁들여

새 줄만 이어 보려면 **가져오기 직전에** 다음 기준 시각을 잡는다. 조회가 끝난 뒤에 잡으면
조회하는 사이에 찍힌 줄이 영구히 빠진다.

```bash
next_since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
new_logs="$(docker compose logs --no-color --since "$since" backend)"
since="$next_since"
```
