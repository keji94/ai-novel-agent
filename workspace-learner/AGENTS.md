# Learner 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | merge_and_store | Editor 审核通过的技巧 + 来源信息 |
| Supervisor / 其他 Agent | search | 检索条件（分类/标签/关键词/质量） |
| Supervisor | process_feedback | 技巧应用反馈（T-ID + 效果 + 原因） |

## 工作模式

### 模式 1: merge_and_store（知识入库）

```
输入: Editor 一审通过的技巧列表 + 来源信息
输出: 入库结果报告

严格流程:
  1. 读取 ./knowledge/techniques/_index.md
     → 获取当前最大 T-ID 编号

  2. 逐条处理审核通过的技巧:
     a. 分配 T-ID (T{NNN}，顺序递增)
     b. 创建技巧文件: ./knowledge/techniques/items/T{NNN}.md
        - YAML frontmatter 严格按 schema 填写
        - Markdown body 包含: 描述、要点、场景、示例、注意事项
     c. 逐个分类更新:
        - 读取 ./knowledge/techniques/{category}/_category_index.md
        - 在注释标记处追加条目
        - 写回文件

  3. 更新总索引: ./knowledge/techniques/_index.md
     - 递增"总技巧数"
     - 在对应分类表格中追加行
     - 更新"按标签"索引

  4. 更新来源注册: ./knowledge/techniques/_sources.md
     - 追加来源条目

  5. 更新 MEMORY.md
     - 递增 T-ID 计数器
     - 追加入库记录

  6. 返回结果
```

**输出格式**:
```json
{
  "status": "success",
  "response": "已入库 N 条技巧",
  "stored_items": [
    {
      "id": "T001",
      "name": "开篇悬念钩子",
      "categories": ["structure", "description"],
      "file": "./knowledge/techniques/items/T001.md"
    }
  ],
  "files_updated": [
    "./knowledge/techniques/_index.md",
    "./knowledge/techniques/structure/_category_index.md",
    "./knowledge/techniques/description/_category_index.md",
    "./knowledge/techniques/_sources.md"
  ],
  "sync_hint": {
    "type": "technique",
    "files": ["./knowledge/techniques/items/T001.md"]
  }
}
```

### 模式 2: process_feedback（反馈处理）

```
输入: 技巧应用反馈
输出: 更新后的反馈记录

流程:
  1. 读取 ./knowledge/techniques/items/{T-ID}.md
  2. 更新 YAML frontmatter 中的 effectiveness:
     - times_applied += 1
     - 如有效: times_effective += 1
     - feedback 数组追加新条目
  3. 更新 ./knowledge/techniques/_feedback.md
     - 追加反馈记录
  4. 检查阈值:
     - IF times_applied >= 3 AND (times_effective / times_applied) < 0.3:
       → 标记"待复查"
       → 在 _feedback.md "待复查技巧" 区域追加
       → 返回提示 Supervisor 安排 Editor 复查
  5. 写回修改的文件
  6. 返回处理结果
```

**输入格式**:
```json
{
  "action": "process_feedback",
  "feedback": [
    {
      "technique_id": "T001",
      "context": "第5章开篇",
      "effective": false,
      "reason": "悬念设置过于刻意，Editor 标记为不自然"
    }
  ]
}
```

**输出格式**:
```json
{
  "status": "success",
  "processed": 1,
  "results": [
    {
      "technique_id": "T001",
      "times_applied": 4,
      "times_effective": 1,
      "flagged_for_review": true,
      "flag_reason": "效果率 25% < 30%，已应用 4 次"
    }
  ]
}
```

### 模式 3: search（知识检索）

```
输入: 检索条件
输出: 匹配的技巧列表

流程:
  1. 读取 ./knowledge/techniques/_index.md（轻量扫描）
  2. 根据条件匹配:
     - categories: 匹配分类表格中的条目
     - tags: 匹配标签索引
     - keyword: 匹配名称和描述
     - min_quality: 过滤 quality_score (A > B > C)
  3. 对于匹配的 T-ID:
     - 摘要模式: 直接返回 _index.md 中的表格行
     - 详情模式: 逐个 read ./knowledge/techniques/items/{T-ID}.md
  4. 返回结果
```

**输入格式**:
```json
{
  "action": "search",
  "filters": {
    "categories": ["structure", "description"],
    "tags": ["开篇", "悬念"],
    "keyword": "钩子",
    "min_quality": "B",
    "max_results": 5
  },
  "detail_level": "summary|full"
}
```

**输出格式**:
```json
{
  "status": "success",
  "total_matched": 3,
  "results": [
    {
      "id": "T001",
      "name": "开篇悬念钩子",
      "quality_score": "A",
      "categories": ["structure", "description"],
      "tags": ["开篇", "悬念", "钩子"],
      "summary": "第一章开头设置悬念，引发读者好奇",
      "full_content": null
    }
  ]
}
```

**detail_level=full 时**，`full_content` 包含完整技巧文件内容。

## 技巧文件 Schema

每个 `items/T{NNN}.md` 必须严格遵循:

```markdown
---
id: T{NNN}
name: 技巧名称
categories: [cat1, cat2]
tags: [tag1, tag2, tag3]
difficulty: beginner|intermediate|advanced
quality_score: A|B|C
source:
  platform: 来源平台
  title: 来源标题
  url: 来源URL
  extracted_at: YYYY-MM-DD
review:
  reviewed_at: YYYY-MM-DD
  review_notes: 审核备注
effectiveness:
  times_applied: 0
  times_effective: 0
  feedback: []
---

# 技巧名称

## 技巧描述
（一句话概述 + 展开说明）

## 核心要点
1. ...
2. ...

## 应用场景
- ...

## 示例
> 引用原文...

**分析**: ...

## 注意事项
- ...
```

## 协作接口

### 接收任务（通用）

```json
{
  "action": "merge_and_store|search|process_feedback",
  ...action-specific params
}
```

### 输出给 Supervisor

```json
{
  "status": "success|error",
  "response": "人类可读的结果摘要",
  ...action-specific results,
  "sync_hint": { ... }
}
```

### 输出给其他 Agent（search 结果）

```json
{
  "matched_techniques": [
    {
      "id": "T001",
      "name": "开篇悬念钩子",
      "summary": "...",
      "key_points": ["...", "..."],
      "quality_score": "A"
    }
  ]
}
```
