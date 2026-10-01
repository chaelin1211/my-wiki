---
type: session-log
project: dna-sql-agent-deploy
date: 2026-08-28
duration: 
focus: "고객사 폐쇄망 설치 완주 — 임베딩 모델 미탐지 원인 확정, rootless Docker·vfs 환경 규명"
tools-used: [claude-code]
outcome: success
---

# 2026-08-28 — 폐쇄망 설치 완주와 rootless Docker·vfs 환경 규명

## 목표

2026-08-26 부터 미해결로 남아 있던 고객사 임베딩 모델 미탐지 문제를 확정하고,
고객사 서버(`lhbigocrgpu01`, 계정 `pcloud`)에서 설치를 끝까지 통과시킨다.

## 수행한 작업

1. **VPN 접속 불가 규명** — `ping` timeout, `ssh -v` 가 `Connecting to` 에서 멈춤.
   VPN 터널(utun4 `172.16.0.4/23`)과 로컬 LAN(en0 `172.16.0.230/23`)의 대역이 겹쳐
   사내망 패킷이 물리 인터페이스로 새고 있었다. 핫스팟 전환으로 우회
2. **`init.sh` 중단 원인 확정** — `[2/5] 폴더 준비` 의 `[[ ! -w "$d" ]]` 에서 멈춤.
   `mkdir -p` 는 성공했고(이미 존재) 쓰기 권한만 없는 상태. 그 결과
   `[3/5] 이미지 불러오기` 가 실행되지 않아 이후 `docker compose up` 이
   레지스트리 pull 로 빠져 폐쇄망에서 실패했다
3. **rootless Docker 발견** — `ps` 에서 `dockerd` 가 `pcloud` 소유로 실행 중.
   설치 경로 `/logs/bigdata/docker-rootless-offline-el7/`.
   호스트에 보이던 UID `101004` 의 정체가 여기서 밝혀졌다 (subuid 매핑)
4. **vfs 스토리지 드라이버 발견** — EL7 커널이라 overlay2 미지원으로 폴백.
   4GB 압축 이미지 적재에 수 시간, 컨테이너 생성마다 이미지 전체 재복사
5. **이미지 적재 완료** — 중복 실행된 `docker load` 프로세스들이 서로 방해하며
   dockerd 를 237% 로 점유하고 있었다. 전부 정리하고 하나만 백그라운드로 재실행
6. **`dnasql_agent` DB 수동 생성** — postgres 공식 이미지의 `initdb` 는 데이터 폴더가
   비어 있을 때만 `CREATE DATABASE $POSTGRES_DB` 를 수행한다. 이전 시도의 잔재가 남아
   통째로 건너뛰어진 상태였다
7. **모델 권한 해소** — 컨테이너 경유로 `chmod -R go+rX models` 적용 후 기동 성공
8. **관리자 버튼 미표시 원인 규명** — 로그인·DB·`isAdmin` 모두 정상인데 버튼이 없었다.
   프론트 게이팅 조건에 `isOfficeAddin === false` 가 걸려 있고, 폐쇄망에서
   외부 office.js 가 로드되지 않아 판정이 `null` 로 남는 구조

## 핵심 결정

- **`:ro` 마운트 권한은 패키지 빌드 시점에 정규화한다** (미구현)
  `models` 는 `:ro` 라 컨테이너가 자가치유(chown)할 수 없다. 고객사에서 `chmod` 가
  불가능한 계정일 수도 있으므로, 런타임 조치가 아니라 `package.sh` 에서
  `chmod -R a+rX "$MODEL_STAGE"` 로 애초에 열어 보내는 것이 정본이다.
  `init.sh` 쪽 보정은 실패해도 진행되는 보조 수단으로만 둔다
- **rw 마운트의 소유권은 건드리지 않는다**
  `config`·`log`·`data`·`hf_cache` 는 컨테이너 엔트리포인트가 기동할 때마다
  자기 계정으로 chown 한다. 담당자가 101004 로 맞춰둔 것은 고장이 아니라 정상 동작이며,
  pcloud 로 되돌려도 재기동 시 원복된다

## 배운 것

- **rootless Docker 는 UID 상식이 반대다.** 컨테이너 UID 0 → 호스트 사용자,
  컨테이너 UID 1+ → subuid(100000번대). 따라서 호스트 소유권을 내 계정으로 맞추려면
  rootful 의 `--user $(id -u)` 가 아니라 **`--user 0:0`** 을 써야 한다
