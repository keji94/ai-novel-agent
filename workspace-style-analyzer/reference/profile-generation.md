# 风格指纹与风格指南生成

本文档包含 StyleAnalyzer 风格生成与应用工具（工具 9-11）的完整实现。

---

### 9. generate_style_profile - 生成风格指纹

**用途**: 整合所有分析结果，生成 style_profile.json。

```python
def generate_style_profile(content, source, author=None):
    return {
        "metadata": {
            "source": source,
            "author": author or "未知",
            "word_count": len(tokenize(content)),
            "analyzed_at": datetime.now().isoformat()
        },
        "sentence_length": analyze_sentence_length(content),
        "vocabulary": analyze_vocabulary(content),
        "paragraph": analyze_paragraph(content),
        "sentence_types": analyze_sentence_types(content),
        "rhetoric": analyze_rhetoric(content),
        "rhythm": analyze_rhythm(content)
    }
```

---

### 10. generate_style_guide - 生成风格指南

**用途**: 基于分析结果，生成 style_guide.md。

**Prompt 结构**:
```
## 任务
根据以下风格分析数据，生成一份详细的风格指南。

## 分析数据
{style_profile}

## 输出要求
1. 整体风格描述（1-2段）
2. 句式特点（长短句、句式类型）
3. 词汇特点（用词偏好、特色词汇）
4. 描写风格（环境、动作、心理）
5. 对话风格
6. 节奏控制
7. 禁忌事项

## 格式
使用 Markdown 格式，清晰分节。
```

**调用示例**:
```json
sessions_spawn({
  "agentId": "style-analyzer",
  "task": "生成风格指南\n分析数据: {style_profile}\n作者: {作者名}",
  "label": "生成风格指南",
  "model": {
    "temperature": 0.3,
    "max_tokens": 4096
  }
})
```

---

## 风格应用

### 11. apply_style - 应用风格到书籍

**用途**: 将风格指纹和指南应用到指定书籍。

**实现**:
```json
// Step 1: 复制风格文件到书籍目录
exec({
  "command": "cp style_profile.json ./novels/仙道长生/story/"
})

exec({
  "command": "cp style_guide.md ./novels/仙道长生/story/"
})

// Step 2: 更新 book_rules.md
edit({
  "path": "./novels/仙道长生/story/book_rules.md",
  "oldText": "## 文风要求\n（待填充）",
  "newText": "## 文风要求\n请参考 style_guide.md"
})
```
