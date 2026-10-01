---
tags: [docker, buildx, disk, ci]
related: []
---

# docker buildx 캐시 무제한 누적 → 디스크 풀

## 증상

`df -h`로 보면 파티션이 100% 찼는데, `docker system df`나 `du /var/lib/docker`를 봐도 원인이
안 잡힘. self-hosted CI 러너 등 반복적으로 `docker build`/`docker buildx build`를 돌리는
환경에서 서서히 발생.

## 원인

`docker buildx`(BuildKit)의 빌드 캐시는 classic docker storage(`/var/lib/docker`)와 **별도
위치·별도 드라이버**에 저장된다. 자동 GC나 캐시 상한을 명시적으로 설정하지 않으면 빌드를 돌릴
때마다 무제한 누적된다. `docker system df`는 이 캐시를 잡아주지 않으므로 "docker는 안 크던데
디스크는 왜 꽉 찼지" 하는 혼란이 생기기 쉽다.

## 진단

```
docker buildx du          # buildx 전용 캐시 사용량 (Shared/Private/Reclaimable/Total)
docker buildx du | grep -i total
```

`Reclaimable`이 크면 이게 원인.

## 해결

```
docker buildx prune -af
```

## 예방

- `docker system df`뿐 아니라 `docker buildx du`도 정기 점검 대상에 포함
- buildkitd 설정의 `gcpolicy`(캐시 상한)를 걸어 자동 정리되게 하거나, cron으로 주기적
  `docker buildx prune` 실행
- 디스크 여유가 거의 없는 상태에서는 `docker exec`로 컨테이너에 오래 붙어 있는 것만으로도
  (로그 드라이버가 exec 세션 출력까지 기록) 남은 여유분이 소진돼 다른 프로세스가 `ENOSPC`로
  기동 실패할 수 있음 — 디스크 조사 중엔 불필요한 대화형 세션을 오래 띄워두지 않기

## 관련 페이지

- [[projects/dna-sql-agent/issues/self-hosted-runner-disk-full-buildx-cache]]
