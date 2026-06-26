---
type: troubleshooting
project: dna-sql-agent-web
date: 2026-06-09
resolved: true
root-cause: "loadConversationMessages의 catch에서 404 외 에러도 대화를 목록에서 삭제하고 activeId를 초기화함"
related: []
tags: [conversation, error-handling, network]
---

# 대화 메시지 로드 실패 시 대화 목록에서 삭제되는 문제

## 증상

대화를 선택해 이전 메시지를 로드하는 중 네트워크 오류·서버 500 등 일시적 장애가 발생하면, 해당 대화가 사이드바 목록에서 사라지고 activeId가 초기화됨.

## 환경

- **런타임:** Next.js (React)
- **관련 파일:** `hooks/use-conversations.ts` - `loadConversationMessages`
- **재현 조건:** 대화 선택 후 백엔드가 일시적으로 응답 실패할 때

## 시도한 것들

1. ✅ `loadConversationMessages` catch 블록 확인 → 404와 그 외 에러를 동일하게 처리함을 발견

## 근본 원인

```ts
// 수정 전
} catch (err) {
    if (err instanceof Error) {
        if (err.message.includes('404')) {
            setConversations(prev => prev.filter(c => c.id !== convId))
            setActiveId(null)
        } else {
            console.error(...)
            setConversations(prev => prev.filter(c => c.id !== convId))  // ← 잘못됨
            setActiveId(null)
        }
    }
}
```

404가 아닌 에러(네트워크 타임아웃, 500 등)에서도 대화를 로컬에서 삭제함.

## 해결 방법

404일 때만 로컬에서 삭제. 나머지는 콘솔 에러만 출력.

```ts
} catch (err) {
    if (err instanceof SessionExpiredError) return
    if (err instanceof Error && err.message.includes('404')) {
        setConversations(prev => prev.filter(c => c.id !== convId))
        setActiveId(null)
    } else {
        console.error('Failed to load conversation messages:', err)
    }
}
```

## 예방책

- 404(리소스 없음)와 일시적 오류(500, 네트워크)의 처리를 명확히 분리할 것
- 일시적 오류에서 로컬 상태를 파괴적으로 변경하지 말 것
