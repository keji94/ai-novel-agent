# 知识检索工具

## query_techniques - 查询写作技巧

**用途**: 写作前从知识库检索相关技巧，纳入写作上下文。

**使用时机**:
- 开始新章节前（根据章节类型加载相关技巧）
- 大纲指定特殊场景（打斗、恋爱、开篇等）
- 遇到写作瓶颈时主动查询

**实现步骤**:

```
Step 1: 确定检索条件
  根据章节大纲和场景类型，确定:
  - categories: 结构→structure, 描写→description, 对话→dialogue, 人物→character, 爽点→climax
  - tags: 从大纲关键词提取（开篇、打斗、悬念、升级...）
  - min_quality: B（只用质量过关的技巧）

Step 2: 轻量扫描
  read ./knowledge/techniques/_index.md
  → 按条件匹配技巧条目

Step 3: 按需加载
  FOR EACH matched T-ID WHERE quality_score >= "B":
    read ./knowledge/techniques/items/{T-ID}.md
    → 提取核心要点、示例

Step 4: 纳入写作上下文
  将匹配的技巧摘要写入 Phase 1 的创作指导中:
  "参考技巧: T001-开篇悬念钩子: 1.制造信息差 2.设置反常 3.埋设钩子"
```

**检索场景映射**:

| 章节类型 | 推荐检索条件 |
|----------|-------------|
| 开篇/首章 | categories: structure, tags: 开篇 |
| 打斗场景 | categories: [description, climax], tags: 打斗 |
| 对话密集 | categories: dialogue |
| 高潮/爽点 | categories: climax, min_quality: A |
| 感情戏 | categories: [character, dialogue], tags: 感情 |
| 过渡/铺垫 | categories: structure, tags: 伏笔 |

## report_technique_feedback - 技巧效果反馈

**用途**: 写作完成后，向 Supervisor 报告技巧应用效果，触发反馈闭环。

**使用时机**:
- Editor 审核章节后发现技巧相关问题
- Writer 写作时发现技巧不适合当前场景

**反馈格式**（返回给 Supervisor）:

```json
{
  "action": "report_technique_feedback",
  "feedback": [
    {
      "technique_id": "T001",
      "context": "第5章开篇",
      "effective": false,
      "reason": "悬念设置过于刻意，与角色当前处境不匹配"
    }
  ]
}
```

**说明**: Writer 不直接修改知识库，而是通过 Supervisor 路由到 Learner 的 `process_feedback` 模式。
