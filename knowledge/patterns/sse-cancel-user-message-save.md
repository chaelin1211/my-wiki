---
type: pattern
tags: [sse, fastapi, asyncio, cancel, streaming]
created: 2026-06-09
---

# SSE 스트리밍 중단 시 사용자 메시지 저장 패턴

## 문제

FastAPI SSE 엔드포인트에서 클라이언트가 연결을 끊으면(취소 버튼, 탭 닫기 등) 진행 중인 스트리밍이 중단된다. 이 시점에 이미 전송된 사용자 메시지가 DB에 저장되지 않아 유실된다.

## 패턴

```python
async def generate() -> AsyncGenerator[str, None]:
    stream_completed = False
    try:
        async for chunk in handler.handle_stream(request):
            yield f"data: {chunk.model_dump_json()}\n\n"
        yield "data: [DONE]\n\n"
        stream_completed = True
    except PermissionError:
        # ... 403 응답 ...
        stream_completed = True
    except Exception as e:
        # ... 500 응답 ...
        # stream_completed는 False 유지
    finally:
        if not stream_completed and request.conversation_id:
            asyncio.create_task(save_user_message(...))
```

## 핵심 원리

- 클라이언트 disconnect → Python이 async generator에 `GeneratorExit` throw → `finally` 블록 실행
- `stream_completed` 플래그로 정상 완료 경로(after_message가 처리)와 중단 경로를 구분
- `finally` 안에서는 `await` 불가 (`GeneratorExit` 후 이벤트 루프 상태 불안정) → `asyncio.create_task()`로 fire-and-forget

## 주의사항

- 정상 완료 경로에서 별도 `after_message` 훅이 이미 사용자 메시지를 저장하는 구조라면 `stream_completed = True`로 설정해 finally 저장을 건너뜀 → 중복 저장 방지
- `save_user_message`는 conversation 존재 여부를 먼저 확인 후 INSERT (신규 대화 생성 전 연결 끊긴 경우 대비)

## 적용 사례

- `dna-sql-agent`: `src/vanna/servers/fastapi/routes.py` `generate()` 함수
