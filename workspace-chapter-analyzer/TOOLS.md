# ChapterAnalyzer 工具手册

本文档定义 ChapterAnalyzer (章节分析器) 可使用的工具。

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取源文件（小说正文）。

**示例**:
```json
// 单文件模式
read({"path": "./source/我的小说.txt"})

// 目录模式
read({"path": "./source/chapters/chapter_001.md"})
```

### 2. write - 写入真相文件

**用途**: 创建 7 个真相文件。

**示例**:
```json
write({
  "path": "./novels/仙道长生/context/tracking/current_state.md",
  "content": "# 世界状态\n\n..."
})
```

### 3. exec - 执行命令

**用途**: 列出目录、拆分文件等。

**示例**:
```json
// 列出章节目录
exec({"command": "ls -1 ./source/chapters/*.md"})

// 创建目录
exec({"command": "mkdir -p ./novels/仙道长生/context/tracking"})
```

---

## 导入工具

### 4. split_chapters - 拆分章节

**用途**: 从单文件中拆分出各章节。

**拆分规则**:

| 模式 | 正则 | 示例 |
|------|------|------|
| 中文默认 | `第[零一二三四五六七八九十百千]+章` | 第一章、第十零章 |
| 中文数字 | `第\d+章` | 第1章、第100章 |
| 英文默认 | `Chapter\s+\d+` | Chapter 1, Chapter 100 |
| 自定义 | 用户提供正则 | 用户指定 |

**实现**:
```python
def split_chapters(content, mode="chinese"):
    patterns = {
        "chinese": r'第[零一二三四五六七八九十百千]+章[^\n]*',
        "chinese_num": r'第\d+章[^\n]*',
        "english": r'Chapter\s+\d+[^\n]*',
        "custom": None  # 用户提供
    }
    
    pattern = patterns.get(mode, mode)
    
    # 查找所有章节标题
    matches = list(re.finditer(pattern, content))
    
    chapters = []
    for i, match in enumerate(matches):
        start = match.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        
        chapter_title = match.group().strip()
        chapter_content = content[start:end].strip()
        
        chapters.append({
            "number": i + 1,
            "title": chapter_title,
            "content": chapter_content
        })
    
    return chapters
```

**调用示例**:
```json
// Step 1: 读取文件
content = read({"path": "./source/novel.txt"})

// Step 2: 拆分章节
chapters = split_chapters(content, "chinese")

// Step 3: 保存各章节
for chapter in chapters:
    write({
        "path": f"./novels/仙道长生/chapters/chapter_{chapter['number']:03d}.md",
        "content": chapter['content']
    })
```

---

### 5. analyze_chapter - 分析单章节

**用途**: 从单章节中提取信息。

**分析维度**:

#### 5.1 提取角色

```python
def extract_characters(chapter_content, known_characters=None):
    characters = []
    
    # 1. 从已知角色中匹配
    if known_characters:
        for char in known_characters:
            if char['name'] in chapter_content:
                characters.append(char['name'])
    
    # 2. 从对话中提取
    dialogues = re.findall(r'「([^」]+)」|\"([^\"]+)\"', chapter_content)
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

#### 5.2 提取资源变化

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

#### 5.3 提取伏笔

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

#### 5.4 提取情感变化

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

---

### 6. consolidate_info - 信息整合

**用途**: 合并多章节提取的信息，解决冲突。

**整合策略**:

```python
def consolidate_info(all_chapters_info):
    consolidated = {
        "characters": {},
        "resources": {},
        "foreshadowing": {},
        "emotions": {},
        "subplots": {}
    }
    
    # 1. 按时间顺序遍历章节
    for chapter_num, info in sorted(all_chapters_info.items()):
        # 2. 更新角色状态（后出现的覆盖前面的）
        for char in info['characters']:
            if char['name'] not in consolidated['characters']:
                consolidated['characters'][char['name']] = {
                    "first_appearance": chapter_num,
                    "states": []
                }
            consolidated['characters'][char['name']]['states'].append({
                "chapter": chapter_num,
                "state": char['state']
            })
        
        # 3. 累积资源变化
        for change in info['resources']:
            key = change['item']
            if key not in consolidated['resources']:
                consolidated['resources'][key] = []
            consolidated['resources'][key].append({
                "chapter": chapter_num,
                "change": change
            })
        
        # 4. 追踪伏笔状态
        for f in info['foreshadowing']:
            if f['status'] == 'planted':
                consolidated['foreshadowing'][f['context']] = {
                    "planted_chapter": chapter_num,
                    "status": "pending"
                }
            elif f['status'] == 'resolved':
                # 查找对应的已埋设伏笔
                for key in consolidated['foreshadowing']:
                    if is_related(f['context'], key):
                        consolidated['foreshadowing'][key]['resolved_chapter'] = chapter_num
                        consolidated['foreshadowing'][key]['status'] = "resolved"
    
    return consolidated
