---
type: session-log
project: dna-sql-agent
date: 2026-07-28
duration: ""
focus: "self-hosted 러너 디스크 풀 장애 대응 + 이미지 빌드 컨텍스트 보안 강화"
tools-used: [claude-code]
outcome: success
---

# 2026-07-28 — self-hosted 러너 디스크 풀 장애 대응 + 이미지 빌드 컨텍스트 보안 강화

## 목표

self-hosted GitHub Actions 러너(sdn04)에서 `No space left on device`로 워커가 죽는 장애를
원인 규명하고 해결. 겸사겸사 배포 이미지에 불필요/민감 파일이 담기지 않도록 빌드 구조 점검.

## 수행한 작업

1. 러너 워커 크래시 로그(`System.IO.IOException: No space left on device`) 분석 → `/dev/sda3` 100% 확인.
2. `du`로 최상위 디렉토리 순차 확인(`/home` 278G, `/var` 7.3G, `/usr` 16G, `/opt` 213M) →
   합계 약 301G인데 실사용 780G와 약 480G 갭 발견.
3. `lsof +L1`로 삭제됐지만 프로세스가 물고 있는 파일 확인 시도 → `run.sh`(2.8KB), `memfd:doublemapper`
   (2TB로 찍히지만 device `0,1`=RAM 기반이라 실제 디스크와 무관, red herring으로 배제)만 발견,
   이 경로로는 갭을 못 찾음.
4. `docker buildx du`로 전환 → **buildx 캐시 149.7GB 전부 Reclaimable**로 확인, 주요 원인으로 특정.
5. `docker buildx prune -af`로 캐시 정리 안내.
6. 부가 증상: exec로 컨테이너에 bash 진입해 있는 동안 서버가 안 뜨다가 exec 종료 직후 뜸 →
   디스크 여유가 razor-thin한 상태에서 exec 세션의 로그/버퍼가 남은 여유분을 마저 소진해
   서버가 필요한 파일(소켓/pid/임시파일)을 못 쓰고 재시도만 반복했던 것으로 추정 (`ENOSPC` 계열).
7. `Dockerfile` 점검 중 `.dockerignore`가 아예 없고 최종 스테이지 `COPY . $HOME/`가 `docs/`,
   `.git/`, 테스트 등 레포 전체를 이미지에 그대로 담고 있는 것 확인.
8. `.dockerignore` 신설 (`docs`, `.git`, `.github`, `.claude`, `venv`, `__pycache__`, `tests` 등 제외).
   커밋(`08a57bb`, `feat/nuitka`) 후 push 완료.
9. `requirements.txt`를 최종 이미지에서 빼고 싶다는 요청 → `.dockerignore`로는 처리 불가(빌더
   스테이지 `COPY requirements.txt .`가 깨짐) 설명. 단순 `COPY` 후 `RUN rm`도 레이어 히스토리에
   파일이 남아 보안 목적 달성 못 함 → **버려지는 중간 스테이지에서 걸러내는 패턴** 제안
   (`FROM ... AS context` → 파일 복사·제거 → 최종 스테이지는 `COPY --from=context`만 사용).
   실제 `Dockerfile` 반영은 사용자 확인 대기 중 세션 종료.

## 핵심 결정

- **결정 1:** 배포 이미지 빌드 컨텍스트에서 `docs/`, `.git/`, 테스트 등 런타임 불필요 파일을
  `.dockerignore`로 제외한다.
  → ADR: [[decisions/028-image-build-context-minimization]]
- **결정 2 (설계만, 미적용):** `requirements.txt` 등 최종 이미지 레이어 히스토리에도 안 남겨야
  하는 파일은 `.dockerignore`가 아니라 버려지는 중간 스테이지(`AS context`)에서 제거하는 패턴을
  쓴다 — `.dockerignore`는 빌드 전체 컨텍스트에 적용돼 builder 스테이지의 필수 `COPY`까지 깨뜨림.
  → 지식: [[knowledge/patterns/docker-multistage-context-stage-strip-secrets]]

## 배운 것

- `du -h -d 1`은 출력만 depth 1이지 스캔은 항상 전체 재귀 — 큰 디스크에서 체감상 "멈춘 것"처럼
  느껴지는 게 정상. `ncdu`나 `docker buildx du` 같은 스코프 좁힌 도구가 훨씬 빠름.
- `docker buildx du`의 Id는 컨테이너/이미지 ID와 다른 네임스페이스(빌드 캐시 블롭). `docker rm`/
  `rmi`로 안 지워지고 `docker buildx prune`만 먹힘.
- `lsof +L1`의 `memfd:*` 항목은 RAM 기반이라 크기가 터무니없이 커도(TB 단위) 디스크 사용량과
  무관 — 삭제된 실제 파일(device가 실디스크 파티션)만 봐야 함.
  → 지식: [[knowledge/troubleshooting/docker-buildx-cache-unbounded-growth-fills-disk]]

## 문제 & 해결

- **문제:** self-hosted 러너(`sdn04`)가 `No space left on device`로 워커 프로세스째 죽음.
- **원인:** `docker buildx` 빌드 캐시가 149.7GB까지 무제한 누적 (자동 GC/용량 상한 미설정).
- **해결:** `docker buildx prune -af`로 즉시 회수. 재발 방지는 주기적 prune 또는 buildx
  `--gc` / 캐시 상한 설정 필요(이번 세션에선 미설정, 이월).
  → 이슈: [[issues/self-hosted-runner-disk-full-buildx-cache]]

## 다음 할 일

- [ ] `Dockerfile`에 `requirements.txt` 등을 위한 `context` 스테이지 실제 반영 (사용자 승인 대기 중이었음)
- [ ] self-hosted 러너(`sdn04`) buildx 캐시 자동 정리(cron 또는 `--gc` 옵션) 설정 — 재발 방지
- [ ] self-hosted 러너에서 실제 빌드 검증 (기존 이월 항목, 이번 세션에서 디스크 문제로 계속 막혀있었음 — 공간 확보했으니 재시도 가능)
- [ ] `.env`가 컨테이너 런타임에 파일로 직접 읽히는지 확인 후 `.dockerignore`에서 `.env` 제외 여부 재검토

## 효과적이었던 프롬프트

```
sudo du -h -x -d 1 / | sort -rh | head -20   # 대신 정렬 없이 바로 실행해서 실시간으로 보는 게 체감 속도 훨씬 나음
docker buildx du | grep -i total              # 전체 목록 대신 요약만 뽑기
```
