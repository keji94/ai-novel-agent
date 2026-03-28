# Writer 工具手册 v2.0

> **重大升级**: 实现两阶段写作 + 写后验证器 + 7个真相文件管理

---

## 核心能力：两阶段写作架构

### 为什么需要两阶段？

**问题**:
- 单阶段写作时，创意写作（temp 0.7）和状态结算（temp 0.3）混在一起
- 创意要求高温度，但状态追踪要求精确
- 导致：状态更新不准确，长篇一致性差

**解决**:
```
Phase 1: 创意写作 (temperature: 0.7)
  - 只输出章节正文
  - 创造性表达，不受约束
  
Phase 2: 状态结算 (temperature: 0.3)
  - 分析正文，更新所有真相文件
  - 精确追踪，确保一致性
```

---

## 两阶段写作流程

### Phase 1: 创意写作

**输入**:
- 7个真相文件（只读）
- 章节大纲
- 创作指导（可选）
- 风格指南（可选）

**输出**:
- 章节标题
- 章节正文（2000-3000字）

**Prompt 结构**:
```
## 系统提示
你是专业的网文写手，负责创作章节正文。

## 输入信息
- 世界观设定: {story_bible}
- 角色设定: {character_matrix}
- 当前状态: {current_state}
- 资源账本: {particle_ledger}
- 未回收伏笔: {pending_hooks}
- 章节大纲: {outline}
- 风格指南: {style_guide}

## 创作规则
[题材专属规则 + 通用创作规则 + 去AI味规则]

## 输出要求
只输出章节标题和正文，不要包含其他内容。

格式:
# 第X章 章节名

[正文内容，2000-3000字]
```

**调用示例**:
```json
sessions_spawn({
  "agentId": "writer",
  "task": "Phase 1: 创意写作\n章节: 第{N}章\n大纲: {大纲内容}\n指导: {创作指导}",
  "label": "创意写作-第{N}章",
  "model": {
    "temperature": 0.7,
    "max_tokens": 8192
  }
})
```

---

### Phase 2: 状态结算

**输入**:
- Phase 1 输出的章节正文
- 当前 7 个真相文件

**输出**:
- 更新后的 `current_state.md`
- 更新后的 `particle_ledger.md`
- 更新后的 `pending_hooks.md`
- 更新后的 `chapter_summaries.md`
- 更新后的 `subplot_board.md`
- 更新后的 `emotional_arcs.md`
- 更新后的 `character_matrix.md`

**Prompt 结构**:
```
## 系统提示
你是状态追踪专家，负责从章节正文中提取状态变化，更新真相文件。

## 输入
- 章节正文: {chapter_content}
- 当前真相文件: {truth_files}

## 任务
分析章节正文，识别以下变化：
1. 世界状态变化: 地点转移、势力变化、重要事件
2. 资源变化: 物品获得/消耗、金钱变化
3. 伏笔动态: 新埋设的伏笔、回收的伏笔
4. 角色状态: 修为变化、装备变化、关系变化
5. 情感弧线: 角色情绪变化、成长节点
6. 支线进度: 支线故事推进

## 输出格式
分别输出每个真相文件的更新内容：

### current_state.md 更新
[变化内容]

### particle_ledger.md 更新
[变化内容，格式: +物品 x数量 (来源) / -物品 x数量 (消耗)]

### pending_hooks.md 更新
[新伏笔 / 已回收伏笔]

### chapter_summaries.md 更新
## 第N章 摘要
**核心事件**: ...
**出场人物**: ...
**地点**: ...
**伏笔**: ...
**角色变化**: ...

### emotional_arcs.md 更新
[角色情绪变化]

### subplot_board.md 更新
[支线进度更新]

### character_matrix.md 更新
[角色关系/信息边界变化]
```

**调用示例**:
```json
sessions_spawn({
  "agentId": "writer",
  "task": "Phase 2: 状态结算\n章节正文: {phase1_output}\n\n请分析并更新所有真相文件。",
  "label": "状态结算-第{N}章",
  "model": {
    "temperature": 0.3,
    "max_tokens": 4096
  }
})
```

---

## 写后验证器

**用途**: 11 条确定性规则，零 LLM 成本，每章写完立刻触发。

### 验证规则

