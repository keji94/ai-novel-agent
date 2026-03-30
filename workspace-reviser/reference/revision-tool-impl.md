# 修订工具详细实现

本文档包含 Reviser 修订工具 4-10 的完整实现细节。

---

### 4. analyze_audit - 分析审计报告

**用途**: 从审计报告中提取需要修复的问题。

**输入**:
```json
{
  "audit_result": {
    "critical": [...],
    "warning": [...]
  }
}
```

**输出**:
```json
{
  "critical_issues": [
    {
      "dimension": 1,
      "location": "第3段第2句",
      "description": "OOC问题",
      "suggestion": "修改建议"
    }
  ],
  "warning_issues": [...],
  "priority_order": [1, 3, 5]  // 按优先级排序
}
```

---

### 5. locate_problem - 定位问题位置

**用途**: 在章节正文中定位问题的精确位置。

**实现**:
```python
def locate_problem(chapter_content, issue):
    # 按段落分割
    paragraphs = chapter_content.split('\n\n')

    # 定位段落
    if issue['location'].startswith('第'):
        paragraph_num = extract_number(issue['location'])
        target_paragraph = paragraphs[paragraph_num - 1]

    # 定位句子
    sentences = split_sentences(target_paragraph)

    # 根据问题关键词匹配
    for i, sentence in enumerate(sentences):
        if contains_keywords(sentence, issue['keywords']):
            return {
                "paragraph_index": paragraph_num - 1,
                "sentence_index": i,
                "original_text": sentence,
                "context": get_context(sentences, i)
            }

    return None
```

---

### 6. generate_fix - 生成修复方案

**用途**: 根据问题和上下文生成修复方案。

**Prompt 结构**:
```
## 任务
修复以下章节问题。

## 问题
- 维度: {dimension}
- 描述: {description}
- 位置: {location}
- 建议: {suggestion}

## 原文上下文
{context}

## 修复要求
1. 只修改有问题的部分
2. 保持原有文风
3. 不引入新的问题
4. 保持上下文连贯

## 输出
只输出修复后的内容，不要解释。
```

**调用示例**:
```json
sessions_spawn({
  "agentId": "reviser",
  "task": "修复 OOC 问题\n原文: {原文}\n问题: {问题}\n建议: {建议}",
  "label": "spot-fix-第N段",
  "model": {
    "temperature": 0.3,
    "max_tokens": 1024
  }
})
```

---

### 7. apply_fix - 应用修复

**用途**: 将修复方案应用到章节正文。

**实现**:
```python
def apply_fix(chapter_content, fix):
    paragraphs = chapter_content.split('\n\n')

    # 获取定位
    para_idx = fix['location']['paragraph_index']
    sent_idx = fix['location']['sentence_index']

    # 替换句子
    paragraph = paragraphs[para_idx]
    sentences = split_sentences(paragraph)
    sentences[sent_idx] = fix['revised_text']

    # 重新组合
    paragraphs[para_idx] = join_sentences(sentences)

    return '\n\n'.join(paragraphs)
```

---

### 8. count_ai_tells - AI 痕迹计数

**用途**: 统计章节中的 AI 痕迹数量。

**检测规则**:
```python
def count_ai_tells(content):
    count = 0

    # AI 套话
    ai_phrases = [
        '不得不承认', '毋庸置疑', '显而易见', '众所周知',
        '首先', '其次', '最后', '总而言之',
        '综上所述', '由此可见', '不容置疑'
    ]
    for phrase in ai_phrases:
        count += content.count(phrase)

    # 公式化结构
    if re.search(r'第一[，。].*第二[，。].*第三', content):
        count += 3

    # 段落等长惩罚
    paragraphs = [p for p in content.split('\n\n') if len(p) > 50]
    if len(paragraphs) > 3:
        lengths = [len(p) for p in paragraphs]
        if stdev(lengths) < 20:
            count += 5

    return count
```

---

### 9. verify_revision - 验证修订

**用途**: 验证修订是否成功，是否引入新问题。

**检查项**:
```python
def verify_revision(original, revised, audit_result):
    verification = {
        "issues_fixed": 0,
        "new_issues": [],
        "ai_tell_change": 0
    }

    # 1. 检查问题是否修复
    for issue in audit_result['critical']:
        if issue_resolved(revised, issue):
            verification['issues_fixed'] += 1
        else:
            verification['new_issues'].append({
                "type": "unresolved",
                "issue": issue
            })

    # 2. 检查是否引入新问题
    # (可以调用 Editor 的部分审计维度)

    # 3. 对比 AI 痕迹
    original_ai = count_ai_tells(original)
    revised_ai = count_ai_tells(revised)
    verification['ai_tell_change'] = revised_ai - original_ai

    if verification['ai_tell_change'] > 0:
        verification['new_issues'].append({
            "type": "ai_tell_increase",
            "count": verification['ai_tell_change']
        })

    return verification
```

---

### 10. select_revision_mode - 选择修订模式

**用途**: 根据审计结果自动选择最合适的修订模式。

**决策逻辑**:
```python
def select_revision_mode(audit_result, ai_tell_score):
    critical_count = len(audit_result['critical'])
    warning_count = len(audit_result['warning'])

    # AI 痕迹过重
    if ai_tell_score < 70:
        return "anti-detect"

    # 问题较少
    if critical_count == 0 and warning_count <= 3:
        return "polish"

    # 定点问题
    if critical_count <= 3:
        return "spot-fix"

    # 中等问题
    if critical_count <= 6:
        return "rewrite"

    # 严重问题
    return "rework"
```
