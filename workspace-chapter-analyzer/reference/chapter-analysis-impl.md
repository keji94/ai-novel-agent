# analyze_chapter 详细实现

> 主文件: TOOLS.md 工具 5

## 5.1 提取角色

```python
def extract_characters(chapter_content, known_characters=None):
    characters = []

    # 1. 从已知角色中匹配
    if known_characters:
        for char in known_characters:
            if char['name'] in chapter_content:
                characters.append(char['name'])

    # 2. 从对话中提取
    dialogues = re.findall(r'「([^」]+)」|"([^"]+)"', chapter_content)
    for d in dialogues:
        # 分析说话人
        speaker = extract_speaker(chapter_content, d)
        if speaker and speaker not in characters:
            characters.append(speaker)

    # 3. 从称呼中提取
    titles = ['师兄', '师姐', '师妹', '师弟', '师父', '前辈', '晚辈']
    for title in titles:
        pattern = rf'([^\s，。！？]+){title}'
        matches = re.findall(pattern, chapter_content)
        characters.extend(matches)

    return list(set(characters))
```

## 5.2 提取资源变化

```python
def extract_resource_changes(chapter_content, character):
    changes = []

    # 物品获得模式
    gain_patterns = [
        r'获得([^\s，。]+)',
        r'得到([^\s，。]+)',
        r'取出([^\s，。]+)',
        r'收到([^\s，。]+)'
    ]

    # 物品消耗模式
    consume_patterns = [
        r'用(了|掉)([^\s，。]+)',
        r'消耗(了)?([^\s，。]+)',
        r'失去(了)?([^\s，。]+)'
    ]

    for pattern in gain_patterns:
        matches = re.findall(pattern, chapter_content)
        for m in matches:
            changes.append({
                "type": "gain",
                "item": m,
                "source": "章节内容"
            })

    for pattern in consume_patterns:
        matches = re.findall(pattern, chapter_content)
        for m in matches:
            changes.append({
                "type": "consume",
                "item": m[1] if isinstance(m, tuple) else m,
                "reason": "章节内容"
            })

    return changes
```

## 5.3 提取伏笔

```python
def extract_foreshadowing(chapter_content):
    foreshadowing = []

    # 伏笔埋设信号词
    plant_signals = [
        '心中隐隐觉得',
        '似乎有些不对',
        '却没注意到',
        '并未察觉',
        '不知为何'
    ]

    # 伏笔回收信号词
    resolve_signals = [
        '原来',
        '难怪',
        '终于明白',
        '真相大白',
        '原来如此'
    ]

    for signal in plant_signals:
        if signal in chapter_content:
            # 提取伏笔内容
            context = extract_context(chapter_content, signal)
            foreshadowing.append({
                "status": "planted",
                "signal": signal,
                "context": context
            })

    for signal in resolve_signals:
        if signal in chapter_content:
            context = extract_context(chapter_content, signal)
            foreshadowing.append({
                "status": "resolved",
                "signal": signal,
                "context": context
            })

    return foreshadowing
```

## 5.4 提取情感变化

```python
def extract_emotional_changes(chapter_content, character):
    emotions = []

    # 情绪词库
    emotion_words = {
        "愤怒": ["怒", "气", "愤", "火"],
        "喜悦": ["喜", "乐", "高兴", "开心"],
        "悲伤": ["悲", "伤", "痛", "哭"],
        "恐惧": ["惧", "怕", "恐", "惊"],
        "惊讶": ["惊", "愣", "怔", "呆"],
        "期待": ["期待", "盼望", "希望"]
    }

    # 查找角色的情绪表达
    char_content = extract_character_content(chapter_content, character)

    for emotion, words in emotion_words.items():
        for word in words:
            if word in char_content:
                context = extract_context(char_content, word)
                emotions.append({
                    "emotion": emotion,
                    "trigger_word": word,
                    "context": context
                })

    return emotions
```
