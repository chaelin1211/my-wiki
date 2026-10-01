---
type: pattern
tags: [huggingface, 폐쇄망, 배포, docker, 임베딩]
created: 2026-08-18
---

# 폐쇄망에 모델을 넣을 때는 HF 캐시가 아니라 flat 디렉터리로

## 문제

`SentenceTransformer("org/model")` 처럼 **이름**으로 모델을 부르면 huggingface_hub 이
런타임에 알아서 내려받는다. 명시적인 다운로드 단계가 없어서, 폐쇄망에서는 기동은 되고
검색만 조용히 죽는다.

미리 넣어 보내야 하는데, 받는 방법이 두 가지고 결과물이 전혀 다르다.

## 두 방식

**캐시에 받기** — `HF_HOME` 을 지정하고 `hf download <repo>`

```
<HF_HOME>/hub/models--org--model/
    blobs/       실체 파일 (이름이 전부 sha256 해시)
    snapshots/<commit>/
        config.json -> ../../blobs/72b987fd...   전부 심링크
    refs/main -> <commit>                        커밋 해시 간접 참조
```

**flat 디렉터리** — `hf download <repo> --local-dir <경로>`

```
<경로>/
    config.json          612        전부 실제 파일
    model.safetensors    2.2G
    modules.json  tokenizer.json  1_Pooling/  ...
```

## 결론

**전달물은 flat 디렉터리로 만든다.**

`hub/models--org--model/{blobs,snapshots,refs}` 는 huggingface_hub 의 **내부 캐시 구현**이지
문서화된 배포 포맷이 아니다. 라이브러리 버전이 바뀌면 레이아웃 보장이 없고, 심링크가 섞여
있어 zip 에 넣으면 (`zip` 이 링크를 따라가) 용량이 두 배가 된다. `ls` 로 내용을 확인할 수도 없다.

flat 디렉터리는 평범한 파일이라 읽기 전용 마운트가 되고, 심링크가 없어 압축해도 부풀지 않는다.
vLLM·TGI 등이 쓰는 방식이기도 하다.

## 주의

- **폴더 이름은 repo id 를 통째로 쓴다**(org 포함). org 를 떼면 `upskyy/bge-m3-korean` 과
  다른 곳의 같은 이름이 한 폴더로 뭉친다. 차원이 같으면 오류 없이 로드되면서 이미 쌓아 둔
  벡터와 조용히 어긋난다.
- **`huggingface_hub < 0.23`** 에서는 `--local-dir` 이 5MB 넘는 파일을 캐시로 심링크한다.
  `--local-dir-use-symlinks False` 를 붙이거나 최신 버전으로 받는다.
- **비어 있는 폴더를 걸러낸다.** 마운트만 되고 모델을 안 넣은 상태를 잡으려면 `config.json`
  존재 여부를 본다. 어느 모델에나 있는 파일이다.
- 이름으로 내려받는 구성도 지원한다면 `HF_HOME` 캐시 볼륨은 여전히 필요하다.
  없으면 컨테이너를 다시 만들 때마다 다시 받는다.

## 확인 방법

`HF_HUB_OFFLINE=1` 로 네트워크를 막고 로드해 본다. 캐시가 없으면 즉시 `OSError` 로 떨어지고,
준비돼 있으면 정상 로드된다. 컨테이너 단위로 확인할 때는 `docker run --network none`.

## 사례

- [[projects/dna-sql-agent-deploy/decisions/001-offline-embedding-model|dna-sql-agent-deploy ADR-001]]