```

---

### 7. generate_truth_files - 生成真相文件

**用途**: 从整合后的信息生成 7 个真相文件。

**生成流程**:

```python
async def generate_truth_files(project_name, consolidated_info):
    base = f"./novels/{project_name}/context"
    
    # 确保目录存在
    await mkdir(f"{base}/tracking", recursive=True)
    await mkdir(f"{base}/summaries", recursive=True)
    
    # 1. 生成 current_state.md
    current_state = build_current_state(consolidated_info)
    await write(f"{base}/tracking/current_state.md", current_state)
    
    # 2. 生成 particle_ledger.md
    particle_ledger = build_particle_ledger(consolidated_info['resources'])
    await write(f"{base}/tracking/particle_ledger.md", particle_ledger)
    
    # 3. 生成 pending_hooks.md
    pending_hooks = build_pending_hooks(consolidated_info['foreshadowing'])
    await write(f"{base}/tracking/foreshadowing.json", pending_hooks)
    
    # 4. 生成 chapter_summaries.md
    chapter_summaries = build_chapter_summaries(consolidated_info)
    await write(f"{base}/summaries/chapter_summaries.md", chapter_summaries)
    
    # 5. 生成 subplot_board.md
    subplot_board = build_subplot_board(consolidated_info['subplots'])
    await write(f"{base}/tracking/subplot_board.md", subplot_board)
    
    # 6. 生成 emotional_arcs.md
    emotional_arcs = build_emotional_arcs(consolidated_info['emotions'])
    await write(f"{base}/tracking/emotional_arcs.md", emotional_arcs)
    
    # 7. 生成 character_matrix.md
    character_matrix = build_character_matrix(consolidated_info['characters'])
    await write(f"{base}/tracking/character_states.json", character_matrix)
```

---

## 导入流程示例

### 完整导入命令

```json
// 假设用户请求: "导入 ./source/我的小说.txt"

// Step 1: 读取源文件
content = read({"path": "./source/我的小说.txt"})

// Step 2: 创建项目
project_name = extract_project_name(content)  // 从内容中提取书名
exec({"command": f"mkdir -p ./novels/{project_name}/{{chapters,context}}"})

// Step 3: 拆分章节
chapters = split_chapters(content, "chinese")

// Step 4: 保存章节
for chapter in chapters:
    write({
        "path": f"./novels/{project_name}/chapters/chapter_{chapter['number']:03d}.md",
        "content": chapter['content']
    })

// Step 5: 逐章分析
all_info = {}
for chapter in chapters:
    info = analyze_chapter(chapter['content'], chapter['number'])
    all_info[chapter['number']] = info

// Step 6: 信息整合
consolidated = consolidate_info(all_info)

// Step 7: 生成真相文件
generate_truth_files(project_name, consolidated)

// Step 8: 生成导入报告
report = generate_import_report(chapters, consolidated)
write({"path": f"./novels/{project_name}/import_report.md", "content": report})
```

---

## 断点续导

**用途**: 导入中断后，从指定章节继续。

```json
// 用户请求: "继续导入，从第50章开始"

// Step 1: 读取已导入的章节
existing_chapters = exec({"command": f"ls ./novels/{project}/chapters/*.md"})

// Step 2: 确定续导起点
resume_from = 50

// Step 3: 只处理后续章节
for chapter in chapters[resume_from-1:]:
    // ... 分析和保存
```

---

## 输出格式

### current_state.md 模板

```markdown
# 世界状态

> 最后更新: 第{N}章

## 当前地点

### 主要场景
- {地点1}: {描述}
- {地点2}: {描述}

## 势力格局

### 主要势力
| 势力 | 类型 | 实力 | 关系 |
|------|------|------|------|
| 青云宗 | 宗门 | 强 | 友好 |
| 魔教 | 门派 | 极强 | 敌对 |

## 已知信息

### 主角已知
- {信息1}
- {信息2}

## 时间线

- 第1章: {事件}
- 第5章: {事件}
- 第10章: {事件}
```

### character_matrix.md 模板

```json
{
  "characters": {
    "林风": {
      "name": "林风",
      "first_appearance": 1,
      "last_appearance": 157,
      "current_state": {
        "cultivation": "筑基初期",
        "location": "青云宗内门",
        "equipment": ["玄铁剑", "储物袋(中品)"],
        "skills": ["青云剑诀(圆满)"],
        "resources": ["下品灵石 x500"]
      },
      "personality": ["谨慎", "果断", "重情义"],
      "speaking_style": "简洁直接",
      "known_info": ["宗门秘辛", "师姐身份"],
      "unknown_info": ["师父真实身份", "系统来源"],
      "relationships": {
        "苏婉": "相识→好友",
        "赵天": "仇敌"
      },
      "emotional_arc": {
        "start": "压抑、渴望变强",
        "current": "自信、有责任感",
        "key_events": [
          {"chapter": 1, "event": "觉醒签到系统", "emotion": "惊喜→期待"},
          {"chapter": 10, "event": "突破筑基", "emotion": "焦虑→喜悦"}
        ]
      }
    }
  }
}
```

---

## 注意事项

### 必须做的事
- 按时间顺序分析
- 记录信息来源章节
- 标注不确定推断
- 解决前后冲突

### 禁止做的事
- 凭空臆测未出现内容
- 忽略时间线矛盾
- 遗漏重要角色
- 打乱章节顺序