---
type: troubleshooting
tags: [docker, rootless, permissions, deployment]
created: 2026-08-28
updated: 2026-08-28
---

# rootless Docker 에서는 UID 상식이 반대다

## 증상

- 호스트 파일 소유자가 `101004` 처럼 **호스트에 없는 큰 숫자**로 보인다
  (`ls -l` 이 이름 대신 번호를 찍는다)
- `--user $(id -u):$(id -g)` 로 실행했는데 여전히 내 계정 소유가 아니다
- `sudo` 없이 `chown` 이 안 되는데, 담당자에게 물으면 "권한 처리 했다" 고 한다
- `docker info` 의 Storage Driver 가 `vfs` 다 (동반 증상)

## 판별

```bash
ps -fp $(pgrep -x dockerd)     # dockerd 가 root 가 아니라 사용자 소유면 rootless
docker info 2>/dev/null | grep -iE "rootless|security opt"
cat /etc/subuid | grep $USER   # 예: myuser:100000:65536
```

`dockerd` 실행 계정 하나만 봐도 대부분 판별된다.

## 원인

rootless Docker 는 user namespace 로 UID 를 **변환**한다. 그대로 쓰지 않는다.

| 컨테이너 안 UID | 호스트에서 보이는 UID |
|---|---|
| **0 (root)** | **데몬을 띄운 사용자** (예: 1000) |
| 1 이상 | subuid 범위 (보통 100000 + N - 1) |

그래서 `/etc/subuid` 가 `myuser:100000:65536` 이면 컨테이너 UID 1005 는
호스트에서 `101004` 로 보인다. 호스트에 그런 계정이 없으니 숫자로만 표시된다.

**핵심 역전:** 호스트에서 내 계정 소유로 만들려면 컨테이너를 **root 로** 돌려야 한다.

| 환경 | 호스트 소유권을 내 계정으로 |
|---|---|
| rootful Docker | `--user $(id -u):$(id -g)` |
| **rootless Docker** | **`--user 0:0`** |

직관과 반대라 여기서 많이 헤맨다.

## sudo 없이 소유권·권한 고치기

rootless 에서는 사용자가 subuid 범위의 주인이므로, 컨테이너를 경유하면
`sudo` 없이 `chown`/`chmod` 가 된다.

```bash
# 호스트 소유권을 내 계정으로 (컨테이너 0:0 → 호스트 나)
docker run --rm -u 0:0 --entrypoint chown \
  -v "$PWD":/mnt <아무_이미지> -R 0:0 /mnt

# 권한만 열기
docker run --rm -u 0:0 --entrypoint chmod \
  -v "$PWD":/mnt <아무_이미지> -R go+rX /mnt
```

`--entrypoint` 를 반드시 지정한다. 엔트리포인트가 있는 이미지(nginx, postgres 등)에
그냥 명령을 넘기면 인자로 먹혀서 엉뚱하게 동작한다.

`-v` 의 콜론 **왼쪽만** 호스트 절대경로다. 오른쪽 `/mnt` 는 컨테이너 안에서만
존재하는 이름이라 바꿀 필요가 없다.

## 함정

- **`user: "0:0"` 을 줘도 앱은 non-root 로 돌 수 있다.** 그 설정은 *첫 프로세스*만
  root 로 만든다. 엔트리포인트가 마운트를 chown 한 뒤 `gosu`/`setpriv` 로 계정을
  낮추는 구조가 흔하다 (공식 postgres 가 대표적).
  `docker exec ... id` 는 `Config.User` 를 쓰므로 root 로 나온다 — **실제 앱 계정은
  `docker top` 의 USER 열**을 봐야 한다
- **엔트리포인트가 chown 하는 폴더는 건드려도 재기동 시 원복된다.** 되돌리는 것은
  헛수고다. 반면 **`:ro` 마운트는 컨테이너가 chown 할 수 없어** 자가치유가 안 되고,
  거기를 잘못 만지면 복구되지 않는다
- 이미지 기본 USER 가 root 면 `user: "0:0"` 은 있으나 없으나 같다

## 관련 페이지

- [[docker-bind-mount-uid-mismatch]]
- [[docker-vfs-storage-driver-extreme-slowness]]
- [[exists-check-masks-permission-denied]]