| 规则 | 级别 | 说明 |
|------|------|------|
| **禁止句式** | error | 「不是……而是……」 |
| **禁止破折号** | error | 「——」 |
| **转折词密度** | warning | 仿佛/忽然/竟然等，每 3000 字 ≤ 1 次 |
| **高疲劳词** | warning | 题材疲劳词单章每词 ≤ 1 次 |
| **元叙事** | error | 编剧旁白式表述 |
| **报告术语** | warning | 分析框架术语不入正文 |
| **作者说教** | warning | 显然/不言而喻等 |
| **集体反应** | warning | 「全场震惊」类套话 |
| **连续了字** | warning | ≥ 6 句连续含「了」 |
| **段落过长** | warning | ≥ 2 个段落超 300 字 |
| **本书禁忌** | error | book_rules.md 中的禁令 |

### 实现代码

```python
def validate_post_write(content, book_rules, genre_profile):
    violations = []
    
    # 1. 禁止句式检测
    if re.search(r'不是[^。]{0,10}而是', content):
        violations.append({
            "rule": "禁止句式",
            "severity": "error",
            "message": "检测到「不是...而是」句式"
        })
    
    # 2. 禁止破折号
    if '——' in content:
        violations.append({
            "rule": "禁止破折号",
            "severity": "error",
            "message": "检测到破折号「——」"
        })
    
    # 3. 转折词密度
    transition_words = ['仿佛', '忽然', '竟然', '居然', '不由得', '不禁']
    for word in transition_words:
        count = content.count(word)
        if count > len(content) / 3000:
            violations.append({
                "rule": "转折词密度",
                "severity": "warning",
                "message": f"「{word}」出现{count}次，超过阈值"
            })
    
    # 4. 高疲劳词（题材相关）
    fatigue_words = genre_profile.get('fatigueWords', [])
    for word in fatigue_words:
        if content.count(word) > 1:
            violations.append({
                "rule": "高疲劳词",
                "severity": "warning",
                "message": f"疲劳词「{word}」出现{content.count(word)}次"
            })
    
    # 5. 元叙事检测
    meta_patterns = [
        r'作为[^，]{0,5}，',
        r'要知道，',
        r'不得不说，'
    ]
    for pattern in meta_patterns:
        if re.search(pattern, content):
            violations.append({
                "rule": "元叙事",
                "severity": "error",
                "message": f"检测到元叙事表达"
            })
    
    # 6. 作者说教
    preach_words = ['显然', '不言而喻', '众所周知', '毋庸置疑']
    for word in preach_words:
        if word in content:
            violations.append({
                "rule": "作者说教",
                "severity": "warning",
                "message": f"检测到说教词「{word}」"
            })
    
    # 7. 集体反应套话
    collective_patterns = [
        r'全场[^，]{0,5}震惊',
        r'所有人[^，]{0,5}倒吸.*气',
        r'众人[^，]{0,5}瞳孔.*缩'
    ]
    for pattern in collective_patterns:
        if re.search(pattern, content):
            violations.append({
                "rule": "集体反应",
                "severity": "warning",
                "message": "检测到集体反应套话"
            })
    
    # 8. 连续了字
    sentences = re.split(r'[。！？]', content)
    consecutive_le = 0
    for sentence in sentences:
        if '了' in sentence:
            consecutive_le += 1
            if consecutive_le >= 6:
                violations.append({
                    "rule": "连续了字",
                    "severity": "warning",
                    "message": f"连续{consecutive_le}句含「了」"
                })
                break
        else:
            consecutive_le = 0
    
    # 9. 段落过长
    paragraphs = content.split('\n\n')
    long_paragraphs = [p for p in paragraphs if len(p) > 300]
    if len(long_paragraphs) >= 2:
        violations.append({
            "rule": "段落过长",
            "severity": "warning",
            "message": f"有{len(long_paragraphs)}个段落超过300字"
        })
    
    # 10. 本书禁忌（从 book_rules 读取）
    if book_rules and 'forbiddenWords' in book_rules:
        for word in book_rules['forbiddenWords']:
            if word in content:
                violations.append({
                    "rule": "本书禁忌",
                    "severity": "error",
                    "message": f"检测到禁忌词「{word}」"
                })
    
    return {
        "errors": [v for v in violations if v["severity"] == "error"],
        "warnings": [v for v in violations if v["severity"] == "warning"]
    }
```

