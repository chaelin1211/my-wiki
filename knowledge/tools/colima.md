---
type: knowledge
tags: [docker, colima, macos, devops]
created: 2026-07-24
updated: 2026-08-26
---

# Colima (macOS Docker 데몬)

Docker Desktop 대신 쓰는 경량 대안. `docker` CLI는 그대로 쓰고, Colima는 백그라운드 VM
안에서 Docker 데몬을 띄워주는 역할만 한다.

## 기본 명령

| 명령 | 용도 |
|------|------|
| `docker exec -it <컨테이너ID> bash` | 컨테이너 안 진입 — Docker Desktop과 완전히 동일 |
| `colima ssh` | 컨테이너가 아니라 VM 자체(호스트 OS)에 SSH 접속 |
| `colima status` / `colima list` | VM 상태, CPU/메모리 리소스 확인 |
| `colima start --memory 8 --cpu 4` | 리소스 조정 (기존 인스턴스에도 적용됨, `vm-type`은 재생성 없이는 변경 불가) |

## 트러블슈팅: `failed to run attach disk ..., in use by instance`

`colima start`가 `vz` 드라이버(Apple Virtualization.framework)에서 이 에러로 기동 자체가
안 되는 경우가 있다.

- `ps aux | grep -i -E "colima|lima|Virtualization"`로 좀비 프로세스(특히
  `com.apple.Virtualization.VirtualMachine.xpc`)를 찾아 `kill -9` — 이걸로 풀리기도 함
- `lsof`/`fcntl.flock`으로 확인해도 실제로 파일을 잡고 있는 프로세스가 없는데도 에러가
  반복되면, macOS 재부팅으로도 항상 풀리는 건 아니었음(이번 사례에서는 재부팅 후에도 재발)
- **확실한 해결책**: `colima delete` 후 `colima start`로 재생성. 호스트 파일에는 영향
  없음 — VM 내부 도커 이미지·캐시만 날아가서 다시 받아야 함

## 기본 리소스가 작음 — 무거운 빌드 시 OOM 주의

기본 메모리 2GiB. `docker build`로 무거운 컴파일(예: Nuitka로 torch 포함 전체 컴파일)을
돌리면 `exit 137`(OOM kill)로 죽는다. `colima start --memory 8 --cpu 4`처럼 올려야 함 —
그래도 부족하면 컴파일 대상 자체를 줄이는 게 근본 해결(예:
[[projects/dna-sql-agent/decisions/027-nuitka-source-compilation]] 참고).

## 바인드 마운트 권한이 강제되지 않는다 — 리눅스 전용 버그를 못 잡는다

맥의 호스트 폴더는 VM 을 한 겹 거쳐 컨테이너에 들어온다. 이 과정에서 **UID·권한이
그대로 전달되지 않아**, 호스트에서 `chmod o-rx` 를 걸어도 컨테이너가 그대로 읽는다.

즉 **바인드 마운트 권한 문제는 맥에서 구조적으로 재현되지 않는다.**
"내 맥에서는 되는데 고객사 리눅스에서만 안 된다" 의 흔한 원인이다.

```bash
# 맥에서는 이 시험이 통과해버린다 (권한이 안 걸림)
chmod o-rx ./models && docker compose restart backend
```

리눅스와 같은 조건으로 시험하려면 VM 안 파일시스템에 두고 돌려야 한다.

```bash
colima ssh          # VM(리눅스) 자체로 진입
```

같은 이유로 **라이선스 머신 바인딩 검증도 맥에서는 불가**하다.
`/etc/machine-id`·`/proc` 가 없어 도커 VM 값이 들어오고 호스트와 다르다.

정리하면, 아래 항목은 **반드시 리눅스에서 검증**해야 한다.

| 항목 | 이유 |
|---|---|
| 바인드 마운트 권한·소유권 | 맥에서 권한이 강제되지 않음 |
| 라이선스 머신 바인딩 | `/etc/machine-id`·`/proc` 부재 |
| `linux/amd64` 성능 | Apple Silicon 에서는 QEMU 에뮬레이션 |

## 관련 페이지

- [[knowledge/troubleshooting/docker-bind-mount-uid-mismatch]]
- 사례: [[projects/dna-sql-agent-deploy/issues/embedding-model-not-found-despite-correct-mount]]
