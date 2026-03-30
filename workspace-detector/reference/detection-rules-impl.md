# 检测规则实现细节

本文档包含工具 2-11 的完整 Python 实现代码。

---

### 2. detect_forbidden_patterns - 禁止句式检测

**用途**: 检测禁止的句式和标点。

**实现**:
```python
FORBIDDEN_PATTERNS = {
    "不是_而是": {
        "pattern": r'不是[^。]{0,20}而是',
        "weight": 10,
        "message": "禁止句式「不是...而是...」"
    },
    "破折号": {
        "pattern": r'——',
        "weight": 8,
        "message": "禁止使用破折号「——」"
    }
}

def detect_forbidden_patterns(content):
    violations = []

    for name, config in FORBIDDEN_PATTERNS.items():
        matches = list(re.finditer(config['pattern'], content))
        for match in matches:
            violations.append({
                "rule": name,
                "weight": config['weight'],
                "position": find_paragraph_number(content, match.start()),
                "context": extract_context(content, match.start()),
                "suggestion": config['message']
            })

    return violations
```

---

### 3. detect_transition_words - 转折词密度检测

**用途**: 检测转折词是否过多。

**实现**:
```python
TRANSITION_WORDS = [
    '仿佛', '宛如', '犹如', '好似',
    '忽然', '突然', '骤然',
    '竟然', '居然', '不料',
    '不禁', '不由得', '忍不住',
    '显然', '明摆着', '显而易见'
]

def detect_transition_words(content):
    violations = []
    word_count = len(tokenize(content))
    threshold = word_count / 3000  # 每 3000 字允许 1 次

    for word in TRANSITION_WORDS:
        count = content.count(word)
        if count > max(1, threshold):
            violations.append({
                "rule": "转折词密度",
                "word": word,
                "count": count,
                "threshold": max(1, threshold),
                "weight": 5,
                "suggestion": f"「{word}」出现{count}次，建议减少"
            })

    return violations
```

---

### 4. detect_fatigue_words - 疲劳词检测

**用途**: 检测题材疲劳词是否过多。

**实现**:
```python
def detect_fatigue_words(content, genre_profile):
    violations = []

    fatigue_words = genre_profile.get('fatigueWords', [])

    for word in fatigue_words:
        count = content.count(word)
        if count > 1:
            violations.append({
                "rule": "高疲劳词",
                "word": word,
                "count": count,
                "weight": 5,
                "suggestion": f"疲劳词「{word}」出现{count}次，建议替换"
            })

    return violations
```

---

### 5. detect_meta_narrative - 元叙事检测

**用途**: 检测编剧旁白式表述。

**实现**:
```python
META_PATTERNS = [
    r'作为[^，]{0,5}，',
    r'要知道，',
    r'不得不说，',
    r'从某种意义上说',
    r'换句话说',
    r'总而言之'
]

def detect_meta_narrative(content):
    violations = []

    for pattern in META_PATTERNS:
        matches = list(re.finditer(pattern, content))
        for match in matches:
            violations.append({
                "rule": "元叙事",
                "weight": 10,
                "position": find_paragraph_number(content, match.start()),
                "context": match.group(),
                "suggestion": "避免元叙事表达，直接叙述"
            })

    return violations
```

---

### 6. detect_preachy_words - 说教词检测

**用途**: 检测作者说教式表达。

**实现**:
```python
PREACHY_WORDS = [
    '显然', '不言而喻', '众所周知',
    '毋庸置疑', '毋庸置疑', '理所当然',
    '显而易见', '毫无悬念'
]

def detect_preachy_words(content):
    violations = []

    for word in PREACHY_WORDS:
        if word in content:
            count = content.count(word)
            violations.append({
                "rule": "作者说教",
                "word": word,
                "count": count,
                "weight": 5,
                "suggestion": f"避免说教词「{word}」"
            })

    return violations
```

---

### 7. detect_collective_reactions - 集体反应套话检测

**用途**: 检测「全场震惊」类套话。

