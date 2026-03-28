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

### 3. analyze_sentence_length - 句长分析

**用途**: 统计句子长度分布。

**实现**:
```python
def analyze_sentence_length(content):
    # 分句
    sentences = split_sentences(content)
    
    # 计算长度
    lengths = [len(s) for s in sentences]
    
    return {
        "mean": np.mean(lengths),
        "std": np.std(lengths),
        "min": min(lengths),
        "max": max(lengths),
        "distribution": {
            "short_1_10": sum(1 for l in lengths if l <= 10) / len(lengths),
            "medium_11_30": sum(1 for l in lengths if 11 <= l <= 30) / len(lengths),
            "long_31_60": sum(1 for l in lengths if 31 <= l <= 60) / len(lengths),
            "very_long_61_plus": sum(1 for l in lengths if l > 60) / len(lengths)
        }
    }
```

---

### 4. analyze_vocabulary - 词汇分析

**用途**: 分析词汇特征。

**实现**:
```python
def analyze_vocabulary(content):
    # 分词
    words = tokenize(content)
    
    # 统计
    total_words = len(words)
    unique_words = len(set(words))
    ttr = unique_words / total_words if total_words > 0 else 0
    
    # 词频统计
    word_freq = Counter(words)
    top_100 = word_freq.most_common(100)
    
    # 停用词过滤后的高频词
    stop_words = set(['的', '了', '是', '在', '有', '和', '不', '我', '他', '她'])
    content_words = [w for w in words if w not in stop_words]
    content_freq = Counter(content_words)
    top_content = content_freq.most_common(50)
    
    return {
        "ttr": ttr,
        "total_words": total_words,
        "unique_words": unique_words,
        "top_100_words": [w for w, _ in top_100],
        "top_content_words": top_content,
        "rare_words": [w for w, c in word_freq.items() if c == 1][:100]
    }
```

---

### 5. analyze_paragraph - 段落分析

**用途**: 分析段落结构。

**实现**:
```python
def analyze_paragraph(content):
    # 分段
    paragraphs = content.split('\n\n')
    paragraphs = [p.strip() for p in paragraphs if p.strip()]
    
    # 段落长度
    lengths = [len(p) for p in paragraphs]
    
    # 对话检测
    dialogue_count = sum(1 for p in paragraphs if has_dialogue(p))
    dialogue_ratio = dialogue_count / len(paragraphs)
    
    # 描写检测
    description_count = sum(1 for p in paragraphs if has_description(p))
    description_ratio = description_count / len(paragraphs)
    
    return {
        "mean_length": np.mean(lengths),
        "count": len(paragraphs),
        "dialogue_ratio": dialogue_ratio,
        "description_ratio": description_ratio,
        "narrative_ratio": 1 - dialogue_ratio - description_ratio
    }
```

---

### 6. analyze_sentence_types - 句式分析

**用途**: 分析句子类型分布。

**实现**:
```python
def analyze_sentence_types(content):
    sentences = split_sentences(content)
    
    types = {
        "declarative": 0,  # 陈述句
        "exclamatory": 0,  # 感叹句
        "interrogative": 0,  # 疑问句
        "imperative": 0   # 祈使句
    }
    
    for s in sentences:
        if s.endswith('！') or s.endswith('!'):
            types["exclamatory"] += 1
        elif s.endswith('？') or s.endswith('?'):
            types["interrogative"] += 1
        elif is_imperative(s):
            types["imperative"] += 1
        else:
            types["declarative"] += 1
    
    total = sum(types.values())
    return {k: v / total for k, v in types.items()}
```

---

### 7. analyze_rhetoric - 修辞分析

**用途**: 统计修辞手法使用频率。

**实现**:
```python
def analyze_rhetoric(content):
    word_count = len(tokenize(content))
    
    # 比喻检测
    metaphors = len(re.findall(r'像|如|似|若|仿佛|宛如', content))
    
    # 排比检测
    parallelisms = detect_parallelism(content)
    
    # 拟人检测
    personifications = detect_personification(content)
    
    return {
        "metaphor_per_1000": metaphors / (word_count / 1000),
        "parallelism_per_1000": parallelisms / (word_count / 1000),
        "personification_per_1000": personifications / (word_count / 1000)
    }
```

---

### 8. analyze_rhythm - 节奏分析

**用途**: 分析叙事节奏。

**实现**:
```python
def analyze_rhythm(content):
    paragraphs = content.split('\n\n')
    
    fast_count = 0  # 快节奏：短句多、对话多
    slow_count = 0  # 慢节奏：长句多、描写多
    
    for p in paragraphs:
        sentences = split_sentences(p)
        avg_length = np.mean([len(s) for s in sentences])
        dialogue_ratio = count_dialogue(p) / len(p)
        
        if avg_length < 20 or dialogue_ratio > 0.5:
            fast_count += 1
        elif avg_length > 40 or has_long_description(p):
            slow_count += 1
    
    total = len(paragraphs)
    medium_count = total - fast_count - slow_count
    
    return {
        "fast_passages": fast_count / total,
        "medium_passages": medium_count / total,
        "slow_passages": slow_count / total
    }
```

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

---

## 分析流程示例

```json
// 用户请求: "分析 ./reference/作者A.txt 的文风"

// Step 1: 读取参考文本
content = read({"path": "./reference/作者A.txt"})

// Step 2: 检查字数
word_count = len(tokenize(content))
if word_count < 10000:
    return "警告：样本字数不足 10000，分析结果可能不准确"

// Step 3: 执行各项分析
profile = {
    "sentence_length": analyze_sentence_length(content),
    "vocabulary": analyze_vocabulary(content),
    "paragraph": analyze_paragraph(content),
    "sentence_types": analyze_sentence_types(content),
    "rhetoric": analyze_rhetoric(content),
    "rhythm": analyze_rhythm(content)
}

// Step 4: 保存风格指纹
write({
    "path": "./output/style_profile.json",
    "content": json.dumps(profile, ensure_ascii=False, indent=2)
})

// Step 5: 生成风格指南（调用 LLM）
guide = generate_style_guide(profile)

// Step 6: 保存风格指南
write({
    "path": "./output/style_guide.md",
    "content": guide
})

// Step 7: 返回分析报告
return {
    "status": "success",
    "word_count": word_count,
    "key_features": [
        f"平均句长: {profile['sentence_length']['mean']:.1f}字",
        f"词汇多样性: {profile['vocabulary']['ttr']:.3f}",
        f"对话占比: {profile['paragraph']['dialogue_ratio']*100:.1f}%"
    ],
    "files": [
        "./output/style_profile.json",
        "./output/style_guide.md"
    ]
}
```

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