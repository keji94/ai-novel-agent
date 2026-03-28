# StyleAnalyzer 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | 用户风格分析请求 | 参考文本路径 + 作者名(可选) + 目标项目(可选) |

## 工作模式

### 模式 1: 完整风格分析

```
适用场景:
  - 首次分析某个作者的文风
  - 需要完整的风格指纹和指南
  - 参考文本 ≥ 10000 字

输入:
  - source_path: 参考文本文件路径
  - author: 作者名称（可选）
  - min_sample_length: 10000（建议 50000+）

输出:
  - style_profile.json: 统计风格指纹
  - style_guide.md: 可读风格指南

流程:
  1. 读取参考文本
  2. 统计分析（6 个维度）
     ├── 句长分析: 平均值、标准差、分布
     ├── 词汇分析: TTR、高频词、独特词
     ├── 段落分析: 平均长度、对话/描写/叙述占比
     ├── 句型分析: 陈述/感叹/疑问/祈使占比
     ├── 修辞分析: 比喻/排比/拟人频率
     └── 节奏分析: 快/中/慢段落分布
  3. 生成 style_profile.json（数值指纹）
  4. 通过 LLM 生成 style_guide.md（人类可读指南）
  5. 输出分析结果
```

### 模式 2: 快速风格检测

```
适用场景:
  - 快速了解文本风格特征
  - 不需要完整指南，只需统计数据
  - 参考文本较短（≥ 3000 字）

输入:
  - source_path: 参考文本文件路径

输出:
  - style_profile.json: 仅统计维度数据

流程:
  1. 读取参考文本
  2. 运行统计维度分析
  3. 输出 style_profile.json
```

### 模式 3: 风格应用到书籍

```
适用场景:
  - 已有风格分析结果
  - 需要将风格应用到某个书籍项目

输入:
  - profile_path: style_profile.json 路径
  - guide_path: style_guide.md 路径
  - project_name: 目标项目名称

输出:
  - 已复制到项目目录的风格文件
  - 更新后的 book_rules.md

流程:
  1. 验证风格文件存在
  2. 复制到目标项目目录
     - style_profile.json → ./novels/{项目}/style/
     - style_guide.md → ./novels/{项目}/style/
  3. 更新 book_rules.md 添加风格引用
  4. 输出应用结果
```

## 协作接口

### 接收任务

```json
{
  "task": "分析文风",
  "source": {
    "path": "./reference/author_work.txt",
    "author": "作者名",
    "min_length": 10000
  },
  "project_name": "仙道长生",
  "apply_to_project": true,
  "analysis_depth": "full|quick"
}
```

### 输出结果

```json
{
  "status": "success",
  "profile": {
    "path": "./novels/仙道长生/style/style_profile.json",
    "key_characteristics": {
      "avg_sentence_length": 18.5,
      "ttr": 0.12,
      "dialogue_ratio": 0.35,
      "description_ratio": 0.25,
      "narration_ratio": 0.40,
      "dominant_rhythm": "快节奏"
    }
  },
  "guide": {
    "path": "./novels/仙道长生/style/style_guide.md",
    "summary": "短句为主，对话密集，快节奏，善用比喻"
  },
  "applied_to_project": true,
  "sync_hint": {
    "type": "settings",
    "project": "仙道长生",
    "files": [
      "./novels/仙道长生/style/style_profile.json",
      "./novels/仙道长生/style/style_guide.md"
    ]
  }
}
```

## 输出给其他 Agent

### 给 Supervisor

```json
{
  "status": "success",
  "summary": "风格分析完成：短句为主（均值 18.5 字），TTR 0.12，对话占比 35%，快节奏",
  "applied": true,
  "project": "仙道长生"
}
```

### 给 Writer（风格引用）

```json
{
  "task": "加载风格指南",
  "style_guide_path": "./novels/仙道长生/style/style_guide.md",
  "key_constraints": [
    "句长控制在 15-22 字",
    "对话占比 30-40%",
    "避免长段落（> 200 字）",
    "比喻每 3000 字 ≤ 2 次"
  ]
}
```

## 风格指纹格式 (style_profile.json)

```json
{
  "metadata": {
    "author": "作者名",
    "source_file": "参考文件路径",
    "sample_length": 50000,
    "analyzed_at": "2026-03-28"
  },
  "sentence": {
    "avg_length": 18.5,
    "std_dev": 12.3,
    "distribution": {
      "short_le10": 0.25,
      "medium_10_25": 0.45,
      "long_gt25": 0.30
    }
  },
  "vocabulary": {
    "ttr": 0.12,
    "top_frequency_words": ["的", "了", "是", "在", "他"],
    "unique_words_count": 3200
  },
  "paragraph": {
    "avg_length": 85.0,
    "dialogue_ratio": 0.35,
    "description_ratio": 0.25,
    "narration_ratio": 0.40
  },
  "sentence_types": {
    "declarative": 0.70,
    "exclamatory": 0.12,
    "interrogative": 0.08,
    "imperative": 0.10
  },
  "rhetoric": {
    "metaphor_per_3000": 1.5,
    "parallelism_per_3000": 0.8,
    "personification_per_3000": 0.3
  },
  "rhythm": {
    "fast": 0.40,
    "medium": 0.35,
    "slow": 0.25
  }
}
```

## 风格指南格式 (style_guide.md)

```markdown
# 风格指南：{作者名}

## 整体风格
[一句话总结风格特征]

## 句式特征
- 平均句长：{X} 字
- 建议：控制句子在 {min}-{max} 字之间
- 句式变化：{大/中/小}

## 词汇偏好
- 词汇多样性：{高/中/低}
- 常用修辞：{修辞手法}
- 避免词汇：{从疲劳词列表}

## 描写风格

### 环境描写
[特征描述]

### 动作描写
[特征描述]

### 心理描写
[特征描述]

## 对话风格
[特征描述]

## 节奏控制
- 快节奏段落占比：{X}%
- 建议快慢比：{X}:{Y}

## 禁忌
- 避免的表达方式
- 避免的句式结构
```

## 注意事项

- 参考文本至少 3000 字才能进行有意义的分析
- 50000+ 字的参考文本可产生更准确的指纹
- 风格指南是指导性的，Writer 不需要完全遵循
- 多作者风格可叠加使用（取平均值或加权）
