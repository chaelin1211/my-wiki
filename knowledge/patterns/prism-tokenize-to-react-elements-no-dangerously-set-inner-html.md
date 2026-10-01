---
type: pattern
tags: [react, prism, syntax-highlighting, dangerouslySetInnerHTML, useMemo, performance]
related-projects: [dna-sql-agent-web]
date: 2026-07-24
---

# Prism 문법 하이라이팅을 `dangerouslySetInnerHTML` 없이 React 엘리먼트로 렌더링하기

## 문제

Prism.js로 코드 하이라이팅을 할 때 흔한 패턴은 `Prism.highlight()`로 HTML 문자열을 만들고
`dangerouslySetInnerHTML`로 주입하는 것이다.

```tsx
// 흔한 패턴 — 문제 있음
const highlighted = Prism.highlight(code, Prism.languages.sql, 'sql')
return <code dangerouslySetInnerHTML={{ __html: highlighted }} />
```

이 방식은 두 가지 문제가 겹친다:
1. React의 가상 DOM diffing을 우회해 `innerHTML`을 통째로 재작성 — 브라우저가 서브트리를 파괴/재생성
2. (더 흔한 실전 문제) `useMemo` 없이 컴포넌트 함수 안에서 매번 `Prism.highlight()`를 호출하면,
   해당 코드 텍스트가 안 바뀌었는데도 부모가 리렌더될 때마다(스트리밍 UI 등에서 흔함) 재계산됨

## 패턴

`Prism.highlight()`(HTML 문자열 반환) 대신 `Prism.tokenize()`(토큰 배열 반환)를 쓰고,
토큰 트리를 재귀적으로 순회해 React 엘리먼트로 직접 변환한다. 포맷팅/토큰화 자체는 `useMemo`로 캐싱.

```tsx
import { useMemo } from 'react'
import Prism, { type Token } from 'prismjs'

function renderToken(token: string | Token, key: React.Key): React.ReactNode {
  if (typeof token === 'string') return token

  const classes = ['token', token.type]
  if (token.alias) {
    classes.push(...(Array.isArray(token.alias) ? token.alias : [token.alias]))
  }

  const content = Array.isArray(token.content)
    ? token.content.map((t, i) => renderToken(t, i))
    : renderToken(token.content, 0)

  return (
    <span key={key} className={classes.join(' ')}>
      {content}
    </span>
  )
}

function CodeBlock({ code }: { code: string }) {
  const tokens = useMemo(
    () => Prism.tokenize(code, Prism.languages.sql),
    [code]
  )
  return (
    <code className="language-sql">
      {tokens.map((token, i) => renderToken(token, i))}
    </code>
  )
}
```

CSS는 기존과 동일하게 `.token.keyword`, `.token.string` 등 클래스 셀렉터로 색을 입히면 된다
(Prism의 `Token.stringify`가 만드는 클래스명 규칙 — `token` + `type` + `alias`들 — 을
`renderToken`에서 그대로 재현했기 때문).

## 언제 쓰나

- 채팅/스트리밍 UI처럼 같은 코드 블록 컴포넌트가 부모 리렌더 때문에 자주 다시 그려지는 화면
- SQL/코드 미리보기 카드처럼 읽기 전용으로만 쓰이는 곳 (수정 가능한 편집기가 필요하면 CodeMirror/Monaco 같은 전용 에디터가 더 적합 — 이건 대체재가 아님)

## 효과 (실측)

Node.js + jsdom 환경, 34,079자 SQL / 30회 리렌더 시뮬레이션 기준 4729ms → 748ms (약 84% 감소).
단, 이득의 대부분은 `dangerouslySetInnerHTML` 제거 자체보다 **`useMemo` 캐싱 도입**에서 나왔다 —
즉 이 패턴을 쓸 때 `useMemo`를 빼먹으면 이득이 크게 줄어든다.

## 관련 페이지

- [[projects/dna-sql-agent-web/sessions/2026-07-24-sql-block-render-perf-and-conversation-loading]]
- [[projects/dna-sql-agent-web/decisions/016-sql-block-keep-dual-parse-prism-sql-formatter]]
