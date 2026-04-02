# 反馈数据 Schema

## 反馈记录格式

每条反馈记录存储在 `feedback/_log.md` 中：

```markdown
### FB-{YYYY}-{NNN}

- **日期**: YYYY-MM-DD
- **内容标识**: {content_id}
- **反馈类型**: FALSE_POSITIVE | MISSED_ISSUE | FIX_APPROVED
- **关联规则**: {rule_id}
- **人工标注**:
  - 原文: "..."
  - 标注说明: "..."
- **处理结果**: 待处理 / 已处理
- **规则变更**: (处理后的变更记录)
```

---

## 反馈类型详细说明

### FALSE_POSITIVE（误报）

Checker 报告了一个问题，但人工审核认为这不是问题。

**触发动作**:
1. 规则的 false_positive_count += 1
2. 更新规则的有效率
3. IF false_positive_rate > 30% AND times_applied >= 5:
   - 规则降级为 experimental
   - 如果关联知识库技巧 → 输出 knowledge_feedback (effective=false)

**记录格式**:
```
- 关联规则: {rule_id}
- Checker 判定: {issue}
- 人工判断: 不是问题的原因
- 处理: 调整阈值/增加排除条件/保持不变
```

### MISSED_ISSUE（漏报）

Checker 未报告问题，但人工检查发现了一个 Checker 应该捕获的问题。

**触发动作**:
1. LLM 分析漏报问题，提取通用模式（1 次 LLM 调用）
2. 生成候选规则 R-L{NNN}.yaml
3. 标记为 experimental
4. 存入 rules/learned/
5. 更新 rules/learned/_index.yaml

**模式提取 Prompt**:
```
分析以下漏报问题，提取可复用的检查规则：
- 漏报段落: {paragraph_text}
- 问题描述: {human_description}
- 上下文: {surrounding_paragraphs}

请提取:
1. 问题模式（通用化描述）
2. 检查逻辑（如何识别这类问题）
3. 严重级别建议
4. 适用场景
```

### FIX_APPROVED（修复确认）

Checker 报告的问题被确认正确，修改建议被采纳。

**触发动作**:
1. 规则的 times_caught += 1
2. 更新规则的有效率
3. 如果关联知识库技巧 T-{NNN}:
   - 输出 knowledge_feedback (effective=true)
   - 输出 knowledge_feedback，由上游 Agent 路由到知识库管理 Agent

---

## 学习规则状态转换

```
  ┌─────────────┐     应用≥10次      ┌───────────────┐     人工审核通过     ┌──────────┐
  │ experimental├───────────────────►│ review_pending ├───────────────────►│  active   │
  │  (实验性)    │   有效率≥50%       │  (待人工审核)    │                    │  (活跃)    │
  └──────┬──────┘                   └───────┬───────┘     ┌─────────────┐ └─────┬─────┘
       ▲  ▲                                 │             │             │       │
       │  │                         审核不通过 │             │ 误报率>30%   │       │
       │  │                                 ▼             │             │       │
       │  │                           ┌──────────┐        │             │       │
       │  └───────────────────────────┤deprecated│◄───────┘             │       │
       │        重新验证               │ (已废弃)  │                      │       │
       │                              └──────────┘    ┌─────────────────┘       │
       │                                              │ 审核通过                  │
       │                                              ▼                          │
       │                                       ┌──────────────┐               │
       └───────────────────────────────────────│review_needed │───────────────┘
              重新实验                           │ (降级待审核)  │  审核不通过
                                                └──────┬───────┘
                                                       │ 审核不通过
                                                       ▼
                                                ┌──────────┐
                                                │deprecated│
                                                │ (已废弃)  │
                                                └──────────┘
```

### review_pending 行为

- 仍然参与检查（与 experimental 相同行为）
- 产生的 violation 标记 `source: "learned_review_pending"`
- **不影响正式评分**（仅记录，不扣分）
- 出现在检查报告的单独 section: `pending_review_violations`

### 批量审核接口

```json
{
  "review_action": "batch_review",
  "reviews": [
    { "rule_id": "R-L003", "action": "approve", "note": "模式有效" },
    { "rule_id": "R-L005", "action": "reject", "note": "过于宽泛" },
    { "rule_id": "R-L006", "action": "retest", "note": "需更多数据" }
  ]
}
```

---

## 候选规则生成模板

```yaml
id: R-L{NNN}  # 自动递增
name: "从反馈提取的规则名称"
source: human_feedback
created_from: "feedback/FB-{YYYY}-{NNN}"
created_at: "{timestamp}"
severity: warning  # 默认 warning，需验证后可能升级
pattern_type: structural|semantic|contextual
check_prompt: |
  {LLM 提取的检查逻辑描述}
applies_to: [all|dialogue|action|description]
status: experimental
effectiveness:
  times_applied: 0
  times_caught: 0
  false_positive_count: 0
  false_positive_rate: null
```

---

## 批量反馈处理

支持一次提交多条反馈：

```json
{
  "feedback_batch": [
    {
      "content_id": "内容标识",
      "type": "FALSE_POSITIVE",
      "rule_id": "{rule_id}",
      "original_text": "...",
      "note": "这里是合理使用，不是滥用"
    },
    {
      "content_id": "内容标识",
      "type": "MISSED_ISSUE",
      "paragraph_index": 12,
      "original_text": "...",
      "issue_description": "问题描述",
      "severity_suggestion": "warning"
    }
  ]
}
```
