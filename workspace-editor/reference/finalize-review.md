# 定稿审核与差异学习

## 差异分析方法论

### 逐段对比策略

1. 将初稿和终稿按段落分割（空行分隔）
2. 按顺序匹配段落，标记：
   - UNCHANGED: 完全相同
   - MODIFIED: 有修改（重点分析对象）
   - ADDED: 终稿新增段落
   - DELETED: 终稿删除了段落
3. 对 MODIFIED 段落，进一步细化到句子级别分析

### 变更分类标准

| 类别 | 识别特征 | 规则生成方向 |
|------|---------|-------------|
| ai_trace | AI套话被替换为自然表达（如"不禁"→删除） | → replacements/ai-traces.yaml |
| style | 句式重构但含义不变（如长句拆短句、被动改主动） | → rules/learned/ |
| grammar | 修正不通顺或冗余表达（语病、重复、累赘） | → rules/learned/ |
| plot | 内容/情节发生变化（增删情节、调整逻辑） | 不生成规则 |
| setting | 涉及世界观/设定的修改 | 不生成规则 |
| other | 不属于以上类别的变更 | 视情况决定 |

### 分类判断方法

对每个 MODIFIED 段落，通过以下问题链确定类别：

1. **含义是否改变？**
   - 否 → 进入 2（形式层面的修改）
   - 是 → 进入 5（内容层面的修改）

2. **是否涉及 AI 套话/高频词被替换？**
   - 是 → ai_trace（如"不禁"被删除、"竟然"被替换）
   - 否 → 进入 3

3. **是否句式/结构发生了变化？**
   - 是（如长句拆短、倒装、语序调整）→ style
   - 否 → 进入 4

4. **是否存在语病修正或冗余精简？**
   - 是 → grammar
   - 否 → other

5. **是否涉及世界观/设定的修改？**
   - 是 → setting
   - 否 → plot

### 模式提取方法

对同一类别的多条变更，寻找共性：

1. **多次出现相同的 AI 表达被替换** → 高置信度 replacement 规则
   - 示例：3处"不禁"被删除 → 生成一条 replacement
2. **多处句式调整方向一致** → 风格偏好规则
   - 示例：5处长句被拆成短句 → 生成"避免过长句子"规则
3. **单次出现但改动显著** → 标记为低置信度，需更多数据确认
   - 不急于生成规则，记录观察

## 规则生成模板

### AI痕迹替换规则 (→ rules/replacements/ai-traces.yaml)

```yaml
- ai_pattern: "被替换的AI表达"
  human_alternatives: ["用户使用的替换"]
  severity: warning
  note: "定稿分析-章节{N}"
  source: "human_edit"
```

示例：
```yaml
- ai_pattern: "不由自主"
  human_alternatives: ["下意识"]
  severity: warning
  note: "定稿分析-第3章"
  source: "human_edit"
```

### 学习规则 (→ rules/learned/)

新规则使用 H 前缀（Human edit derived），编号从 H001 递增。

```yaml
- id: H001
  name: "规则名称"
  phase: 1
  severity: warning
  type: pattern
  pattern: '正则表达式'
  message: "说明为什么需要避免此模式"
  source: "finalize_chapter_{N}"
  confidence: high|medium|low
  applies_to: [all]
```

示例：
```yaml
- id: H001
  name: "避免连续长句"
  phase: 1
  severity: warning
  type: pattern
  pattern: '[^。！？]{60,}。[^。！？]{60,}。'
  message: "连续两个60字以上的长句会降低阅读节奏"
  source: "finalize_chapter_1"
  confidence: medium
  applies_to: [all]
```

### 置信度定义

| 置信度 | 条件 | 处理 |
|--------|------|------|
| high | 同类变更 ≥3 次，模式一致 | 直接写入 |
| medium | 同类变更 1-2 次，模式清晰 | 写入，标记待验证 |
| low | 单次变更，模式不确定 | 暂不写入，记录观察 |

## 输出 JSON Schema

```json
{
  "mode": 7,
  "chapter": "第X章-标题",
  "review": {
    "grade": "A|B|C|D",
    "issues": []
  },
  "diff_analysis": {
    "total_changes": 25,
    "by_category": {
      "ai_trace": {"count": 8, "examples": ["不禁→删除", "竟然→（重写）"]},
      "style": {"count": 10, "examples": ["长句拆短句", "被动改主动"]},
      "grammar": {"count": 5, "examples": ["冗余副词删除"]},
      "plot": {"count": 2, "examples": ["增加了一段心理描写"]}
    }
  },
  "candidate_rules": [
    {
      "target": "replacements/ai-traces.yaml",
      "rule": {
        "ai_pattern": "不由自主",
        "human_alternatives": ["下意识"],
        "severity": "warning",
        "note": "定稿分析-第1章",
        "source": "human_edit"
      }
    },
    {
      "target": "learned",
      "rule": {
        "id": "H001",
        "name": "避免连续长句",
        "phase": 1,
        "severity": "warning",
        "type": "pattern",
        "pattern": "[^。！？]{60,}。[^。！？]{60,}。",
        "message": "连续两个60字以上的长句会降低阅读节奏",
        "source": "finalize_chapter_1",
        "confidence": "medium",
        "applies_to": ["all"]
      }
    }
  ],
  "summary": "定稿分析：共25处变更，生成3条候选规则（1条replacement + 2条learned）"
}
```
