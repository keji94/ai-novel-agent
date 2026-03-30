# 两阶段写作 Prompt 详细实现

## Phase 0: 上下文组装（新增）

> **渐进式上下文加载**：不是把所有文件塞进去，而是按需分层加载，控制在7K字以内。

### 加载流程

```
步骤1: 读取项目索引
  read(context/index.md) → 确定项目名、当前进度、文件位置

步骤2: 第一层加载（必选，~2K字）
  read(context/state/characters.json) → 提取本章涉及角色的状态
  read(context/state/foreshadowing.json) → 提取 pending 伏笔
  read(context/summaries/recent.md) → 最近10章摘要

步骤3: 第二层加载（条件，~3K字）
  根据大纲判断需要加载的内容:
  - 涉及某角色详细设定 → read(outline/角色设定.md) 中对应部分
  - 涉及某伏笔原文 → 从章节文件中提取相关段落
  - read(context/tracking/strand_balance.json) → 读取 alerts
  - read(context/tracking/readability.json) → 读取追读力趋势

步骤4: 第三层加载（按需，~2K字）
  - 写战斗场景 → read(context/descriptions/scenes_index.md) 中战斗部分
  - 涉及复杂关系 → read(context/tracking/character_relations.json)
  - 跨卷内容 → read(context/summaries/vol_X_summary.md)

步骤5: 组装
  将所有加载内容按优先级组装成上下文 prompt
  总量控制在 7K 字以内
```

### 上下文 Prompt 结构

```
## 写作上下文 - 第{N}章

### 核心状态（第一层）
**本章涉及角色**:
{从 characters.json 提取相关角色状态}

**待回收伏笔**:
{从 foreshadowing.json 提取 pending 条目}

**最近剧情**:
{recent.md 最近10章摘要}

### 创作指导（第二层）
**节奏提示**:
{strand_balance.json 中的 alerts}
{readability.json 中的趋势}

**相关设定**:
{根据大纲需要加载的设定文件片段}

### 参考素材（第三层）
**防重复提醒**:
{scenes_index.md 中相关的已描写场景}

{如有其他按需加载的内容}
```

---

## Phase 1: 创意写作

**输入**:
- Phase 0 组装的上下文（渐进式加载，~7K字）
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

## 写作上下文
{phase0_output}

## 章节大纲
{outline}

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
  "task": "Phase 0+1: 上下文组装+创意写作\n章节: 第{N}章\n大纲: {大纲内容}\n指导: {创作指导}",
  "label": "创意写作-第{N}章",
  "model": {
    "temperature": 0.7,
    "max_tokens": 8192
  }
})
```

---

## Phase 2: 状态结算（增强版）

**输入**:
- Phase 1 输出的章节正文
- 当前上下文文件（characters.json, foreshadowing.json 等）
- scenes_index.md（防重复检查）

**输出**: 更新以下文件（共11个）

### 状态文件更新（7个）

| 文件 | 路径 | 更新内容 |
|------|------|---------|
| characters.json | `context/state/characters.json` | 角色状态变化 |
| foreshadowing.json | `context/state/foreshadowing.json` | 新增/回收伏笔 |
| world_state.json | `context/state/world_state.json` | 世界状态变化 |
| timeline.json | `context/state/timeline.json` | 时间线推进 |
| recent.md | `context/summaries/recent.md` | 追加本章摘要 |
| particle_ledger.md | `context/tracking/particle_ledger.md` | 资源变化 |
| character_matrix.md | `context/tracking/character_states.json` | 角色关系 |

### 追踪文件更新（4个，新增）

| 文件 | 路径 | 更新内容 |
|------|------|---------|
| strand_balance.json | `context/tracking/strand_balance.json` | 本章Strand类型+节奏统计 |
| readability.json | `context/tracking/readability.json` | Hook强度+爽点+微兑现 |
| character_relations.json | `context/tracking/character_relations.json` | 关系变化 |
| scenes_index.md | `context/descriptions/scenes_index.md` | 新描写的场景 |

**Prompt 结构**:
```
## 系统提示
你是状态追踪专家，负责从章节正文中提取状态变化，更新上下文文件。

## 输入
- 章节正文: {chapter_content}
- 当前上下文文件: {context_files}

## 任务
分析章节正文，按以下步骤更新所有文件：

### Step 1: 更新状态文件

#### characters.json
- 更新本章出场角色的 current_state（位置、状态、装备等）
- 更新 appearance_chapters 和 last_appearance
- 更新 relationships（如有变化）

#### foreshadowing.json
- 新埋设的伏笔 → 新增条目（id: fh_XXX）
- 已回收的伏笔 → 标记 resolved: true
- 更新 _meta 统计

#### world_state.json
- 势力变化
- 地点状态变化
- 重大事件

#### timeline.json
- 追加本章时间线条目

#### recent.md
- 追加本章摘要（按模板格式）
- 如果已满10章，将第1章摘要压缩后移入卷摘要

### Step 2: 更新追踪文件

#### strand_balance.json
- 判断本章 Strand 类型: quest(主线) / fire(感情) / constellation(世界观)
- 追加 history 条目
- 重新计算 stats 比例
- 检查节奏规则，生成 alerts:
  - Quest连续≥5章 → 告警
  - Fire断档≥10章 → 告警
  - Constellation断档≥15章 → 告警

#### readability.json
- 评估章末 Hook 强度 (0-1)
- 识别 Hook 类型: 悬念/反转/期待/危机
- 统计爽点数量和密度
- 记录微兑现（承诺是否兑现）
- 判断趋势: stable/rising/declining

#### character_relations.json
- 新角色 → 追加 nodes
- 关系变化 → 追加/更新 edges
- 记录 evolution（关系演变）

#### scenes_index.md
- 战斗场景 → 追加到战斗索引
- 日常场景 → 追加到日常索引
- 情感场景 → 追加到情感索引
- 特殊描写（金句/名场面）→ 追加到特殊索引

### Step 3: 一致性校验
- 检查 characters.json 与章节内容是否一致
- 检查 foreshadowing.json 是否遗漏了本章的伏笔
- 检查是否有与 scenes_index.md 重复的描写
```

**调用示例**:
```json
sessions_spawn({
  "agentId": "writer",
  "task": "Phase 2: 状态结算（增强版）\n章节正文: {phase1_output}\n\n请按渐进式上下文系统规范更新所有状态文件和追踪文件。",
  "label": "状态结算-第{N}章",
  "model": {
    "temperature": 0.3,
    "max_tokens": 4096
  }
})
```

---

## 摘要压缩规则

### 触发条件
- recent.md 中的章节数超过10章时

### 压缩流程
```
1. 取最早的5章摘要
2. 压缩为1段卷摘要（~500字）
3. 写入 vol_X_summary.md
4. 从 recent.md 中删除这5章
5. 如果卷摘要已满10卷，压缩为全书摘要
```

### 卷摘要格式
```markdown
# 第{卷号}卷摘要（第{start}-{end}章）

## 本卷概要
{200字以内的卷概述}

## 关键转折
1. {转折1} - 第{N}章
2. {转折2} - 第{N}章

## 角色变化
- {角色名}: {变化描述}

## 伏笔动态
- 新增: {伏笔列表}
- 回收: {伏笔列表}
- 仍悬: {伏笔列表}
```
