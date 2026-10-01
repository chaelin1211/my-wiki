---
type: troubleshooting
tags: [docker, permissions, deployment]
created: 2026-08-04
updated: 2026-08-26
---

# 바인드 마운트한 폴더에 컨테이너가 쓰지 못할 때

## 증상

- 로그 파일이 생기지 않는다
- 앱이 설정 파일을 저장하지 못한다 (오류 없이 조용히 실패하기도 함)
- 이미지에서는 잘 되던 것이 마운트만 붙이면 안 된다

## 원인

컨테이너 안 프로세스의 **uid**와 호스트 폴더 소유자의 **uid**가 다르면 커널이
쓰기를 거부한다. 리눅스는 계정 **이름**이 아니라 **번호**로 권한을 판단하므로,
컨테이너 안의 `appuser` 와 호스트의 `deploy` 가 각각 1005·1000 이면 남남이다.

**이미지에서 설정한 권한은 소용없다.** 마운트하면 컨테이너 안 디렉토리가
호스트 디렉토리로 **대체**되어, `Dockerfile` 의 `chmod 777` 이나 `chown` 은
가려진다.

```
Dockerfile:  RUN chmod 777 -R /app/data     ← 마운트하면 이 설정은 보이지 않음
compose:     ./data:/app/data               ← 호스트 폴더의 권한이 적용됨
```

## 해결 방법

### 1. 엔트리포인트에서 정리 후 권한 강등 (권장)

root 로 시작해 소유권을 맞춘 뒤 앱 계정으로 내려간다. `postgres`·`mariadb`
공식 이미지가 쓰는 방식이다.

```sh
#!/bin/sh
set -e
APP_UID=1005

# --user 로 띄워 root 가 아니면 그대로 실행 (기존 방식과 호환)
[ "$(id -u)" != "0" ] && exec "$@"

for dir in /app/config /app/log; do
    [ -d "$dir" ] || mkdir -p "$dir"
    # 이미 맞으면 건너뛴다 — 파일이 많을 때 매 기동 재귀 chown 은 비싸다
    [ "$(stat -c '%u' "$dir")" = "$APP_UID" ] || chown -R "$APP_UID:$APP_UID" "$dir"
done

exec setpriv --reuid="$APP_UID" --regid="$APP_UID" --clear-groups "$@"
```

`Dockerfile` 에서 `USER` 를 **지정하지 않아야** 한다(root 로 시작해야 하므로).

- `gosu` 가 없으면 `setpriv`(util-linux)로 대체 가능 — 대부분의 데비안 계열
  이미지에 이미 들어 있다
- 부작용: `docker exec` 가 root 로 들어간다. 작업 시 `-u <계정>` 을 붙일 것.
  그러지 않으면 마운트 폴더에 root 소유 파일이 생겨 앱이 손대지 못한다

### 2. 실행 uid 를 호스트에 맞추기

```yaml
services:
  app:
    user: "${APP_UID}:${APP_GID}"    # 설치 시 id -u / id -g 로 채움
```

Airflow(`AIRFLOW_UID`)가 쓰는 방식. 이미지 수정이 필요 없지만:

- 설치자가 root 면 컨테이너도 root 로 돈다
- 컨테이너 안에 그 uid 계정이 없어 `getpwuid()` 를 호출하는 라이브러리가
  들어오면 깨진다
- 이미지 내부 경로가 누구나 쓸 수 있게 열려 있어야 한다

### 3. named volume 사용

도커가 이미지의 디렉토리 소유권을 그대로 복사해 초기화하므로 문제가 없다.
대신 호스트에서 파일을 직접 보기 어려워, 운영자가 로그를 열람해야 하는
상황에는 맞지 않는다.

## 판단 기준

| 상황 | 선택 |
|---|---|
| 제품으로 배포, 설치자 환경을 모름 | 1 (엔트리포인트) |
| 호스트에서 파일을 자주 직접 편집 | 2 (uid 맞추기) |
| 로그·설정을 호스트에서 볼 필요 없음 | 3 (named volume) |

## 확인 방법

```bash
docker top <컨테이너>                    # 실제 실행 uid
stat -c '%u %g %a' <호스트 폴더>          # 호스트 소유자·권한
docker run --rm --user 1000:1000 <이미지> id   # 다른 uid 로 뜨는지 시험
```

