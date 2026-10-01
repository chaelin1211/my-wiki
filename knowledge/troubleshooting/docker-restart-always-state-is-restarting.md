---
type: troubleshooting
tags: [docker, docker-compose, 헬스체크]
created: 2026-08-18
---

# 기동 실패를 exited 로 잡으면 한 번도 안 걸린다

## 증상

컨테이너가 기동에 실패하는데, 그걸 감지하려고 넣은 상태 검사가 전혀 동작하지 않는다.
대기 루프가 타임아웃(예: 15분)을 다 채운 뒤에야 실패를 알린다.

## 원인

`restart: always` (또는 `unless-stopped`) 가 걸려 있으면 도커가 곧바로 다시 띄우므로
상태가 `exited` 로 머무르지 않는다. 크래시 루프 중인 컨테이너는 **`restarting`** 으로 보인다.

```bash
docker run -d --restart always --name t alpine sh -c 'exit 1'
docker inspect t --format '{{.State.Status}}'
# → restarting
```

## 해결

`restarting` 을 함께 잡는다.

```bash
state="$(docker compose ps -a --format '{{.Service}} {{.State}}' | awk '$1=="backend"{print $2}')"
if [[ "$state" == "exited" || "$state" == "dead" || "$state" == "restarting" ]]; then
  ...
fi
```

`restarting` 은 이미 한 번 죽었다는 뜻이므로 오탐 위험이 낮다. 더 엄격하게 보려면
`.RestartCount` 증가를 본다.