### 自动修复

当验证器发现 **error** 级别违规时：
```python
if len(violations["errors"]) > 0:
    # 自动触发 spot-fix 模式
    fixed_content = spot_fix(content, violations["errors"])
    return fixed_content
```

---

## 7 个真相文件管理

### 文件列表

| 文件 | 路径 | 用途 |
|------|------|------|
| `current_state.md` | `context/tracking/current_state.md` | 世界状态：地点、势力、已知信息 |
| `particle_ledger.md` | `context/tracking/particle_ledger.md` | 资源账本：物品、金钱、修炼资源 |
| `pending_hooks.md` | `context/tracking/foreshadowing.json` | 伏笔钩子：未闭合伏笔 |
| `chapter_summaries.md` | `context/summaries/chapter_summaries.md` | 章节摘要 |
| `subplot_board.md` | `context/tracking/subplot_board.md` | 支线进度板 |
| `emotional_arcs.md` | `context/tracking/emotional_arcs.md` | 情感弧线 |
| `character_matrix.md` | `context/tracking/character_states.json` | 角色矩阵：关系、信息边界 |

### 读取顺序

```python
async def read_truth_files(project_name):
    base = f"./novels/{project_name}/context"
    
    truth_files = {}
    
    # 并行读取
    truth_files['current_state'] = await read(f"{base}/tracking/current_state.md")
    truth_files['particle_ledger'] = await read(f"{base}/tracking/particle_ledger.md")
    truth_files['pending_hooks'] = await read(f"{base}/tracking/foreshadowing.json")
    truth_files['chapter_summaries'] = await read(f"{base}/summaries/chapter_summaries.md")
    truth_files['subplot_board'] = await read(f"{base}/tracking/subplot_board.md")
    truth_files['emotional_arcs'] = await read(f"{base}/tracking/emotional_arcs.md")
    truth_files['character_matrix'] = await read(f"{base}/tracking/character_states.json")
    
    return truth_files
```

### 写入顺序

Phase 2 结算时，按以下顺序更新：
1. `current_state.md` - 世界状态
2. `particle_ledger.md` - 资源账本
3. `pending_hooks` - 伏笔
4. `character_matrix` - 角色
5. `chapter_summaries` - 摘要
6. `emotional_arcs` - 情感
7. `subplot_board` - 支线

---

## 完整写作流程（新版）

```
1. 接收写作任务
   ↓
2. 读取所有真相文件
   ↓
3. Phase 1: 创意写作 (temp 0.7)
   ├─ 读取上下文
   ├─ 生成章节正文
   └─ 输出标题+正文
   ↓
4. 写后验证器
   ├─ 11 条规则检测
   ├─ 发现 error → 自动 spot-fix
   └─ 发现 warning → 记录日志
   ↓
5. Phase 2: 状态结算 (temp 0.3)
   ├─ 分析章节正文
   ├─ 提取状态变化
   └─ 更新所有真相文件
   ↓
6. 写入章节文件
   ↓
7. 返回结果
   ├─ 章节内容
   ├─ 验证结果
   ├─ 状态更新摘要
   └─ Token 用量
```

---

## AI 痕迹检测与去除

### 内置去 AI 味规则（Prompt 层）

```
## 去AI味规则

以下表达禁用或限制使用：

### 完全禁用
- 「不是...而是...」
- 「——」破折号
- 「作为...，...」元叙事
- 「显然」「不言而喻」说教词

### 限制使用（每3000字≤1次）
- 仿佛、宛如、犹如
- 忽然、突然、竟然、居然
- 不由得、不禁、忍不住
- 「全场震惊」类套话

### 词汇疲劳检测
题材疲劳词列表：
[仙侠: 冷笑、蝼蚁、倒吸凉气、瞳孔骤缩、天道、大道、因果、气运]
[玄幻: 妖孽、逆天、震撼、恐怖、惊人、无法想象]

### 句式疲劳检测
- 连续 ≥6 句含「了」
- 连续使用相同句式开头
- 段落长度过于均匀

### 避免AI生成特征
- 不要使用列表式结构
- 不要使用「首先...其次...最后」
- 不要使用「总结来说」
- 避免过度总结和归纳
```

