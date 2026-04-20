---
type: dashboard
---

# my-wiki — Dashboard

## 활성 프로젝트

```dataview
TABLE status, stack, updated
FROM "projects"
WHERE type = "project-overview" AND status = "active"
SORT updated DESC
```

## 최근 세션 (10건)

```dataview
TABLE project, focus, outcome, duration
FROM "projects"
WHERE type = "session-log"
SORT date DESC
LIMIT 10
```

## 미해결 이슈

```dataview
TABLE project, root-cause
FROM "projects"
WHERE type = "troubleshooting" AND resolved = false
SORT date DESC
```

## 최근 의사결정

```dataview
TABLE project, status
FROM "projects"
WHERE type = "decision-record"
SORT date DESC
LIMIT 10
```

## Knowledge 최근 갱신

```dataview
TABLE type, updated
FROM "knowledge"
SORT updated DESC
LIMIT 15
```

## 태그별 도구

```dataview
LIST
FROM "knowledge/tools"
SORT file.name ASC
```
