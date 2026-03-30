# 知识审核模式详解（模式 5 & 模式 6）

> 从 AGENTS.md 拆分出的详细审核维度、判定标准和输出格式。

---

## 模式 5: 知识一审（逐条过滤）

```
适用: Analyst 提取的技巧入库前审核
输入: extracted_tips 数组 + ./knowledge/techniques/_index.md
输出: APPROVE / REJECT / MERGE 判定列表

审核维度:
  1. 质量评估
     - 描述是否清晰、可操作？
     - 示例是否具体、有说服力？
     - 技巧是否可直接用于网文创作？

  2. 有害过滤
     - 是否鼓励抄袭或照搬？
     - 是否包含误导性写作建议？
     - 是否与平台内容规范冲突？

  3. 价值评估
     - 是真正可操作的技巧，还是空话套话？
     - 是否提供了新知识，还是已有常识？
     - 能否独立应用，还是过于依赖特定上下文？

  4. 去重检测（对照 _index.md）
     - 是否与已有技巧完全重复？
     - 是否为已有技巧的子集，应合并而非新建？

判定结果:
  - APPROVE: 有效技巧，分配 quality_score (A/B/C)，建议分类
  - REJECT: 质量不足/有害/过于笼统，附 rejection_reason
  - MERGE: 与已有 T-ID 重复，指定 merge_target 和合并说明
```

### 输出格式

```json
{
  "mode": "knowledge_review_1st_pass",
  "review_results": [
    {
      "index": 0,
      "name": "开篇悬念钩子",
      "decision": "APPROVE",
      "quality_score": "A",
      "suggested_categories": ["structure", "description"],
      "review_notes": "清晰可操作，示例具体，适合开篇场景"
    },
    {
      "index": 1,
      "name": "写好文字",
      "decision": "REJECT",
      "rejection_reason": "过于笼统，不可操作，缺少具体方法"
    },
    {
      "index": 2,
      "name": "悬念设计技巧",
      "decision": "MERGE",
      "merge_target": "T001",
      "merge_reason": "与已有 T001「开篇悬念钩子」高度重叠，可作为补充示例合并"
    }
  ],
  "summary": {
    "total": 5,
    "approved": 3,
    "rejected": 1,
    "merged": 1
  }
}
```

---

## 模式 6: 知识二审（系统一致性）

```
适用: Learner 入库后的全系统一致性检查
输入: 新入库 T-ID 列表 + ./knowledge/techniques/_index.md
输出: 一致性检查报告

检查项:
  1. 新条目间互重
     - 新入库的条目之间是否存在重复？
     - 是否有应合并但未合并的条目？

  2. 分类归属
     - 分类选择是否合理？
     - 是否遗漏了应归属的分类？
     - 是否有不恰当的分类？

  3. 质量评分一致性
     - 同级评分的条目质量是否相当？
     - A 级条目是否真正优秀？

  4. 引用完整性
     - _index.md 中的 T-ID 是否都有对应 items/ 文件？
     - _category_index.md 中引用的 T-ID 是否存在？
```

### 输出格式

```json
{
  "mode": "knowledge_review_2nd_pass",
  "status": "pass|issues_found",
  "new_items_checked": ["T003", "T004"],
  "dedup_issues": [],
  "category_issues": [],
  "quality_issues": [],
  "integrity_issues": [],
  "corrections_applied": [],
  "summary": "一致性检查通过，无问题"
}
```
