# Editor 工具手册 v2.0

> **重大升级**: 33 维度审计 + AI 痕迹检测 + 自动修订建议

---

## 核心能力：33 维度审计

### 审计维度分类

#### 基础一致性维度 (1-7)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 1 | OOC检查 | 角色行为是否符合人设 | critical |
| 2 | 时间线检查 | 时间是否混乱、跳跃 | critical |
| 3 | 设定冲突 | 是否与世界观设定矛盾 | critical |
| 4 | 战力崩坏 | 战斗力是否前后不一致 | critical |
| 5 | 数值检查 | 数值型资源是否一致 | critical |
| 6 | 伏笔检查 | 伏笔是否遗忘或冲突 | warning |
| 7 | 节奏检查 | 叙事节奏是否合理 | warning |

#### 内容质量维度 (8-14)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 8 | 文风检查 | 文风是否一致 | warning |
| 9 | 信息越界 | 角色是否知道不该知道的事 | critical |
| 10 | 词汇疲劳 | 高频词是否过多 | warning |
| 11 | 利益链断裂 | 角色行为动机是否合理 | critical |
| 12 | 年代考据 | 历史背景是否准确 | warning |
| 13 | 配角降智 | 配角是否为推剧情变蠢 | critical |
| 14 | 配角工具人化 | 配角是否只有工具价值 | warning |

#### 叙事技巧维度 (15-19)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 15 | 爽点虚化 | 爽点是否到位 | warning |
| 16 | 台词失真 | 对话是否符合角色身份 | warning |
| 17 | 流水账 | 是否过于平铺直叙 | warning |
| 18 | 知识库污染 | 是否引入不相关设定 | warning |
| 19 | 视角一致性 | 视角是否混乱 | critical |

#### AI 痕迹维度 (20-23)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 20 | 段落等长 | 段落长度是否过于均匀 | warning |
| 21 | 套话密度 | AI 套话是否过多 | warning |
| 22 | 公式化转折 | 转折是否公式化 | warning |
| 23 | 列表式结构 | 是否使用列表式叙述 | warning |

#### 支线弧线维度 (24-26)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 24 | 支线停滞 | 支线是否长期未推进 | warning |
| 25 | 弧线平坦 | 角色成长弧线是否平淡 | warning |
| 26 | 节奏单调 | 整体节奏是否单调 | warning |

#### 敏感内容维度 (27)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 27 | 敏感词检查 | 是否包含敏感词汇 | critical |

#### 番外/同人专属维度 (28-33)

| ID | 维度 | 检查内容 | 严重级别 |
|----|------|----------|----------|
| 28 | 正传事件冲突 | 番外是否与正传矛盾 | critical |
| 29 | 未来信息泄露 | 角色是否知道未来信息 | critical |
| 30 | 世界规则跨书一致性 | 世界规则是否一致 | critical |
| 31 | 番外伏笔隔离 | 番外是否越权回收正传伏笔 | critical |
| 32 | 读者期待管理 | 是否违背读者期待 | warning |
| 33 | 大纲偏离检测 | 是否严重偏离大纲 | critical |

---

## 审计报告格式

```markdown
# 审计报告

## 基本信息
- 项目: {项目名}
- 章节: 第{N}章
- 审计时间: {时间}
- 审计维度: 33 维度

## 总体评价
- 等级: A/B/C/D
- 字数: {字数}
- 通过维度: {通过数}/33
- Critical 问题: {数量}
- Warning 问题: {数量}

## 详细问题

### Critical 问题

#### [维度ID] 维度名称
- **位置**: 第{X}段 / 第{Y}行
- **问题描述**: {具体问题}
- **建议修复**: {修复建议}

### Warning 问题

#### [维度ID] 维度名称
- **位置**: 第{X}段
- **问题描述**: {具体问题}
- **建议修复**: {修复建议}

## 审计通过条件
- [ ] 无 Critical 问题
- [ ] Warning 问题 ≤ 5 个
- [ ] 通过维度 ≥ 28/33

## 修订建议
- 模式: polish / spot-fix / rewrite / rework / anti-detect
- 重点: {需要重点修复的维度}
```

---

## 详细审计实现

### 维度 1: OOC检查

**检查项**:
- 角色行为是否符合已建立的性格
- 角色说话风格是否一致
- 角色决策是否合理（基于动机）

