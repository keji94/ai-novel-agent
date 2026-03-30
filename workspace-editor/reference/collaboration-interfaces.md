# 协作接口 JSON 格式

> 从 AGENTS.md 拆分出的接口定义。

---

## 接收任务

```json
{
  "task": "审核章节",
  "project": "项目名",
  "chapter": {
    "number": 1,
    "content": "章节内容",
    "outline": "章节大纲",
    "notes": "写作说明"
  },
  "settings": {
    "world": "世界观",
    "characters": "角色设定"
  },
  "mode": "quick|standard|full|ai_trace|fanfic",
  "genre": "仙侠|玄幻|都市"
}
```

## 输出结果

```json
{
  "status": "pass|revisions_needed|fail",
  "grade": "A|B|C|D",
  "audit_dimensions_used": 22,
  "passed_dimensions": 20,
  "report": {
    "critical_issues": [],
    "warning_issues": [],
    "highlights": []
  },
  "revised_content": "润色后内容（可选）",
  "revision_suggestion": {
    "mode": "spot-fix",
    "reason": "3 个 critical 问题需要定点修复",
    "priority_dimensions": [1, 9, 13]
  },
  "metrics": {
    "word_count": 2856,
    "readability_score": 85,
    "engagement_score": 78
  }
}
```

## 输出给其他 Agent

### 给 Supervisor

```json
{
  "status": "pass|revisions_needed|fail",
  "grade": "B",
  "summary": "22 维度审计通过 20，2 个 critical，3 个 warning",
  "revision_needed": true,
  "suggested_mode": "spot-fix"
}
```

### 给 Reviser（触发修订）

```json
{
  "task": "根据审计报告修订",
  "chapter_number": 1,
  "mode": "spot-fix",
  "audit_result": {
    "critical": [...],
    "warning": [...]
  },
  "focus_dimensions": [1, 9, 13]
}
```

### 给 Planner（设定问题反馈）

当发现设定问题时：

```json
{
  "task": "修正设定",
  "issue": "描述问题",
  "suggestion": "建议方案",
  "dimension": 3
}
```