## 읽기도 똑같이 막힌다 — `:ro` 마운트의 사각지대

위 내용은 "쓰지 못한다" 로 시작하지만, **읽기도 같은 규칙**이다. 그리고 읽기 전용
마운트에는 1번(엔트리포인트 chown)이 **적용되지 않는다.**

```yaml
- ${MODEL_DIR:-./models}:/app/models:ro    # chown 대상으로 넣어도 ro 라 실패한다
```

그래서 다른 마운트는 전부 기동 시 자가치유되는데 **`:ro` 마운트만 호스트 권한에
그대로 노출**되는 비대칭이 생긴다. 엔트리포인트 chown 목록을 짤 때 "여기 없는 경로는
호스트 권한이 그대로다" 를 반드시 같이 문서화할 것.

주의할 점 둘.

- **파일이 아니라 상위 디렉터리의 `x`(통과) 권한**이 먼저 걸린다.
  `config.json` 이 `644` 여도 상위가 `750` 이고 소유자가 다르면 안 보인다
- **읽기 실패는 조용하다.** `os.path.isfile()` 류는 권한 부족을 예외가 아니라
  `False` 로 돌려주므로, "파일이 없다" 는 로그로 위장된다
  → [[knowledge/troubleshooting/exists-check-masks-permission-denied]]

조치는 root 가 필요 없다. `chmod` 은 **소유자**면 가능하다(`chown` 만 root 필요).

```bash
chmod -R a+rX <마운트할 폴더>    # 대문자 X = 디렉터리에만 실행권한
```

특정 UID 를 겨냥하지 않으므로 rootless Docker 든 아니든 통한다.

## 함정: 개발 환경에서는 안 드러난다

이 부류의 버그는 **두 가지 이유로 개발 중에 안 보인다.**

1. **맥(colima/Docker Desktop)은 바인드 마운트 권한을 강제하지 않는다.**
   `chmod o-rx` 를 걸어도 컨테이너가 그대로 읽는다 → [[knowledge/tools/colima]]
2. **리눅스 개발 서버라도 UID 가 우연히 일치하면 안 걸린다.** 압축을 푼 계정의 UID 가
   마침 앱 UID 와 같으면 owner 비트로 읽히므로, other 비트를 꺼도 아무 일이 없다.
   재현 시험을 하려면 소유자를 **다른 UID 로 바꾼 뒤** other 비트를 꺼야 한다

```bash
stat -c '%u %g %a %n' <폴더>      # 개발 서버가 앱 UID 와 같은지부터 확인
sudo chown -R 1000:1000 <폴더> && chmod -R o-rx <폴더>   # 유효한 재현
```

## 진단은 "앱 계정" 으로

`docker compose exec` 는 entrypoint 를 거치지 않아 **root 로 들어간다.**
root 로 `ls` 가 되는 것은 아무 근거가 되지 못한다.

```bash
docker compose exec -u <앱UID> <서비스> ls -l /경로   # 앱 시점
docker compose exec -u 0        <서비스> ls -l /경로   # 대조군
docker compose exec <서비스> ps -o uid,cmd | head      # 실제 실행 UID (exec ... id 아님)
docker info | grep -iE "rootless|userns"              # UID 매핑 예외 여부
```

`-u <앱UID>` 만 실패하면 권한 확정이다.

## 계정 "이름" 과 "번호"

컨테이너의 `appuser` 라는 **이름**은 그 이미지의 `/etc/passwd` 에만 있다.
반면 **번호(UID)** 는 커널 차원의 값이라 호스트와 그대로 공유된다. 그래서

- 호스트에 그 번호의 계정이 없어도 `chown 1005:1005` 는 유효하다
- 호스트에서 `ls -ln` 으로 보면 이름 대신 숫자가 그대로 보인다

**예외는 rootless Docker 와 userns-remap** 뿐이다. 이때는 커널이 컨테이너 UID 를
호스트의 다른 번호로 변환해 검사하므로 "숫자가 그대로 통한다" 는 전제가 깨진다.

## 참고

- 사례: [[projects/dna-sql-agent/decisions/031-container-mount-ownership-entrypoint]]
- 사례(읽기·`:ro`): [[projects/dna-sql-agent-deploy/issues/embedding-model-not-found-despite-correct-mount]]