**检测方法**:
```python
def check_ooc(chapter_content, character_matrix):
    issues = []
    
    for character in get_characters(chapter_content):
        # 读取角色设定
        char_profile = character_matrix[character]
        
        # 检查行为
        actions = extract_actions(chapter_content, character)
        for action in actions:
            if not matches_personality(action, char_profile['personality']):
                issues.append({
                    "dimension": 1,
                    "severity": "critical",
                    "location": find_location(chapter_content, action),
                    "description": f"{character}的「{action}」行为与人设不符",
                    "suggestion": f"建议修改为符合{char_profile['personality']}性格的行为"
                })
        
        # 检查对话
        dialogues = extract_dialogues(chapter_content, character)
        for dialogue in dialogues:
            if not matches_speaking_style(dialogue, char_profile['speaking_style']):
                issues.append({
                    "dimension": 1,
                    "severity": "warning",
                    "location": find_location(chapter_content, dialogue),
                    "description": f"{character}的对话风格与设定不一致",
                    "suggestion": f"建议调整为{char_profile['speaking_style']}风格"
                })
    
    return issues
```

### 维度 2: 时间线检查

**检查项**:
- 时间是否倒流（事件顺序错误）
- 时间跨度是否合理
- 季节/天气是否连续

**检测方法**:
```python
def check_timeline(chapter_content, current_state, chapter_n):
    issues = []
    
    # 提取时间信息
    time_info = extract_time_info(chapter_content)
    
    # 对比上一章时间
    prev_time = current_state.get('last_time')
    if prev_time and time_info['time'] < prev_time:
        issues.append({
            "dimension": 2,
            "severity": "critical",
            "description": f"时间倒流：上一章是{prev_time}，本章是{time_info['time']}"
        })
    
    # 检查时间跨度
    time_span = calculate_time_span(prev_time, time_info['time'])
    if time_span > REASONABLE_SPAN:
        issues.append({
            "dimension": 2,
            "severity": "warning",
            "description": f"时间跨度过大：{time_span}"
        })
    
    return issues
```

### 维度 3: 设定冲突

**检查项**:
- 世界观设定是否一致
- 力量体系是否一致
- 地理设定是否一致

**检测方法**:
```python
def check_setting_conflict(chapter_content, story_bible):
    issues = []
    
    # 提取设定引用
    setting_refs = extract_setting_refs(chapter_content)
    
    for ref in setting_refs:
        # 检查世界观
        if ref['type'] == 'world':
            if not matches_world_setting(ref, story_bible['world']):
                issues.append({
                    "dimension": 3,
                    "severity": "critical",
                    "description": f"世界观冲突：{ref['content']}"
                })
        
        # 检查力量体系
        if ref['type'] == 'power':
            if not matches_power_system(ref, story_bible['power_system']):
                issues.append({
                    "dimension": 3,
                    "severity": "critical",
                    "description": f"力量体系冲突：{ref['content']}"
                })
    
    return issues
```

### 维度 5: 数值检查

**检查项**:
- 资源数量是否一致
- 资源变化是否在账本中
- 是否有凭空出现的资源

**检测方法**:
```python
def check_numerical(chapter_content, particle_ledger):
    issues = []
    
    # 提取资源变化
    resource_changes = extract_resource_changes(chapter_content)
    
    for change in resource_changes:
        item = change['item']
        delta = change['delta']
        
        # 检查账本
        ledger_balance = particle_ledger.get(item, 0)
        
        if delta < 0:  # 消耗
            if ledger_balance < abs(delta):
                issues.append({
                    "dimension": 5,
                    "severity": "critical",
                    "description": f"资源不足：{item}账本余额{ledger_balance}，本章消耗{abs(delta)}"
                })
        
        if delta > 0:  # 获得
            if not change.get('source'):
                issues.append({
                    "dimension": 5,
                    "severity": "warning",
                    "description": f"资源来源不明：{item}+{delta}"
                })
    
    return issues
```

### 维度 9: 信息越界

**检查项**:
- 角色是否知道不该知道的信息
- 信息边界是否被打破

**检测方法**:
```python
def check_information_boundary(chapter_content, character_matrix):
    issues = []
    
    for character in get_characters(chapter_content):
        # 获取角色信息边界
        known_info = character_matrix[character].get('known_info', [])
        unknown_info = character_matrix[character].get('unknown_info', [])
        
        # 提取角色行为和对话
        actions_and_dialogues = extract_character_content(chapter_content, character)
        
        for content in actions_and_dialogues:
            # 检查是否引用了未知信息
            for info in unknown_info:
                if info in content:
                    issues.append({
                        "dimension": 9,
                        "severity": "critical",
                        "description": f"{character}引用了不该知道的信息：{info}",
                        "suggestion": f"{character}不应该知道{info}，请修改"
                    })
    
    return issues
```

