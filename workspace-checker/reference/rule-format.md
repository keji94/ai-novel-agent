# 规则编写指南

> 规则格式完整规范: `.openclaw/skills/content-scanner/reference/rule-schema.md`
> 本文件是快速入门指南。

## 规则发现

Scanner 从以下目录自动发现规则（路径由 `domain-config.yaml` 的 `paths` 节配置）：

| 规则类型 | 目录 | 说明 |
|---------|------|------|
| 确定性规则 | `paths.deterministic_dir` | Phase 1，零 LLM 成本 |
| LLM 规则 | `paths.llm_dir` | Phase 2，语义判断 |
| 学习规则 | `paths.learned_dir` | 自动生成，有生命周期管理 |
| 替换表 | `paths.replacements_dir` | AI 痕迹替换对 |

所有目录下的 `*.yaml` 文件会被自动加载。规则索引由宿主项目的 `rules/_index.md` 提供。

---

## 确定性规则 (Phase 1)

### 支持的 type

| type | 说明 | 必需字段 |
|------|------|---------|
| `pattern` | 单正则匹配 | `pattern` |
| `patterns` | 多正则列表，任一匹配触发 | `patterns` (list) |
| `density` | 词频密度 vs 阈值 | `words`, `threshold` |
| `fatigue` | 按 genre 选词表，每词最多1次 | `genre_profiles` |
| `keyword_list` | 关键词计数，全内容最多1次 | `keywords` or `words` |
| `pattern_list` | 多正则组合匹配 | `patterns` (list) |
| `consecutive` | 连续句子含目标字符 | `target_char`, `threshold` |
| `length_check` | 段落长度检查 | `threshold`, `min_violations` |
| `consecutive_pattern` | 连续段落开头重复 | `threshold` |
| `settings_gate` | 上下文源交叉比对 | (需 context_dir) |
| `statistical` | 全文统计特征 | `metric`, `threshold`, `comparison` |

### YAML Schema

```yaml
- id: D{NNN}
  name: "规则名称"
  phase: 1
  severity: critical | warning
  weight: {N}            # 1-10
  type: pattern          # 上表中的 type
  # ... type 特定字段
  message: "违规描述"
  applies_to: [all | dialogue | action | description]
  source: "规则来源标注"
```

### 示例

```yaml
- id: D001
  name: "禁止句式检查"
  phase: 1
  severity: critical
  weight: 10
  type: pattern
  pattern: '不是[^，。！？]{1,30}而是'
  message: "使用禁止句式「不是...而是...」"
  applies_to: [all]
```

---

## LLM 规则 (Phase 2)

### YAML Schema

```yaml
- id: L{NNN}
  name: "规则名称"
  phase: 2
  severity: critical | warning
  weight: {N}
  check_prompt: |
    多行 LLM 检查逻辑描述。
    应包含:
    1. 检查什么
    2. 什么算违规
    3. 严重级别判断标准
  context_requirements:     # 可选：依赖的上下文源
    - 上下文文件名
  applies_to: [all | dialogue | action | description]
  source: "规则来源标注"
```

### check_prompt 编写指南

好的 check_prompt 应该：
- **明确检查目标**: 具体检查什么问题
- **给出判断标准**: 什么情况下算违规
- **区分严重级别**: critical vs warning 的界限
- **提供上下文依赖**: 需要什么上下文信息辅助判断

---

## 学习规则

由自学习引擎从人工反馈自动生成，遵循以下 schema：

```yaml
id: R-L{NNN}              # 自动递增
name: "从反馈提取的规则名称"
source: human_feedback
created_from: "feedback/FB-{YYYY}-{NNN}"
severity: warning
pattern_type: structural | semantic | contextual
check_prompt: |
  {LLM 提取的检查逻辑描述}
applies_to: [all]
status: experimental       # → review_pending → active
effectiveness:
  times_applied: 0
  times_caught: 0
  false_positive_count: 0
  false_positive_rate: null
```

---

## 新增规则步骤

1. 在对应目录创建/编辑 YAML 文件
2. 更新 `rules/_index.md` 的统计信息
3. 如果规则需要特定上下文字段，更新 `domain-config.yaml` 的 `field_rule_map`
4. 如果规则属于某个关联分组，更新 `correlation_groups`

## 规则编号约定

| 前缀 | 范围 | 类型 |
|------|------|------|
| `D{NNN}` | D001-D999 | 确定性规则 |
| `L{NNN}` | L001-L999 | LLM 规则 |
| `R-L{NNN}` | R-L001-R-L999 | 学习规则（自动生成） |
