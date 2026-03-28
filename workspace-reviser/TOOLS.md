# Reviser 工具手册

本文档定义 Reviser (修订者) 可使用的工具。

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取章节内容、真相文件、审计报告。

**常用路径**:
- `./novels/{项目名}/chapters/chapter_{n}.md` - 章节正文
- `./novels/{项目名}/context/tracking/*` - 真相文件
- `./novels/{项目名}/story/story_bible.md` - 故事设定

### 2. write - 写入修订后内容

**用途**: 保存修订后的章节。

**示例**:
```json
write({
  "path": "./novels/仙道长生/chapters/chapter_001_revised.md",
  "content": "# 第一章 觉醒（修订版）\n\n..."
})
```

### 3. edit - 精确修改

**用途**: spot-fix 模式下，精确替换问题句子。

---

## 修订工具

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

## 修订模式选择工具

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

---

## 输出格式

### 修订报告

```markdown
# 修订报告

## 基本信息
- 章节: 第{N}章
- 修订模式: {mode}
- 修订时间: {时间}

## 修改记录

### 修改 1
- **位置**: 第{X}段第{Y}句
- **问题**: {问题描述}
- **原文**: {原句}
- **修订**: {修订后}
- **原因**: {修改原因}

### 修改 2
...

## 验证结果
- 问题修复: {fixed}/{total}
- AI 痕迹变化: {change} ({before} → {after})
- 新问题: {new_issues}

## 建议
{后续建议}
```

---

## 工作流程

### 标准修订流程

```
1. 接收审计报告
   ↓
2. analyze_audit 分析问题
   ↓
3. select_revision_mode 选择模式
   ↓
4. 遍历 critical 问题
   ├─ locate_problem 定位
   ├─ generate_fix 生成方案
   └─ apply_fix 应用修复
   ↓
5. verify_revision 验证结果
   ├─ 问题是否修复
   ├─ AI 痕迹是否增加
   └─ 是否引入新问题
   ↓
6. 生成修订报告
   ↓
7. 返回修订后内容
```

---

## 注意事项

### 不同模式的时间估算

| 模式 | 预估时间 | Token 用量 |
|------|----------|-----------|
| polish | 30秒 | ~1000 |
| spot-fix | 1分钟/问题 | ~500/问题 |
| rewrite | 3-5分钟 | ~4000 |
| rework | 5-10分钟 | ~6000 |
| anti-detect | 3-5分钟 | ~4000 |

### 修订成本控制

- 优先使用 spot-fix 模式（成本低，效果好）
- rewrite 模式要谨慎（可能引入新问题）
- anti-detect 模式后要重新审计

### 错误处理

- 定位失败 → 扩大搜索范围
- 修复失败 → 返回原文，标记问题
- AI 痕迹增加 → 建议保留原文或人工修订

---

## 真相文件一致性

### 职责边界

Reviser **不直接修改**真相文件（7 个 tracking 文件）。Reviser 只修改章节正文内容。

### 真相文件更新触发

当修订涉及以下情况时，调用方（Supervisor）应在修订完成后触发 Writer Phase 2 重新结算真相文件：

- **角色状态变化**: 修改了角色的行为、能力、位置等
- **资源变化**: 修改了物品获取/消耗、金钱变化等
- **伏笔变化**: 修改了伏笔的埋设或回收
- **设定变化**: 修改了世界观、力量体系等设定
- **剧情走向变化**: 修改了核心情节或大纲偏离

### 调用方式

```json
// Supervisor 在收到 Reviser 结果后判断
if (reviser_result.changes涉及设定或状态) {
  sessions_spawn({
    "agentId": "writer",
    "task": "Phase 2: 状态结算（修订触发）\n章节正文: {修订后内容}\n原章节正文: {修订前内容}\n说明: 这是修订后的重算，需对比差异更新真相文件",
    "label": "状态重算-修订-第{N}章",
    "model": { "temperature": 0.3, "max_tokens": 4096 }
  })
}
```

### 简单修订（无需重算）

以下修订不涉及真相文件更新：
- 纯文字润色（替换疲劳词、优化表达）
- 修复语病、错别字
- 调整对话风格（不改变对话内容）
- 修改描写细节（不涉及设定变化）