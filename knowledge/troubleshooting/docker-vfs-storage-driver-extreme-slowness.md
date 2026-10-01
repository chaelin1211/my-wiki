---
type: troubleshooting
tags: [docker, storage-driver, performance, deployment]
created: 2026-08-28
updated: 2026-08-28
---

# 도커가 비정상적으로 느리면 스토리지 드라이버부터 본다

## 증상

- 4GB 이미지 `docker load` 가 **수 시간** 걸린다 (overlay2 면 5~10분)
- `docker compose up` 이 컨테이너 하나 만드는 데 10~30분
- 디스크 사용량이 이미지 크기의 수 배로 불어난다
- `docker load` 중 `dockerd` 가 CPU 수백 %를 점유한다

## 판별

```bash
docker info --format '{{.Driver}}'
```

`vfs` 가 나오면 이것이다. `overlay2` 면 다른 원인을 찾아야 한다.

## 원인

`vfs` 는 레이어를 겹쳐 보여주지 못하고 **레이어마다 전체를 복사**한다.
레이어가 20개면 이미지를 20번 복사하는 셈이다.

| | overlay2 | vfs |
|---|---|---|
| 레이어 처리 | 참조(union mount) | **전체 복사** |
| 이미지 적재 | 수 분 | 수 시간 |
| 컨테이너 생성 | 즉시 | **이미지 전체 재복사** |
| 디스크 | 이미지 크기 | 수 배 |

**`vfs` 는 일부러 고르는 드라이버가 아니다.** overlay2 를 쓸 수 없을 때 떨어지는
폴백이다. 흔한 이유는 오래된 커널(EL7 계열), docker root 가 NFS 위, rootless 구성이다.

## 대응

**rootless 라면 사용자가 직접 바꿀 수 있다.** `fuse-overlayfs` 가 설치돼 있으면
overlay2 에 준하는 성능이 나온다.

```bash
command -v fuse-overlayfs
mkdir -p ~/.config/docker
echo '{"storage-driver":"fuse-overlayfs"}' > ~/.config/docker/daemon.json
# 데몬 재시작 (systemctl --user 가 안 되면 실행 방식을 ps -fp 로 확인)
docker info --format '{{.Driver}}'
```

**rootful 이면 root 권한이 필요하다** — `/etc/docker/daemon.json` + 데몬 재시작.
다만 그 전에 왜 overlay2 가 안 되는지부터 봐야 한다.

```bash
grep overlay /proc/filesystems              # 커널 지원 여부
df -T $(docker info --format '{{.DockerRootDir}}')   # nfs 면 overlay2 불가
```

**드라이버를 바꾸면 기존 이미지는 넘어가지 않는다.** 저장 방식이 달라 변환이 안 되므로
재적재해야 한다. 바꿀 계획이면 그 전에 오래 걸리는 적재를 하지 않는 편이 낫다.

## 바꾸지 못할 때의 운용

- **`docker compose down` 대신 `restart`** — `down` 후 `up` 은 컨테이너 재생성이라
  이미지 전체를 다시 복사한다
- **`--force-recreate` 는 정말 필요할 때만** — compose 설정(이미지·user·볼륨·환경변수)이
  바뀐 경우에만 필요하다. **파일 내용이나 권한 변경은 재생성이 필요 없다.**
  바인드 마운트는 호스트를 실시간으로 본다
- **생성 중 `Ctrl+C` 금지** — 복사한 것이 통째로 날아가고, 이름만 예약된 유령
  컨테이너가 남아 `Conflict. The container name ... is already in use` 가 뜬다
  (`docker rm` 은 `No such container` 로 실패한다. 이름을 바꾸거나 데몬을 재시작해야 한다)

## 진행 여부 판정

`docker load` 는 **출력이 터미널이 아니면 진행률을 찍지 않는다.** nohup 리다이렉트
상태에서 로그가 비어 있는 것은 정상이다. 판정은 디스크로 한다.

```bash
D=$(docker info --format '{{.DockerRootDir}}')
df "$D"; sleep 60; df "$D"      # Used 가 늘면 진행 중
```

## 함정

- **`docker load` 는 tar 를 끝까지 읽어야 이미지가 등록된다.** 중간에 끊기면
  `docker images` 에 아무것도 안 남는다. 세션이 끊길 때마다 재시도하면
  가장 큰 레이어를 영원히 못 끝낸다 → 반드시 `nohup`/`tmux` 로 띄운다
- **같은 파일을 여러 번 `docker load` 하면 서로 방해한다.** 재시도 전에
  `ps aux | grep "docker load"` 로 중복을 정리한다
- **`setsid` 로 띄우면 셸이 즉시 `Done` 을 보고한다.** 작업이 끝난 것이 아니다

## 관련 페이지

- [[rootless-docker-uid-mapping-inverted]]
- [[docker-buildx-cache-unbounded-growth-fills-disk]]
