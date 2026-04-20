# 위키 규약 (Conventions)

## 태그 체계

태그는 계층적으로 사용한다:

- `#lang/typescript`, `#lang/python`, `#lang/rust`
- `#framework/nextjs`, `#framework/fastapi`
- `#infra/docker`, `#infra/vercel`, `#infra/aws`
- `#pattern/auth`, `#pattern/caching`, `#pattern/error-handling`
- `#status/active`, `#status/resolved`, `#status/deprecated`

## 콜아웃 사용법

| 콜아웃 | 용도 |
|--------|------|
| `> [!tip]` | 실용적 팁, 숏컷 |
| `> [!warning] 충돌` | 소스 간 모순 |
| `> [!note] 해석` | LLM의 추론·해석 (소스 원문 아님) |
| `> [!bug]` | 알려진 버그·주의사항 |
| `> [!success]` | 검증된 해결법 |
| `> [!question]` | 추가 조사 필요 |

## 링크 표기

- 내부 링크: `[[projects/my-app/overview|My App]]`
- 외부 링크: `[제목](URL)`
- 소스 참조: `[[raw/articles/파일명|원문]]`

## 커밋 메시지 규약 (Git 사용 시)

```
ingest: {소스 제목} - {영향받은 페이지 수}개 페이지 갱신
session: {프로젝트} - {주제}
lint: 주간 점검 - {발견 사항 요약}
decision: {프로젝트} - ADR-{번호} {제목}
```
