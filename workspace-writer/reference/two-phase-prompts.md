# 两阶段写作 Prompt 详细实现

## Phase 1: 创意写作

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

## Phase 2: 状态结算

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
