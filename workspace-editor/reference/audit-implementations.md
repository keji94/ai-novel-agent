# 审计维度详细实现

> 本文件包含 33 维度审计中各维度的详细检测方法（Python 伪代码）。

---

## 维度 1: OOC检查

**检查项**:
- 角色行为是否符合已建立的性格
- 角色说话风格是否一致
- 角色决策是否合理（基于动机）

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

## 维度 2: 时间线检查

**检查项**:
- 时间是否倒流（事件顺序错误）
- 时间跨度是否合理
- 季节/天气是否连续

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

## 维度 3: 设定冲突

**检查项**:
- 世界观设定是否一致
- 力量体系是否一致
- 地理设定是否一致

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

## 维度 5: 数值检查

**检查项**:
- 资源数量是否一致
- 资源变化是否在账本中
- 是否有凭空出现的资源

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

## 维度 9: 信息越界

**检查项**:
- 角色是否知道不该知道的信息
- 信息边界是否被打破

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

## 维度 10: 词汇疲劳

**检查项**:
- 高频词是否过多
- 题材疲劳词是否过量

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

## 维度 11: 利益链断裂

**检查项**:
- 角色行为是否有合理动机
- 决策是否符合利益

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

## 维度 13: 配角降智

**检查项**:
- 配角是否为了推剧情而变蠢
- 配角是否做出了不符合能力的错误

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

## 维度 20-23: AI 痕迹检测

**检查项**:
- 段落长度是否过于均匀
- AI 套话是否过多
- 转折是否公式化
- 是否使用列表式结构

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

## 维度 24: 支线停滞

**检查项**:
- 活跃支线是否推进
- 停滞的支线是否被激活

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
