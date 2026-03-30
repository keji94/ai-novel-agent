# StyleAnalyzer 工具手册

本文档定义 StyleAnalyzer (文风分析器) 可使用的工具。

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取参考文本。

**示例**:
```json
read({"path": "./reference/作者A_代表作.txt"})
```

### 2. write - 写入风格文件

**用途**: 保存风格指纹和风格指南。

**示例**:
```json
write({
  "path": "./novels/仙道长生/story/style_profile.json",
  "content": "{...}"
})

write({
  "path": "./novels/仙道长生/story/style_guide.md",
  "content": "# 风格指南..."
})
```

---

## 统计分析工具

| # | 工具名 | 用途 |
|---|--------|------|
| 3 | `analyze_sentence_length` | 统计句子长度分布 |
| 4 | `analyze_vocabulary` | 分析词汇特征（TTR、高频词、罕见词） |
| 5 | `analyze_paragraph` | 分析段落结构（对话/描写/叙述占比） |
| 6 | `analyze_sentence_types` | 分析句子类型分布（陈述/感叹/疑问/祈使） |
| 7 | `analyze_rhetoric` | 统计修辞手法使用频率（比喻/排比/拟人） |
| 8 | `analyze_rhythm` | 分析叙事节奏（快/中/慢段落占比） |

> 详细实现见 [reference/analysis-tool-impl.md](reference/analysis-tool-impl.md)

---

## 风格指纹与指南生成

| # | 工具名 | 用途 |
|---|--------|------|
| 9 | `generate_style_profile` | 整合所有分析结果，生成 style_profile.json |
| 10 | `generate_style_guide` | 基于分析结果，调用 LLM 生成 style_guide.md |
| 11 | `apply_style` | 将风格指纹和指南应用到指定书籍 |

> 详细实现见 [reference/profile-generation.md](reference/profile-generation.md)

---

## 分析流程

标准流程：读取文本 → 字数检查 → 执行 6 项分析 → 保存指纹 → 生成指南 → 返回报告。

> 完整分析流程见 [reference/analysis-workflow.md](reference/analysis-workflow.md)

---

## 注意事项

### 样本要求
- 最少 10000 字
- 建议 50000 字以上
- 题材要一致
- 作者要单一

### 分析精度
- 样本越大，分析越准确
- 混合风格文本会影响准确性
- 需要去除非正文内容（序言、后记等）

### 应用建议
- 风格指南作为参考，不是强制规则
- 可结合多个作者的风格
- 定期更新风格指纹
