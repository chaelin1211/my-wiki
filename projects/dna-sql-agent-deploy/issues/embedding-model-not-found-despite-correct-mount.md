---
type: troubleshooting
project: dna-sql-agent-deploy
date: 2026-08-26
resolved: true
root-cause: "모델 파일이 700 으로 반입되어 비-root 앱 계정이 진입 불가. models 는 :ro 마운트라 엔트리포인트 chown 자가치유에서 빠져 있다"
updated: 2026-08-28
related: [embedding, offline, permissions, docker]
tags: [docker, permissions, embedding, offline, deployment]
---

# 마운트·파일 다 정상인데 임베딩 모델을 못 찾는다

## 증상

폐쇄망 고객사에서만 발생. 같은 패키지가 개발 서버에서는 정상 기동한다.

```
[EMBEDDING] /data/apps/dna_sql_agent/models/upskyy/bge-m3-korean 에 모델이 없어
            huggingface.co 에서 내려받습니다.
HTTPSConnection(host='huggingface.co', port=443) Failed to resolve 'huggingface.co' [Errno -3]
urllib3 NameResolutionError
```

이후 기동 실패 → `restart: always` 로 재시작 반복.

`Errno -3`·`NameResolutionError` 는 폐쇄망이라 나오는 **후속 증상**이다.
원인은 그 앞줄, 로컬 탐색이 실패했다는 사실에 있다.

## 환경

- **OS:** 고객사 리눅스 (폐쇄망) / 개발 서버 리눅스 / 로컬 맥 + colima
- **런타임:** docker compose, 백엔드 컨테이너는 `setpriv` 로 UID 1005 실행
- **관련 패키지:** sentence-transformers, huggingface_hub
- **재현 조건:** 미확보 — 개발 서버·맥에서는 재현되지 않음

## 판정 로직

`src/dna/vectorization/embedder.py` `resolve_model_path()` 의 판정은 이것 하나다.

```python
MODEL_ROOT = os.environ.get("DNA_MODEL_ROOT") or "/data/apps/dna_sql_agent/models"

def _has_model(directory):
    return os.path.isfile(os.path.join(directory, "config.json"))

local = os.path.join(MODEL_ROOT, model_name)   # model_name 은 config/embedding.json 의 model
if _has_model(local):
    return local                                # 로컬 사용
return model_name                               # 이름 그대로 → 다운로드 시도
```

**`os.path.isfile()` 은 권한 부족을 예외로 올리지 않고 `False` 를 돌려준다.**
그래서 "파일이 없음" 과 "읽을 수 없음" 이 완전히 같은 로그로 뭉개진다.

## 시도한 것들

1. ❌ **`HF_HUB_OFFLINE` 미설정 의심** — 무관. 로컬 판정은 허깅페이스 호출 이전에
   파일시스템 검사로 끝난다. 켜도 같은 로그가 찍히고 다운로드가 오프라인 오류로 바뀔 뿐
2. ❌ **패키지 zip 손상 의심** — `zipinfo` 로 확인. 구조·이름·크기·권한 정상,
   심링크 0개, `model.safetensors` 2,271,064,456 바이트
3. ❌ **HF 캐시 심링크 구조로 반입됐을 가능성** — `package.sh` 는
   `hf download --local-dir` (구버전 CLI 는 `--local-dir-use-symlinks False`) 로
   standalone 반입. `zip` 도 `-y` 없이는 심링크를 따라간다
4. ❌ **마운트 오지정** — `docker inspect` Source/Destination 정상
5. ❌ **umask 로 인한 권한 부족 (1차 가설)** — 같은 조건의 `license_files` 는
   읽혔으므로 서버 전역 umask 문제는 아니다
6. ❌ **개발 서버에서 `chmod o-rx` 재현 시험** — 무효였다. `stat` 이 `1005 1005 775`,
   즉 파일 소유자가 앱 UID 와 같아 owner 비트로 읽힌다. other 비트를 꺼도 영향 없음
7. ✅ **고객사에서 앱 시점 확인 (2026-08-28)** — 확정.
   `docker exec ... ls -ln` 결과 모델 폴더가 `drwx------`(700), 파일이 `-rwx------`(700).
   소유자만 접근 가능하고 앱 계정은 진입조차 못 하는 상태였다

## 근본 원인

**확정 (2026-08-28) — 1번이었다.** 모델 파일이 `700` 권한으로 반입되어
비-root 로 실행되는 앱 계정이 폴더에 진입조차 못 했고, `os.path.isfile()` 이
이를 `False` 로 돌려주어 "모델 없음" 과 구분되지 않았다.

`700` 이 된 경위는 **패키지를 만드는 쪽의 umask** 다. `package.sh` 의
`hf download` 가 만드는 쪽 umask 를 그대로 따르고, 그 권한이
`cp -R` → `zip`(유닉스 퍼미션 저장) → 고객사 압축 해제까지 그대로 살아남는다.

