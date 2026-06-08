---
type: issue
project: dna-sql-agent-web
date: 2026-05-21
status: resolved
tags: [bookmark, api, data-mapping]
---

# bookmark-component-data-mapping

## 문제

`BookmarkView`의 `BookmarkPreview`에서 표와 차트가 렌더되지 않음.

## 원인

백엔드 북마크 API의 `component_data` 구조가 예상과 달리 중첩됨.

**실제 구조:**
```json
{
  "component_data": {
    "id": "...",
    "type": "dataframe",
    "data": {
      "data": [ ...실제 rows... ],
      "title": "Query Results",
      "columns": [...]
    },
    "visible": true
  }
}
```

**코드가 기대했던 구조:**
```ts
// 잘못된 접근
const rows = (data as any)?.rows ?? (Array.isArray(data) ? data : [])
```

payload가 `componentData` 자체가 아니라 `componentData.data` 안에 있고,
rows는 `componentData.data.data`.

## 해결

`BookmarkPreview`에서 payload 추출 경로 수정:

```ts
// component_data structure: { id, type, data: <actual payload>, ... }
const payload = (bookmark.componentData as any)?.data

// dataframe: payload.data = rows 배열
const rows = payload?.data ?? []

// chart: payload 자체가 chart config (dataSource 또는 data 배열)
```

## 재현 조건

북마크 API에서 `component_data`가 반환될 때마다 해당 구조 가정.
