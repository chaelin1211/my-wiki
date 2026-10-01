---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-05
resolved: true
root-cause: "init.sh 가 태그 존재 여부만 보고 docker load 를 건너뜀 — 태그가 이미지 내용을 식별하지 못함"
related: [deploy, docker, upgrade]
tags: [deployment, docker, packaging]
---

# 새 패키지를 설치했는데 옛 이미지가 계속 도는 문제

## 증상

새 코드로 이미지를 빌드해 패키지를 다시 말았는데, 설치 후에도 고친 내용이
반영되지 않는다. 폐기했어야 할 설정 파일이 계속 다시 생겼다.

```
$ ls config/
database.json  qdrant.json  llm.json    ← 새 코드는 이 파일들을 만들지 않는다
```

`init.sh` 는 아무 문제 없이 지나간다.

```
[3/6] 이미지 불러오기
  이미 불러온 상태입니다 (건너뜀)
```

## 환경

- **OS:** macOS (로컬 리허설), Linux (빌드 서버)
- **런타임:** Docker
- **관련 패키지:** `dna-sql-agent-deploy` 의 `init.sh`, `package.sh`
- **재현 조건:** 같은 `IMAGE_TAG` 로 만든 패키지를 이미 그 태그의 이미지가 있는
  장비에 설치할 때

## 시도한 것들

1. ❌ `config/` 의 파일을 지우고 재기동 — 다시 생김 (옛 코드가 만들고 있었음)
2. ❌ `.env` 확인 — 값은 정상이었음
3. ✅ 이미지 생성 시각 확인 — 8/3자였다. 패키지 tar 는 8/5자
4. ✅ 이미지 안의 `defaults/` 확인 — 폐기한 `database.json`·`qdrant.json`·`llm.json`
   이 그대로 있었음. 신규 모듈 `env_config` 는 없었음

```bash
docker images dna-sql-agent --format "{{.Tag}}  {{.CreatedAt}}"
#  1.0  2026-08-03 15:04:37     ← tar 는 8/5 15:09 생성

docker run --rm --entrypoint sh dna-sql-agent:1.0 -c \
  'ls /data/apps/dna_sql_agent/src/dna/settings/defaults/'
```

## 근본 원인

`init.sh` 가 **태그 존재 여부만으로** 로드 필요를 판단한다.

```bash
need_load=0
for img in "dna-sql-agent:${IMAGE_TAG}" "dna-sql-agent-web:${IMAGE_TAG}"; do
  docker image inspect "$img" >/dev/null 2>&1 || need_load=1
done
if [[ $need_load -eq 0 ]]; then
  echo "  이미 불러온 상태입니다 (건너뜀)"
```

`IMAGE_TAG` 는 `package.sh` 에서 **버전과 같게** 정해진다(`IMAGE_TAG=$VERSION`).
개발 중에는 같은 `1.0` 을 몇 번이고 다시 마는데, 태그가 같으므로 스크립트는
"이미 있다"고 판단하고 새 tar 를 무시한다.

**태그가 이미지 내용을 식별하지 못하는 것**이 본질이다.

## 해결 방법

건너뛸 때 조용히 넘어가지 않고 교체 절차를 안내하도록 했다. 원인 파악에 오래
걸린 이유가 *아무 말 없이* 넘어간 것이었기 때문이다.

```
[3/6] 이미지 불러오기
  같은 태그(1.0)의 이미지가 이미 있어 건너뜁니다.
    이 패키지의 이미지로 바꾸시려면 아래를 실행한 뒤 다시 시도하십시오.
      docker compose down
      docker rmi dna-sql-agent:1.0 dna-sql-agent-web:1.0
      ./init.sh
```

즉시 조치:

```bash
docker compose down
docker rmi dna-sql-agent:1.0 dna-sql-agent-web:1.0
rm -f config/database.json config/qdrant.json config/llm.json
./init.sh && ./start.sh
```

## 예방책

근본 수정은 하지 않았다. 고객사 **최초 설치에서는 이 버그가 나지 않는다**
(그 서버에 이미지가 없으므로 항상 로드된다). 터지는 것은 같은 버전으로 다시
전달할 때, 즉 업그레이드 시나리오이고 `upgrade.sh` 는 아직 만들지 않았다.

업그레이드 작업 때 함께 처리할 방향:

- `package.sh` 가 `docker image inspect --format '{{.Id}}'` 값을 패키지에 기록
- `init.sh` 가 로컬 이미지 ID 와 비교해 다르면 로드

이미지 ID 는 config 다이제스트라 `save`/`load` 를 거쳐도 보존된다. 비교 비용이
사실상 0 이라 "무조건 `docker load`" (4GB 를 매번 gunzip) 보다 낫다.

## 관련 페이지

- 세션: [[projects/dna-sql-agent/sessions/2026-08-05-config-source-unification-and-package-workflow]]
- [[projects/dna-sql-agent/decisions/030-deploy-package-separate-repo]]
