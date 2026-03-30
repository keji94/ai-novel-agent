# 知识审核工具详解

> knowledge_review_1st_pass 和 knowledge_review_2nd_pass 的完整实现。

---

## knowledge_review_1st_pass - 知识一审

**用途**: 审核 Analyst 提取的技巧，逐条过滤后决定入库/拒绝/合并。

**前置条件**: 读取 `./knowledge/techniques/_index.md` 获取已有技巧列表。

**实现流程**:

```
1. read ./knowledge/techniques/_index.md
2. 遍历每条 extracted_tip:
   a. 质量评估: 描述是否清晰可操作？示例是否具体？
   b. 有害过滤: 是否鼓励抄袭/误导/违规？
   c. 价值评估: 是否为空话套话？是否提供了新知识？
   d. 去重检测: 对照 _index.md 现有条目，是否重复或子集？
3. 为每条给出判定:
   - APPROVE: 分配 quality_score (A=优秀/B=良好/C=一般)
     + 建议分类（可多个）: structure/description/dialogue/character/climax/platform/...
   - REJECT: 给出 rejection_reason
   - MERGE: 指定 merge_target (已有 T-ID)，说明合并方式
4. 返回 review_results 数组 + summary
```

**quality_score 标准**:
- A: 描述清晰、有具体示例、可直接操作、适用范围广
- B: 描述较清晰、示例一般、可操作但适用范围有限
- C: 描述笼统、缺少示例、需要自行补充才能使用

## knowledge_review_2nd_pass - 知识二审

**用途**: Learner 完成入库后，检查全系统一致性。

**前置条件**: Learner 已完成 merge_and_store，新 T-ID 文件已写入。

**实现流程**:

```
1. read ./knowledge/techniques/_index.md (获取完整索引)
2. 逐个 read 新增的 items/{T-ID}.md
3. 执行检查:
   a. 新条目互重: 两两比较新条目是否重复
   b. 分类归属: 验证 categories 字段与 _category_index.md 一致
   c. 质量一致性: 同级评分横向比较
   d. 引用完整性: 确认所有索引中引用的 T-ID 在 items/ 中存在
4. 如发现问题，直接修正（edit 相关文件）
5. 返回检查报告
```

**注意事项**:
- 二审可以自动修正小问题（如遗漏分类、索引不一致）
- 重大问题（如重复入库）需要记录并建议处理方案
