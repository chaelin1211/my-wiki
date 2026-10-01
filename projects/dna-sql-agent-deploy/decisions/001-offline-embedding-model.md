---
type: decision-record
project: dna-sql-agent-deploy
date: 2026-08-18
status: accepted
superseded-by: ""
tags: [폐쇄망, 임베딩, 배포, docker]
---

# ADR-001: 폐쇄망에서 임베딩 모델 공급 방식

## 맥락

임베딩 모델(`upskyy/bge-m3-korean`, 약 2GB)을 기동 시 huggingface.co 에서 내려받고 있었다.
명시적인 다운로드 단계가 있는 것이 아니라, `SentenceTransformer("upskyy/bge-m3-korean")`
호출에서 huggingface_hub 가 자동으로 받는 구조다.

폐쇄망 고객은 이 다운로드가 불가능하다. 임베딩 서비스는 `agent_service` 모듈
로드 시점에 만들어지므로, 받지 못하면 재시도 끝에 앱이 종료되고 `restart: always`
때문에 재시작을 반복한다. 즉 **기동 자체가 되지 않는다.**

모델을 이미지에 굽는 방법도 있으나 이미지가 2GB 커지고, 버전을 올릴 때마다 같은
모델을 다시 담게 된다.

## 선택지

### 옵션 A: HF 캐시를 채워서 전달
- **장점:** 소스 수정이 전혀 필요 없다. 모델 이름을 그대로 두고 캐시만 채우면 된다
- **단점:** `hub/models--org--name/{blobs,snapshots,refs}` 는 huggingface_hub 의 **내부 캐시 구현**이지 배포 포맷이 아니다. 심링크·해시 파일명이 섞여 zip 에 넣으면 용량이 두 배가 되고, 라이브러리 버전이 바뀌면 레이아웃 보장이 없다
- **비용/노력:** 낮음

### 옵션 B: flat 로컬 디렉터리로 전달
- **장점:** `hf download --local-dir` 의 결과물 그대로. 평범한 파일이라 `ls` 로 확인되고, 심링크가 없어 zip 에 넣어도 부풀지 않으며, 읽기 전용 마운트가 가능하다. vLLM·TGI 등이 쓰는 표준 방식
- **단점:** 모델을 이름이 아니라 경로로 가리켜야 하므로 앱이 그 경로를 알아야 한다
- **비용/노력:** 중간 (소스 2곳 + 배포 설정)

## 결정

**옵션 B 를 선택한다.** 다만 설정(`config/embedding.json`)은 모델 **이름**을 그대로 두고,
앱이 로딩 직전에 한 번 해석한다.

```python
# dna/vectorization/embedder.py
MODEL_ROOT = os.environ.get("DNA_MODEL_ROOT") or "/data/apps/dna_sql_agent/models"

def resolve_model_path(model_name):
    # MODEL_ROOT 아래에 모델 폴더가 있으면 그 경로로, 없으면 이름 그대로
```

배포 쪽은 호스트의 `MODEL_DIR` 을 컨테이너의 `MODEL_ROOT` 로 읽기 전용 마운트한다.

## 근거

- **한 패키지로 두 환경을 덮는다.** 모델을 넣어 보내면 폐쇄망에서 그것을 쓰고, 안 넣으면
  기존처럼 내려받는다. 고객이 `.env` 나 `config` 를 고칠 일이 없다. 인증서 유무로
  `nginx.conf` / `nginx-http.conf` 를 정하는 기존 `init.sh` 방식과 같은 결이다.
- **설정에 경로가 노출되지 않는다.** 관리자 화면에 경로 대신 모델 이름이 그대로 보인다.
- **폴더 이름은 모델 이름을 통째로 따른다**(org 포함). org 를 떼면 `upskyy/bge-m3-korean` 과
  다른 곳의 같은 이름이 한 폴더로 뭉쳐, 차원이 같아 오류 없이 넘어가면서 이미 쌓아 둔
  벡터와 조용히 어긋날 수 있다.

## 결과

- `package.sh --with-models` 로 모델을 동봉한다. 붙이지 않으면 기존 동작 그대로다.
- 매번 2GB 를 다시 받지 않도록 `MODEL_CACHE_DIR`(기본 `~/.cache/dadap-models`)에 캐시한다.
  캐시를 쓸 수 없어도 중단하지 않고 스테이징에 바로 받는다.
- 모델을 내려받는 구성에서는 `hf_cache` 볼륨이 필요하다. 없으면 컨테이너를 다시 만들 때마다
  2GB 를 다시 받는다. 모델이 사는 곳이 둘이 되는 게 마음에 걸리지만, 재다운로드 비용이 더 크다.
- 기존 `README.txt` 가 안내하던 `/data/apps/dna_sql_agent/.cache` 는 실제 위치
  (`HF_HOME=.../hf_cache`)와 달라 따라 해도 동작하지 않았다. 함께 정정했다.
- **검증** — 실제 모델로 4가지 경우(모델 있음/없음/빈 폴더/경로 직접 지정)와
  `HF_HUB_OFFLINE=1` 오프라인 로딩까지 확인. 컨테이너에서 huggingface 접속 시도가
  사라진 것도 로그로 확인했다.

## 참고 자료

- `dna-sql-agent`: `src/dna/vectorization/embedder.py`, `src/dna/enhancers/retriever.py`
- `dna-sql-agent-deploy`: `package.sh`, `common/docker-compose.yml`, `common/.env.template`
- 관련: [[projects/dna-sql-agent-deploy/overview|dna-sql-agent-deploy]]
