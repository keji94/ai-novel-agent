# 统计分析工具详细实现

本文档包含 StyleAnalyzer 统计分析工具（工具 3-8）的完整实现代码。

---

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
