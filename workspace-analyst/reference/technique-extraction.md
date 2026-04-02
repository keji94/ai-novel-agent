# 技巧提取标准

## 什么是可复用技巧

一条可复用技巧必须满足：
1. 有明确的操作方法（不是笼统的"写好文字"）
2. 有具体示例支撑（原文引用）
3. 有适用场景限定（知道何时用/何时不用）
4. 粒度适中（不是"写好开篇"那么大，也不是"在第3个字用逗号"那么小）

## 提取流程

1. 通读内容，标记所有"技巧点"
2. 对每个技巧点评估：
   - 可操作性：读者看完能立刻用吗？
   - 具体性：有明确的方法/步骤/标准吗？
   - 独特性：是常识还是独特洞察？
3. 按类别归类（structure/description/dialogue/character/climax）
4. 为每条技巧补充：
   - 核心要点（3-5 条）
   - 应用场景
   - 示例（原文引用）
   - 注意事项
5. 与已有知识库对比，标记重复/可合并项

## 质量分级

| 等级 | 标准 | 处理 |
|------|------|------|
| A | 有具体方法+示例+场景，可直接应用 | 直接入库 |
| B | 有方法但示例/场景不够完整 | 补充后入库 |
| C | 方向对但过于笼统 | Editor 决定是否保留 |

## 与下游对齐

提取的技巧需要匹配 Editor knowledge_review_1st_pass 的审核维度：

**输入字段**（Analyst 输出 → Editor 审核）:
```json
{
  "name": "技巧名称",
  "category": "structure|description|dialogue|character|climax",
  "content": {
    "description": "技巧描述",
    "core_points": ["要点1", "要点2"],
    "scenarios": ["适用场景"],
    "examples": ["原文引用"],
    "notes": ["注意事项"]
  },
  "source": {
    "platform": "来源平台",
    "title": "来源标题",
    "url": "来源链接",
    "extracted_at": "提取时间"
  }
}
```

**Editor 审核维度**（知己知彼）:
1. 质量评估：描述是否清晰可操作？示例是否具体？
2. 有害过滤：是否鼓励抄袭/误导/违规？
3. 价值评估：是真正技巧还是空话套话？是否有新知识？
4. 去重检测：与已有知识库是否重复？

**判定结果**:
- APPROVE: 分配 quality_score (A/B/C) + 建议分类
- REJECT: 附 rejection_reason
- MERGE: 指定 merge_target (已有 T-ID)

> 详细审核流程见 `workspace-editor/reference/knowledge-review-modes.md`