### 维度 10: 词汇疲劳

**检查项**:
- 高频词是否过多
- 题材疲劳词是否过量

**检测方法**:
```python
def check_word_fatigue(chapter_content, genre_profile):
    issues = []
    
    # 题材疲劳词
    fatigue_words = genre_profile.get('fatigueWords', [])
    
    for word in fatigue_words:
        count = chapter_content.count(word)
        if count > 1:
            issues.append({
                "dimension": 10,
                "severity": "warning",
                "description": f"疲劳词「{word}」出现{count}次",
                "suggestion": "建议替换为其他表达"
            })
    
    # 通用高频词
    word_freq = calculate_word_frequency(chapter_content)
    for word, freq in word_freq.items():
        if freq > len(chapter_content) / 500:  # 每500字出现超过1次
            if word not in ['的', '了', '是', '在', '有']:  # 排除常用虚词
                issues.append({
                    "dimension": 10,
                    "severity": "warning",
                    "description": f"「{word}」出现频率过高（{freq}次）"
                })
    
    return issues
```

### 维度 11: 利益链断裂

**检查项**:
- 角色行为是否有合理动机
- 决策是否符合利益

**检测方法**:
```python
def check_interest_chain(chapter_content, character_matrix):
    issues = []
    
    for character in get_characters(chapter_content):
        # 提取角色决策
        decisions = extract_decisions(chapter_content, character)
        
        for decision in decisions:
            # 分析动机
            motivation = analyze_motivation(decision, character_matrix[character])
            
            if not motivation['reasonable']:
                issues.append({
                    "dimension": 11,
                    "severity": "critical",
                    "description": f"{character}的决策「{decision}」缺乏合理动机",
                    "suggestion": f"建议增加{character}做出此决策的原因"
                })
    
    return issues
```

### 维度 13: 配角降智

**检查项**:
- 配角是否为了推剧情而变蠢
- 配角是否做出了不符合能力的错误

**检测方法**:
```python
def check_supporting_character_stupidity(chapter_content, character_matrix):
    issues = []
    
    for character in get_supporting_characters(chapter_content):
        char_profile = character_matrix[character]
        
        # 提取配角行为
        actions = extract_actions(chapter_content, character)
        
        for action in actions:
            # 检查是否"降智"
            if is_stupid_action(action, char_profile):
                # 检查是否服务于主角
                if serves_protagonist(action):
                    issues.append({
                        "dimension": 13,
                        "severity": "critical",
                        "description": f"配角{character}为推剧情降智：{action}",
                        "suggestion": "建议让配角保持正常智商，通过其他方式推进剧情"
                    })
    
    return issues
```

### 维度 20-23: AI 痕迹检测

**检查项**:
- 段落长度是否过于均匀
- AI 套话是否过多
- 转折是否公式化
- 是否使用列表式结构

**检测方法**:
```python
def check_ai_tells(chapter_content):
    issues = []
    
    # 20. 段落等长
    paragraphs = chapter_content.split('\n\n')
    lengths = [len(p) for p in paragraphs if len(p) > 50]
    if lengths and stdev(lengths) < 20:  # 标准差过小
        issues.append({
            "dimension": 20,
            "severity": "warning",
            "description": "段落长度过于均匀，疑似AI生成"
        })
    
    # 21. 套话密度
    ai_phrases = [
        '不得不承认', '毋庸置疑', '显而易见', '众所周知',
        '首先', '其次', '最后', '总而言之',
        '综上所述', '由此可见'
    ]
    phrase_count = sum(chapter_content.count(p) for p in ai_phrases)
    if phrase_count > 3:
        issues.append({
            "dimension": 21,
            "severity": "warning",
            "description": f"AI套话过多（{phrase_count}处）"
        })
    
    # 22. 公式化转折
    formulaic_transitions = [
        r'然而，[^。]{0,20}却[^。]',
        r'就在这时，',
        r'突然之间，'
    ]
    for pattern in formulaic_transitions:
        matches = re.findall(pattern, chapter_content)
        if len(matches) > 2:
            issues.append({
                "dimension": 22,
                "severity": "warning",
                "description": f"公式化转折过多：{pattern}"
            })
    
    # 23. 列表式结构
    list_patterns = [
        r'第一[，。].*第二[，。].*第三',
        r'其一[，。].*其二[，。].*其三',
        r'一方面[，。].*另一方面'
    ]
    for pattern in list_patterns:
        if re.search(pattern, chapter_content):
            issues.append({
                "dimension": 23,
                "severity": "warning",
                "description": "检测到列表式结构，不符合小说叙述"
            })
    
    return issues
```

