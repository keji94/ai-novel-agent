# Detector 工具手册

本文档定义 Detector (AI 痕迹检测器) 可使用的工具。

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取待检测的章节内容。

**示例**:
```json
read({"path": "./novels/仙道长生/chapters/chapter_001.md"})
```

---

## 确定性规则检测工具

> 详细实现见 reference/detection-rules-impl.md

| # | Tool | Purpose | Weight |
|---|------|---------|--------|
| 2 | `detect_forbidden_patterns` | 检测禁止的句式和标点（如「不是...而是...」、破折号） | 10/8 |
| 3 | `detect_transition_words` | 检测转折词密度是否过高（每 3000 字允许 1 次） | 5 |
| 4 | `detect_fatigue_words` | 检测题材疲劳词是否过多（依赖 genre_profile） | 5 |
| 5 | `detect_meta_narrative` | 检测编剧旁白式表述（如「作为...」「要知道」） | 10 |
| 6 | `detect_preachy_words` | 检测作者说教式表达（如「显然」「毋庸置疑」） | 5 |
| 7 | `detect_collective_reactions` | 检测「全场震惊」类集体反应套话 | 5 |
| 8 | `detect_consecutive_le` | 检测连续多句含「了」（>=6 句触发） | 3 |
| 9 | `detect_long_paragraphs` | 检测过长段落（>=2 段超 300 字触发） | 2 |
| 10 | `detect_list_structure` | 检测「首先/其次/最后」类列表式结构 | 8 |

---

## 统计特征检测工具

> 详细实现见 reference/detection-rules-impl.md

### 11. calculate_statistics - 计算统计特征

**用途**: 计算 TTR（词汇丰富度）、句长标准差、段落长标准差、主动句比例等。

**返回**: `ttr`, `sentence_length_std`, `paragraph_length_std`, `active_ratio` + 各项阈值

---

## 评分和报告工具

> 详细实现见 reference/scoring-report.md

### 12. calculate_ai_tell_score - 计算 AI 痕迹得分

**用途**: 综合所有 violations 的权重扣分，计算 0-100 分及等级建议。

**等级**: 90+ 极低 | 80-89 低 | 70-79 中等 | 60-69 较高 | <60 高

### 13. generate_detection_report - 生成检测报告

**用途**: 生成含基本信息、规则检测表、统计特征表、问题段落定位的完整报告。

---

## 检测流程

1. `read` 读取章节内容 + 题材配置
2. 依次执行工具 2-10 的确定性规则检测，收集 violations
3. `calculate_statistics` 计算统计特征
4. `calculate_ai_tell_score` 计算最终得分
5. `generate_detection_report` 生成报告

支持单章检测和批量检测（整本书），批量检测输出平均分、分布统计和高风险章节列表。

> 详细实现见 reference/detection-workflow.md

---

## 注意事项

### 检测精度
- 确定性规则准确率高（95%+）
- 语义分析需要 LLM，成本较高
- 建议优先使用确定性规则

### 批量检测建议
- 先对可疑章节进行详细检测
- 对得分低的章节优先修订
- 定期检测整本书的 AI 痕迹分布
