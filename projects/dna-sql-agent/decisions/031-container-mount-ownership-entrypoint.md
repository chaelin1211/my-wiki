---
type: decision-record
project: dna-sql-agent
date: 2026-08-04
status: accepted
superseded-by: ""
tags: [docker, permissions, deployment]
---

# ADR-031: 마운트 폴더 소유권을 엔트리포인트에서 처리

## 맥락

컨테이너는 `dnadev`(uid 1005)로 실행된다. 이 번호는 **우리 개발 서버의
`dnadev` 계정 번호**에 맞춘 값이라(`Dockerfile`), 고객사 설치 계정과 같을
이유가 없다.

바인드 마운트한 `config/`·`log/` 는 설치한 계정 소유로 컨테이너에 들어온다.
번호가 다르면 앱이 쓰지 못해 **로그가 안 쌓이고 관리자 화면의 설정 저장이
실패**한다.

사내 3개 사이트는 호스트 계정이 1005 라 우연히 일치해 이 문제가 드러나지
않았다. 고객사에서 처음 터질 값이었다.

이미지의 `chmod 777 -R $HOME` 은 도움이 되지 않는다. 마운트하면 컨테이너 안
폴더가 호스트 폴더로 **대체**되어 이미지에 설정한 권한이 가려지기 때문이다.

## 선택지

### 옵션 A: 설치자가 `sudo` 로 미리 `chown`
- **장점:** 이미지 수정 불필요
- **단점:** `init.sh` 를 `sudo` 로 돌리면 `.env` 가 root 소유가 되어 이후
  `start.sh` 가 읽지 못한다. 설치 폴더 밖 경로(`/var/log` 등)에 재귀 `chown`
  하면 시스템을 망가뜨릴 수 있어 방어 로직이 계속 늘어난다
- **비용/노력:** 낮지만 부작용이 연쇄

### 옵션 B: 컨테이너를 설치자 uid 로 실행 (`user:` 오버라이드)
- **장점:** 이미지 수정 불필요. 호스트 파일이 설치자 소유라 `config/` 를
  직접 편집할 수 있다
- **단점:** 설치자가 root 면 컨테이너가 root 로 돈다. 컨테이너 안에 그 uid 의
  계정이 없어 `getpwuid()` 를 쓰는 라이브러리가 추가되면 깨진다.
  `chmod 777` 에 의존하며, 설치자와 운영자가 다르면 다시 어긋난다
- **비용/노력:** 낮음

### 옵션 C: 엔트리포인트가 root 로 시작해 소유권을 맞춘 뒤 권한 강등
- **장점:** uid 가 1005 로 진짜 고정된다. 설치자는 아무것도 안 한다.
  A·B 의 문제를 구조적으로 겪지 않는다
- **단점:** `Dockerfile` 수정 필요. 호스트 파일이 1005 소유가 되어
  `config/` 직접 편집에 `sudo` 가 필요하다. `USER` 를 비우므로
  `docker exec` 가 root 로 들어간다
- **비용/노력:** 중간

## 결정

**옵션 C** — `docker-entrypoint.sh` 를 이미지에 넣는다.

```sh
# root 가 아니면 그대로 실행 (--user 로 띄우는 기존 방식과 호환)
[ "$(id -u)" != "0" ] && exec "$@"

for dir in "$HOME/config" "$HOME/log"; do
    owner="$(stat -c '%u' "$dir")"          # 이미 맞으면 건너뜀
    [ "$owner" != "1005" ] && chown -R 1005:1005 "$dir"
done

exec setpriv --reuid=1005 --regid=1005 --clear-groups "$@"
```

`gosu` 대신 `setpriv` 를 쓴다 — 베이스 이미지의 util-linux 에 이미 들어 있어
패키지 추가가 필요 없다.

## 근거

같은 문제를 가진 공식 이미지들을 직접 열어 확인했다.

| 이미지 | 소유권 정리 | 권한 강등 |
|---|---|---|
| `postgres:16` | `find $PGDATA \! -user postgres -exec chown` (58행) | `exec gosu postgres` (343행) |
| `mariadb:11` | `find $DATADIR \! -user mysql -exec chown` (210행) | `exec gosu mysql` (699행) |
| `redis:alpine` | 파일 단위 chown | 없음 — root 로 계속 실행 |
| `nginx:alpine` | 없음 | 앱 자체 기능(마스터 root, 워커 nginx) |

**"업계 표준"이라기보다 데이터를 마운트로 받는 이미지들이 쓰는 검증된 방식**
이다. `find \! -user` 로 이미 맞는 것은 건너뛰는 최적화까지 동일하다.

## 결과

- 설치 절차에서 `sudo`·`chown` 이 사라졌다. `init.sh` 의 소유권 로직 63줄 제거
- `config/`·`log/` 는 기동 후 1005 소유가 되므로 직접 편집에는 `sudo` 가
  필요하다. `INSTALL.txt` 에 명시
- `USER` 를 비웠으므로 `docker exec` 는 root 로 들어간다. 그 상태로 마운트
  폴더에 파일을 만들면 앱이 수정하지 못하므로 `docker exec -u dnadev` 를
  쓰도록 README 에 안내
- 사내 3개 사이트는 `--user` 없이 `docker run` 하므로 root 로 시작해 chown 을
  건너뛰고(이미 1005) 1005 로 실행된다 — 동작 확인함

## 관련

- 세션: [[projects/dna-sql-agent/sessions/2026-08-04-customer-delivery-package]]
- 지식: [[knowledge/troubleshooting/docker-bind-mount-uid-mismatch]]
- [[projects/dna-sql-agent/decisions/030-deploy-package-separate-repo]]