아래는 당시 좁혀둔 후보이며, 1번이 사실로 확인됐다.

1. **앱 UID(1005)가 모델 경로를 읽거나 통과하지 못함** ← **확정**.
   `docker-entrypoint.sh` 의 chown 목록은 `config`·`log`·`hf_cache`·`query-results`
   넷뿐이고 **`models` 는 없다.** `:ro` 마운트라 넣어도 chown 이 안 된다.
   즉 다른 마운트는 전부 기동 시 자가치유되는데 **모델만 호스트 권한에 그대로 노출**된다.
   README 가 폐쇄망 고객에게 모델을 **별도 반입**하도록 안내하므로,
   그 폴더만 소유자·권한이 다를 개연성이 높다
2. `config/embedding.json` 의 `model` 값이 폴더 이름과 다름.
   관리자 화면에서 변경 가능하고 `config/` 는 바인드 마운트라 고객사 파일이 살아남는다
3. 압축이 덜 풀렸거나 `--with-models` 없이 만든 패키지

## 해결 방법

**즉시 조치** — 권한만 열면 되고, 바인드 마운트라 재생성 없이 `restart` 로 충분하다.

```bash
chmod -R a+rX models && docker compose restart backend
```

소유자가 아니라 `chmod` 가 거부되면(고객사에서 실제로 이랬다) 컨테이너를 경유한다.
rootless Docker 라면 컨테이너 UID 0 이 호스트 사용자에 대응하므로 sudo 없이 된다.

```bash
docker run --rm -u 0:0 --entrypoint chmod \
  -v "$PWD/models":/mnt <아무_이미지> -R go+rX /mnt
docker compose restart backend
```

`a+rX` 의 대문자 `X` 는 디렉터리에만 실행권한을 준다. 특정 UID 를 겨냥하지 않아
rootless 든 아니든 통한다.

### 확정용 진단 (앱과 같은 계정으로 봐야 한다)

```bash
docker compose exec -u 1005 backend sh -lc \
  'cat config/embedding.json; echo ---; ls -ld models models/* models/*/*; echo ---; ls -l models/*/*/config.json'
docker compose logs backend | grep EMBEDDING
docker compose exec backend ps -o uid,cmd | head    # 실제 실행 UID
docker info | grep -iE "rootless|userns"            # UID 매핑 예외 확인
```

`-u 1005` 는 실패하고 `-u 0` 은 성공하면 권한 확정. 조치는 root 없이도 된다
(소유자 본인이면 `chmod` 가능):

```bash
chmod -R a+rX models && docker compose restart backend
```

`a+rX` 의 대문자 `X` 는 디렉터리에만 실행권한을 준다. 특정 UID 를 겨냥하지 않아
rootless 든 아니든 통한다. 권한만 바꾸는 것이므로 `restart` 로 충분하다
(`MODEL_DIR` 자체를 바꾼 경우에만 `up -d --force-recreate` 가 필요).

## 예방책

- **정본은 `package.sh` 다 (미구현).** 런타임 조치는 고객사 계정이 `chmod` 를
  못 하는 환경에서 무너진다. 만드는 쪽에서 열어 보내면 조치 자체가 불필요해진다.
  `package.sh` 의 `rm -rf "$MODEL_STAGE/.cache"` 다음에 한 줄:

  ```bash
  chmod -R a+rX "$MODEL_STAGE"
  ```

- `init.sh` 가 `MODEL_DIR` 에 `chmod -R a+rX` 를 걸고, 모델 확인을 **설치 계정이 아니라
  UID 1005 기준**으로 검사한다. 현재 `init.sh` 의 `compgen -G "$MODEL_DIR/*/*/config.json"`
  검사는 설치 계정 기준이라 이 상황을 그대로 통과시킨다
- `resolve_model_path()` 가 폴더는 있는데 `config.json` 이 안 보이면 권한을 의심하는
  로그를 남긴다. 지금은 "없음" 과 "못 읽음" 이 구분되지 않는다
- 폐쇄망 사이트 `.env` 에 `HF_HUB_OFFLINE=1` 을 넣는다. 원인은 아니지만
  DNS 타임아웃 후 무한 재시작 대신 즉시 명확한 오류가 난다
- **검증은 리눅스에서 한다.** 맥(colima)은 바인드 마운트 권한을 강제하지 않아
  이 부류의 버그가 구조적으로 안 보인다

## 관련 페이지

- [[knowledge/troubleshooting/rootless-docker-uid-mapping-inverted]]
- [[knowledge/troubleshooting/docker-bind-mount-uid-mismatch]]
- [[knowledge/troubleshooting/exists-check-masks-permission-denied]]
- [[knowledge/tools/colima]]
- [[001-offline-embedding-model]]
- [[../sessions/2026-08-26-embedding-model-not-found-diagnosis]]
- [[../sessions/2026-08-28-rootless-docker-vfs-closed-network-deploy]]