### 维度 24: 支线停滞

**检查项**:
- 活跃支线是否推进
- 停滞的支线是否被激活

**检测方法**:
```python
def check_subplot_stagnation(chapter_content, subplot_board, chapter_n):
    issues = []
    
    for subplot in subplot_board['active']:
        last_update = subplot['last_update']
        stagnation = chapter_n - last_update
        
        # 检查是否停滞
        if stagnation > 10:
            # 检查本章是否涉及该支线
            if not involves_subplot(chapter_content, subplot):
                issues.append({
                    "dimension": 24,
                    "severity": "warning",
                    "description": f"支线「{subplot['name']}」已停滞{stagnation}章",
                    "suggestion": f"建议在第{chapter_n + 3}章前激活该支线"
                })
    
    return issues
```

---

## 审计结果处理

### 审计通过条件

```python
def is_audit_passed(audit_result):
    # 无 critical 问题
    if len(audit_result['critical']) > 0:
        return False
    
    # warning 问题 ≤ 5 个
    if len(audit_result['warning']) > 5:
        return False
    
    # 通过维度 ≥ 28/33
    if audit_result['passed_dimensions'] < 28:
        return False
    
    return True
```

### 自动修订触发

```python
def handle_audit_result(audit_result, chapter_content):
    if is_audit_passed(audit_result):
        return {
            "status": "passed",
            "content": chapter_content
        }
    
    # 有 critical 问题，触发修订
    if len(audit_result['critical']) > 0:
        # 确定修订模式
        mode = determine_revision_mode(audit_result)
        
        return {
            "status": "needs_revision",
            "mode": mode,
            "issues": audit_result['critical'],
            "suggestions": audit_result['suggestions']
        }
    
    # 只有 warning 问题
    return {
        "status": "passed_with_warnings",
        "warnings": audit_result['warning']
    }
```

### 修订模式选择

| 问题类型 | 修订模式 | 说明 |
|----------|----------|------|
| 1-3 个 critical | spot-fix | 定点修复问题句子 |
| 4-6 个 critical | polish | 润色整个段落 |
| >6 个 critical | rewrite | 重写整个章节 |
| AI 痕迹过多 | anti-detect | 去AI味改写 |
| 大纲偏离 | rework | 调整结构 |

---

## 题材维度配置

### 仙侠题材

```python
XIANXIA_DIMENSIONS = [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26,27]
```

### 玄幻题材

```python
XUANHUAN_DIMENSIONS = [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26,27]
```

### 都市题材

```python
URBAN_DIMENSIONS = [1,2,3,6,7,8,9,10,11,13,14,15,16,17,19,24,25,26,27]
```

### 番外/同人

```python
FANFIC_DIMENSIONS = [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26,27,28,29,30,31,32,33]
```

---

## 审计流程

```
1. 接收审计任务
   ↓
2. 读取章节内容 + 7个真相文件
   ↓
3. 确定题材 → 选择审计维度
   ↓
4. 逐维度执行审计
   ├─ 维度 1-7: 基础一致性
   ├─ 维度 8-14: 内容质量
   ├─ 维度 15-19: 叙事技巧
   ├─ 维度 20-23: AI痕迹
   ├─ 维度 24-26: 支线弧线
   ├─ 维度 27: 敏感内容
   └─ 维度 28-33: 番外专属 (可选)
   ↓
5. 生成审计报告
   ↓
6. 判断是否通过
   ├─ 通过 → 返回结果
   └─ 不通过 → 触发修订
```

---

## 注意事项

### 审计标准

- **A级**: 无 critical，warning ≤ 2，通过维度 ≥ 31/33
- **B级**: 无 critical，warning ≤ 5，通过维度 ≥ 28/33
- **C级**: critical ≤ 2 或 warning > 5
- **D级**: critical > 2，需要重写

### 重点审计维度

对于所有题材，以下维度必须通过：
- 1: OOC检查
- 3: 设定冲突
- 9: 信息越界
- 11: 利益链断裂
- 13: 配角降智
- 27: 敏感词检查

### 输出建议

- 问题要具体（指出位置）
- 建议要可操作（给出改法）
- 语气要建设性
- 区分 critical 和 warning