**实现**:
```python
COLLECTIVE_PATTERNS = [
    r'全场[^，]{0,5}震惊',
    r'所有人[^，]{0,5}倒吸.*气',
    r'众人[^，]{0,5}瞳孔.*缩',
    r'所有人[^，]{0,5}目瞪口呆',
    r'全场[^，]{0,5}哗然'
]

def detect_collective_reactions(content):
    violations = []

    for pattern in COLLECTIVE_PATTERNS:
        matches = list(re.finditer(pattern, content))
        for match in matches:
            violations.append({
                "rule": "集体反应套话",
                "weight": 5,
                "context": match.group(),
                "suggestion": "具体描写不同人的反应，而非集体套话"
            })

    return violations
```

---

### 8. detect_consecutive_le - 连续了字检测

**用途**: 检测连续多句含「了」。

**实现**:
```python
def detect_consecutive_le(content):
    violations = []
    sentences = split_sentences(content)

    consecutive_count = 0
    start_index = None

    for i, sentence in enumerate(sentences):
        if '了' in sentence:
            if consecutive_count == 0:
                start_index = i
            consecutive_count += 1

            if consecutive_count >= 6:
                violations.append({
                    "rule": "连续了字",
                    "weight": 3,
                    "start": start_index + 1,
                    "end": i + 1,
                    "count": consecutive_count,
                    "suggestion": f"第{start_index+1}-{i+1}句连续含「了」，建议变化表达"
                })
        else:
            consecutive_count = 0

    return violations
```

---

### 9. detect_long_paragraphs - 段落过长检测

**用途**: 检测过长的段落。

**实现**:
```python
def detect_long_paragraphs(content, threshold=300):
    violations = []
    paragraphs = [p for p in content.split('\n\n') if p.strip()]

    long_paragraphs = []
    for i, p in enumerate(paragraphs):
        if len(p) > threshold:
            long_paragraphs.append(i + 1)

    if len(long_paragraphs) >= 2:
        violations.append({
            "rule": "段落过长",
            "weight": 2,
            "paragraphs": long_paragraphs,
            "suggestion": f"第{long_paragraphs}段超过{threshold}字，建议拆分"
        })

    return violations
```

---

### 10. detect_list_structure - 列表式结构检测

**用途**: 检测「首先/其次/最后」类结构。

**实现**:
```python
LIST_PATTERNS = [
    r'第一[，。].*第二[，。].*第三',
    r'首先[，。].*其次[，。].*最后',
    r'其一[，。].*其二[，。].*其三',
    r'一方面[，。].*另一方面'
]

def detect_list_structure(content):
    violations = []

    for pattern in LIST_PATTERNS:
        if re.search(pattern, content):
            violations.append({
                "rule": "列表式结构",
                "weight": 8,
                "suggestion": "避免列表式结构，用自然叙述代替"
            })

    return violations
```

---

### 11. calculate_statistics - 计算统计特征

**用途**: 计算 TTR、句长标准差等。

**实现**:
```python
def calculate_statistics(content):
    # 分词
    words = tokenize(content)

    # TTR
    total_words = len(words)
    unique_words = len(set(words))
    ttr = unique_words / total_words if total_words > 0 else 0

    # 句长
    sentences = split_sentences(content)
    sentence_lengths = [len(s) for s in sentences]
    sentence_length_std = np.std(sentence_lengths) if sentence_lengths else 0

    # 段落长
    paragraphs = [p for p in content.split('\n\n') if p.strip()]
    paragraph_lengths = [len(p) for p in paragraphs]
    paragraph_length_std = np.std(paragraph_lengths) if paragraph_lengths else 0

    # 主动句比例
    active_count = count_active_sentences(content)
    active_ratio = active_count / len(sentences) if sentences else 0

    return {
        "ttr": ttr,
        "sentence_length_std": sentence_length_std,
        "paragraph_length_std": paragraph_length_std,
        "active_ratio": active_ratio,
        "thresholds": {
            "ttr_min": 0.05,
            "sentence_std_min": 10,
            "paragraph_std_min": 30,
            "active_ratio_min": 0.5
        }
    }
```