- **sudo 없이도 소유권·권한을 고칠 수 있다.** rootless 는 pcloud 가 subuid 범위의
  주인이므로, 컨테이너를 경유하면 된다:
  `docker run --rm -u 0:0 --entrypoint chown -v "$PWD":/mnt <이미지> -R 0:0 /mnt`
- **vfs 는 일부러 고르는 드라이버가 아니다.** overlay2 가 안 될 때 떨어지는 폴백이다.
  EL7 커널 + rootless 조합에서 흔하며, `fuse-overlayfs` 가 정답이다
- **`docker load` 는 tar 하나를 끝까지 읽어야 이미지가 등록된다.** 중간에 끊기면
  `docker images` 에 아무것도 안 남는다. 세션이 끊길 때마다 재시도하면 영원히 못 끝낸다
- **`docker load` 는 출력이 터미널이 아니면 진행률을 찍지 않는다.** nohup 리다이렉트
  상태에서 로그가 비어 있는 것은 정상이며, 진행 판정은 디스크 증가량으로 해야 한다
- **`setsid` 로 띄우면 셸이 즉시 `Done` 을 보고한다.** 작업이 끝난 것이 아니다

## 문제 & 해결

- **문제:** 마운트·파일 다 정상인데 임베딩 모델을 못 찾는다 (2026-08-26 부터 미해결)
- **원인:** 모델 파일이 `700` 으로 반입되어 비-root 앱 계정이 진입조차 못 했다.
  `models` 만 `:ro` 마운트라 엔트리포인트의 chown 자가치유 대상에서 빠져 있었고,
  `os.path.isfile()` 이 권한 부족을 `False` 로 뭉개 "없음" 과 같은 로그가 되었다
- **해결:** 컨테이너 경유 `chmod -R go+rX models` 후 `docker compose restart backend`
  → 이슈: [[embedding-model-not-found-despite-correct-mount]]

- **문제:** 로그인·DB·`isAdmin` 정상인데 관리자 버튼이 안 뜬다
- **원인:** `sidebar-user-menu.tsx:38` 이 `isOfficeAddin === false` 로 게이팅하는데,
  `use-office-addin.ts` 가 `load` 이벤트만 듣고 `error` 를 듣지 않아
  폐쇄망에서 외부 office.js 가 실패하면 상태가 `null` 로 남는다
- **해결:** 임시로 `/admin` 직접 접근 (`app/admin/layout.tsx` 는 `isAdmin` 만 본다).
  코드 수정은 미적용
  → 이슈: [[projects/dna-sql-agent-web/issues/admin-button-hidden-when-office-js-blocked|admin-button-hidden-when-office-js-blocked]]

- **문제:** `dnasql_agent` DB 가 없다며 backend 가 재시작 반복
- **원인:** postgres `initdb` 는 데이터 폴더가 빈 경우에만 `POSTGRES_DB` 를 만든다.
  이전 시도의 `data/postgres` 잔재가 있어 통째로 건너뛰어졌다
- **해결:** `docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE dnasql_agent;"`

## 다음 할 일

- [ ] `package.sh` 에 `chmod -R a+rX "$MODEL_STAGE"` 추가 (정본 수정)
- [ ] `init.sh` 에 `MODEL_DIR` 권한 보정 추가 (실패해도 진행, 경고만)
- [ ] `use-office-addin.ts` 에 `error` 리스너 + 타임아웃 폴백 추가
- [ ] `resolve_model_path()` 가 "없음" 과 "못 읽음" 을 구분해 로깅
- [ ] 폐쇄망 사이트 `.env` 에 `HF_HUB_OFFLINE=1` 배선
- [ ] 고객사 방화벽 30010/30011 개방 요청 (맥에서 접속 확인 필요)
- [ ] `fuse-overlayfs` 전환 검토 — 담당자가 "일단 유지" 결정. 다음 배포 전 재논의

## 효과적이었던 프롬프트

```
ps -fp <dockerd PID>
```

`dockerd` 가 root 가 아니라 사용자 소유로 떠 있다는 사실 하나로
vfs·UID 101004·sudo 불필요가 한 번에 설명됐다. 도커가 이상하게 동작하면
드라이버(`docker info --format '{{.Driver}}'`)와 데몬 실행 계정부터 봐야 한다.
