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

## 统计特征检测工具

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

---

## 评分和报告工具

### 12. calculate_ai_tell_score - 计算 AI 痕迹得分

**用途**: 综合所有检测结果，计算最终得分。

**实现**:
```python
def calculate_ai_tell_score(violations):
    total_deduction = sum(v['weight'] for v in violations)
    score = max(0, 100 - total_deduction)
    
    if score >= 90:
        level = "极低 AI 痕迹"
        suggestion = "通过"
    elif score >= 80:
        level = "低 AI 痕迹"
        suggestion = "通过"
    elif score >= 70:
        level = "中等 AI 痕迹"
        suggestion = "建议修订"
    elif score >= 60:
        level = "较高 AI 痕迹"
        suggestion = "需要修订"
    else:
        level = "高 AI 痕迹"
        suggestion = "建议重写"
    
    return {
        "score": score,
        "level": level,
        "suggestion": suggestion,
        "total_deduction": total_deduction
    }
```

---

### 13. generate_detection_report - 生成检测报告

**用途**: 生成完整的检测报告。

**实现**:
```python
def generate_detection_report(chapter_num, content, violations, statistics, score):
    report = f"""# AI 痕迹检测报告

## 基本信息
- 章节: 第{chapter_num}章
- 字数: {len(tokenize(content))}
- 检测时间: {datetime.now().isoformat()}
- AI 痕迹得分: {score['score']}/100

## 检测结果

### 确定性规则检测

| 规则 | 发现次数 | 权重 | 扣分 |
|------|----------|------|------|
"""
    
    # 按规则分组
    rule_counts = {}
    for v in violations:
        rule = v['rule']
        if rule not in rule_counts:
            rule_counts[rule] = {'count': 0, 'weight': v['weight']}
        rule_counts[rule]['count'] += 1
    
    for rule, data in rule_counts.items():
        deduction = data['count'] * data['weight']
        report += f"| {rule} | {data['count']} 次 | {data['weight']} | -{deduction} |\n"
    
    report += f"\n**总扣分**: -{score['total_deduction']}\n"
    
    # 统计特征
    report += f"""
### 统计特征检测

| 特征 | 数值 | 阈值 | 状态 |
|------|------|------|------|
| TTR | {statistics['ttr']:.3f} | ≥{statistics['thresholds']['ttr_min']} | {'✅' if statistics['ttr'] >= statistics['thresholds']['ttr_min'] else '⚠️'} |
| 句长标准差 | {statistics['sentence_length_std']:.1f} | ≥{statistics['thresholds']['sentence_std_min']} | {'✅' if statistics['sentence_length_std'] >= statistics['thresholds']['sentence_std_min'] else '⚠️'} |
| 主动句比例 | {statistics['active_ratio']*100:.1f}% | ≥{statistics['thresholds']['active_ratio_min']*100}% | {'✅' if statistics['active_ratio'] >= statistics['thresholds']['active_ratio_min'] else '⚠️'} |
"""
    
    # 问题定位
    report += "\n## 问题段落定位\n"
    for i, v in enumerate(violations[:10], 1):  # 只显示前10个
        if 'position' in v:
            report += f"""
### 问题 {i}: {v['rule']}
**位置**: 第{v['position']}段
**建议**: {v.get('suggestion', '')}
"""
    
    # 总结
    report += f"""
## 总结

- AI 痕迹得分: {score['score']}/100
- 检测级别: {score['level']}
- 建议: {score['suggestion']}
"""
    
    return report
```

---

## 检测流程

```json
// 用户请求: "检测第1章的AI痕迹"

// Step 1: 读取章节
content = read({"path": "./novels/仙道长生/chapters/chapter_001.md"})

// Step 2: 获取题材配置
genre_profile = read({"path": "./novels/仙道长生/story/genre_profile.json"})

// Step 3: 执行确定性规则检测
violations = []
violations.extend(detect_forbidden_patterns(content))
violations.extend(detect_transition_words(content))
violations.extend(detect_fatigue_words(content, genre_profile))
violations.extend(detect_meta_narrative(content))
violations.extend(detect_preachy_words(content))
violations.extend(detect_collective_reactions(content))
violations.extend(detect_consecutive_le(content))
violations.extend(detect_long_paragraphs(content))
violations.extend(detect_list_structure(content))

// Step 4: 计算统计特征
statistics = calculate_statistics(content)

// Step 5: 计算得分
score = calculate_ai_tell_score(violations)

// Step 6: 生成报告
report = generate_detection_report(1, content, violations, statistics, score)

// Step 7: 返回结果
return {
    "score": score['score'],
    "level": score['level'],
    "suggestion": score['suggestion'],
    "violations_count": len(violations),
    "report": report
}
```

---

## 批量检测

```json
// 检测整本书
for chapter_num in range(1, total_chapters + 1):
    content = read({"path": f"./novels/{project}/chapters/chapter_{chapter_num:03d}.md"})
    result = detect(content, genre_profile)
    results.append(result)

// 计算平均分
average_score = sum(r['score'] for r in results) / len(results)

// 分布统计
distribution = {
    "90-100": sum(1 for r in results if r['score'] >= 90),
    "80-89": sum(1 for r in results if 80 <= r['score'] < 90),
    "70-79": sum(1 for r in results if 70 <= r['score'] < 80),
    "60-69": sum(1 for r in results if 60 <= r['score'] < 70),
    "<60": sum(1 for r in results if r['score'] < 60)
}

// 高风险章节
high_risk = [i+1 for i, r in enumerate(results) if r['score'] < 70]
```

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