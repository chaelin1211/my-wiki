---
type: troubleshooting
project: dna-sql-agent
date: 2026-07-28
resolved: true
root-cause: "docker buildx 빌드 캐시가 자동 상한/GC 없이 149.7GB까지 무제한 누적되어 루트 파티션(818G) 소진"
related: []
tags: [docker, ci, self-hosted-runner, disk]
---

# self-hosted GitHub Actions 러너(sdn04) 디스크 풀 — buildx 캐시 누적

## 증상

`sdn04` self-hosted 러너에서 워크플로우 실행 중 러너 워커 프로세스가 통째로 크래시:

```
System.IO.IOException: No space left on device : '/home/dnadev/actions-runner/_diag/Worker_*.log'
```

`df -h /` 확인 결과 `/dev/sda3 818G 780G 0 100% /` — 루트 파티션 완전 소진.

## 환경

- self-hosted GitHub Actions 러너, 호스트 `sdn04`
- `/home/dnadev/actions-runner`
- 러너 위에서 `docker buildx`로 이미지 빌드(Nuitka 컴파일 포함, [[decisions/027-nuitka-source-compilation]])

## 시도한 것들

1. `sudo du -h -x -d 1 / | sort -rh` — 상위 디렉토리별 용량 확인. `/home` 278G, `/var` 7.3G,
   `/usr` 16G, `/opt` 213M로 합계 약 301G. **실사용 780G와 약 480G 갭 발생, 원인 특정 실패.**
2. `sudo lsof +L1 | grep -i deleted` — 삭제됐지만 프로세스가 물고 있는 파일 확인.
   - `run.sh (deleted)` 2.8KB — 러너 자체 업데이트 잔재, 무관
   - `memfd:doublemapper (deleted)` 2TB로 찍힘 — **device가 `0,1`(RAM 기반)이라 실제 디스크
     사용량과 무관한 red herring.** .NET 런타임의 메모리 매핑 트릭이 만든 가상 크기일 뿐.
   - 이 경로로는 갭을 못 찾음 → 폐기
3. `docker buildx du` — buildx 전용 캐시 사용량 확인. **Shared 19.29GB / Private 130.4GB /
   Reclaimable 149.7GB / Total 149.7GB.** 여기서 주요 원인 확정.

## 근본 원인

`docker buildx`(BuildKit) 빌드 캐시는 `/var/lib/docker`(classic docker storage)와 별도 위치에
쌓이며, **자동 GC나 용량 상한이 기본적으로 설정돼 있지 않으면 무제한 누적된다.** `docker system
df`나 `du /var/lib/docker`만 봐서는 이 캐시가 안 잡힌다(별도 드라이버/스토리지 사용).

## 해결 방법

```
docker buildx prune -af
```

149.7GB 전량 즉시 회수.

## 예방책

- `docker buildx du`를 `docker system df`와 별개로 **정기적으로** 확인할 것 — classic docker
  storage가 작다고 안심하면 안 됨.
- self-hosted 러너에 buildx 캐시 자동 정리(cron 또는 `docker buildx build --cache-to` GC 옵션,
  buildkitd 설정의 `gcpolicy`)를 걸어 재발 방지 — 이번 세션에서는 미설정, 이월.
- 디스크가 razor-thin한 상태에서는 컨테이너에 `docker exec`로 대화형 세션을 오래 열어두는 것만으로도
  남은 여유분이 소진돼 앱이 기동 실패할 수 있음(로그 드라이버가 exec 세션 출력도 기록) — 디스크
  여유 확인 전엔 장시간 exec 세션 지양.

## 관련 페이지

- [[decisions/028-image-build-context-minimization]]
- [[knowledge/troubleshooting/docker-buildx-cache-unbounded-growth-fills-disk]]