### AI 痕迹检测维度

```python
AI_TELL_DIMENSIONS = [
    "词汇疲劳",
    "套话密度",
    "公式化转折",
    "列表式结构",
    "段落等长",
    "元叙事检测",
    "作者说教"
]
```

---

## 题材专属规则

### 仙侠题材

```yaml
---
name: 仙侠
fatigueWords:
  - 冷笑
  - 蝼蚁
  - 倒吸凉气
  - 瞳孔骤缩
  - 天道
  - 大道
  - 因果
  - 气运
  - 仿佛
  - 不禁
  - 宛如
  - 竟然
auditDimensions: [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26]
---

## 题材禁忌
- 主角为推剧情突然仁慈、犯蠢
- 修为无铺垫跳跃式突破
- 法宝凭空出现解决危机
- 天道规则前后矛盾
- 用"大道无形"跳过修炼过程
- 同质资源不写衰减

## 修炼规则
- 境界突破必须有积累过程
- 同质资源重复炼化必须写明衰减
- 金手指四维约束：上限/代价/条件/路径
```

### 玄幻题材

```yaml
---
name: 玄幻
fatigueWords:
  - 妖孽
  - 逆天
  - 震撼
  - 恐怖
  - 惊人
  - 无法想象
  - 不可思议
auditDimensions: [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26]
---

## 题材禁忌
- 主角光环过重
- 配角工具人化
- 战力崩坏
- 无脑打脸
```

---

## Token 用量统计

每次写作后，返回 Token 用量：

```json
{
  "phase1": {
    "promptTokens": 2500,
    "completionTokens": 3000,
    "totalTokens": 5500
  },
  "phase2": {
    "promptTokens": 1500,
    "completionTokens": 500,
    "totalTokens": 2000
  },
  "total": {
    "promptTokens": 4000,
    "completionTokens": 3500,
    "totalTokens": 7500
  }
}
```

---

## 真相文件版本控制

### 为什么需要版本控制？

Phase 2 状态结算会更新 7 个真相文件。如果结算结果有误（如遗漏角色状态变化、错误记录资源消耗），会影响后续所有章节的一致性。版本控制允许回退到上一个正确状态。

### 快照机制

**创建时机**: Phase 2 结算开始之前

**实现**:
```json
exec({
  "command": "mkdir -p ./novels/{project}/context/tracking/.snapshots/chapter_{N}_pre && cp ./novels/{project}/context/tracking/*.md ./novels/{project}/context/tracking/*.json ./novels/{project}/context/tracking/.snapshots/chapter_{N}_pre/"
})
```

**快照目录**:
```
./novels/{project}/context/tracking/.snapshots/
├── chapter_10_pre/    # 第 10 章结算前快照
├── chapter_11_pre/    # 第 11 章结算前快照
├── ...
```

### 快照保留策略

- 保留最近 5 个章节的快照
- 超过 5 个时自动删除最旧的快照
- 删除命令: `rm -rf ./novels/{project}/context/tracking/.snapshots/chapter_{N-5}_pre/`

### 回滚流程

当发现真相文件结算有误时：

```
1. 确认需要回退到的版本（通常是上一个章节的快照）
2. 将快照内容复制回 tracking 目录
   exec({
     "command": "cp ./novels/{project}/context/tracking/.snapshots/chapter_{N}_pre/* ./novels/{project}/context/tracking/"
   })
3. 重新执行 Phase 2 状态结算
4. 验证新的结算结果
```

### 注意事项

- 快照是目录级别的完整复制，不是增量
- 回滚后必须重新结算当前章节，否则状态不连续
- 如果连续多章结算都有问题，可能需要回退到更早的快照

---

## 注意事项

### 必须做的事
- **写作前**: 读取所有 7 个真相文件
- **Phase 1**: 只输出正文，不输出其他内容
- **Phase 2**: 必须更新所有变化的真相文件
- **写后**: 运行验证器，error 级别必须修复

### 禁止做的事
- 跳过 Phase 2 状态结算
- 忽略验证器的 error 级别违规
- 不更新真相文件就结束
- 使用禁用的表达方式