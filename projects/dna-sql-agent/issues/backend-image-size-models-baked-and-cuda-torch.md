---
type: troubleshooting
project: dna-sql-agent
date: 2026-08-25
resolved: false
root-cause: "models/ 가 .dockerignore 에 없어 임베딩 모델 2.2GB 가 이미지에 구워지고, torch 가 CUDA 빌드로 깔려 nvidia/ 2.8GB 가 실림"
tags: [docker, image-size, dockerignore, torch, cuda]
---

# 백엔드 이미지가 10GB 대로 커짐

## 증상

로컬에서 만든 `dna-sql-agent` 이미지가 10.4GB. 2주 전 `latest` 는 4.76GB 였다.

## 환경

- `Dockerfile` 최종 스테이지의 `COPY . $HOME/`
- 폐쇄망 테스트를 위해 저장소 루트 `models/` 에 임베딩 모델을 내려받은 뒤부터

## 근본 원인

컨테이너 안에서 실측한 내역이다.

| 항목 | 크기 | 성격 |
|---|---|---|
| `nvidia/` (CUDA 런타임) | 2.8GB | torch 가 딸고 들어옴. CPU 로만 쓰는데 실림 |
| `torch/` | 1.5GB | 필요 |
| `models/` | 2.2GB | **이미지에 있으면 안 되는 것** |

**`models/` 가 `.dockerignore` 에 없다.** `hf_cache/` 는 들어 있는데 `models/` 만 빠져서 `COPY . $HOME/` 이 통째로 담아간다. 그런데 compose 는 어차피 호스트에서 마운트한다.

```yaml
- ${MODEL_DIR:-./models}:/data/apps/dna_sql_agent/models:ro
```

즉 이미지 안의 2.2GB 는 기동하는 순간 마운트에 덮여 한 번도 쓰이지 않는다.

CI 러너에는 `models/` 가 없으므로 서버 빌드는 영향이 없다. 로컬에 모델을 내려받은 사람만 겪는다.

`nvidia/` 는 별개다. `requirements.txt:1` 이 `--find-links https://download.pytorch.org/whl/cu118` 를 쓰는데, `--find-links` 는 PyPI 폴백을 막지 못해 결국 PyPI 의 CUDA 빌드 torch 가 깔린다.

## 해결 방법

미적용. 두 갈래다.

1. `.dockerignore` 에 `models/` 추가 — 2.2GB 감소. compose 가 마운트하므로 위험 없음
2. torch 를 CPU 휠로 전환 — 추가 2.8GB 감소. `--index-url https://download.pytorch.org/whl/cpu` 로 바꾸는 것이며, GPU 를 쓰는 배포처가 있는지 확인이 선행돼야 한다
