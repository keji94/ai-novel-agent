# 渐进式上下文管理系统设计方案

## 设计理念

> AI长篇写作的"遗忘"问题，本质不是"搜索不到"，而是"状态没追踪好"。
> 通过结构化MD文件 + 分层摘要 + 条件加载，80%的问题可以低成本解决。

## 核心架构

```
Writer 写第N章时的上下文加载流程：

第一层（必加载，~2K字）──┐
  ├─ 角色状态卡            │
  ├─ 伏笔债务表            │
  └─ 最近N章摘要            ├→ 组装成写作上下文
                            │
第二层（条件加载，~3K字）──┤
  ├─ 本章大纲涉及角色详细设定│
  ├─ 相关伏笔原文           │
  └─ 节奏/追读力指标        │
                            │
第三层（按需加载，~2K字）──┘
  ├─ 相关卷摘要
  ├─ 防重复描写索引
  └─ 角色关系图
```

## 文件结构

```
novels/{项目}/
├── context/
│   ├── index.md                        ← 索引入口（Writer从这里开始）
│   ├── state/
│   │   ├── characters.json             ← 角色当前状态
│   │   ├── foreshadowing.json          ← 伏笔债务表
│   │   ├── timeline.json               ← 时间线
│   │   └── world_state.json            ← 世界当前状态
│   ├── summaries/
│   │   ├── recent.md                   ← 最近10章详细摘要（滚动窗口）
│   │   ├── vol_1_summary.md            ← 第1卷摘要
│   │   └── arc_{主线名}_summary.md     ← 按剧情线组织
│   ├── descriptions/
│   │   ├── scenes_index.md             ← 已描写场景索引（防重复）
│   │   ├── fights_index.md             ← 已描写战斗索引
│   │   └── emotions_index.md           ← 已描写情感索引
│   └── tracking/
│       ├── strand_balance.json         ← Quest/Fire/Constellation 节奏
│       ├── readability.json            ← 追读力量化指标
│       └── character_relations.json    ← 角色关系图谱
```

## 各文件详细规范

### 1. characters.json - 角色状态卡

```json
{
  "_meta": {
    "version": "1.0",
    "last_updated_chapter": 10,
    "last_updated_at": "2026-03-30"
  },
  "characters": {
    "林风": {
      "id": "char_001",
      "role": "protagonist",
      "profile": "青云宗内门弟子，性格沉稳果断",
      "current_state": {
        "realm": "筑基中期",
        "location": "青云宗内门",
        "equipment": ["青锋剑", "储物袋"],
        "status": "正常"
      },
      "appearance_chapters": [1, 2, 3, 5, 7, 8, 10],
      "last_appearance": 10,
      "relationships": {
        "苏婉": "同门师姐，互有好感",
        "张长老": "师尊，关系亲近"
      }
    }
  }
}
```

**更新时机**: 每章 Phase 2 结算时自动更新
**加载策略**: 第一层，每次必加载（只加载本章涉及的角色的状态）

### 2. foreshadowing.json - 伏笔债务表

```json
{
  "_meta": {
    "version": "1.0",
    "total_planted": 15,
    "total_resolved": 8,
    "total_pending": 7
  },
  "items": [
    {
      "id": "fh_001",
      "description": "神秘老者的真实身份",
      "planted_chapter": 3,
      "planted_context": "第三章结尾，老者留下一个刻有奇怪符文的玉佩",
      "planned_resolve_chapter": 50,
      "resolved": false,
      "priority": "high",
      "related_characters": ["林风", "神秘老者"],
      "tags": ["主线", "身世"]
    },
    {
      "id": "fh_005",
      "description": "苏婉的隐藏血脉",
      "planted_chapter": 7,
      "planted_context": "苏婉受伤时血液呈现淡金色",
      "planned_resolve_chapter": null,
      "resolved": true,
      "resolved_chapter": 15,
      "resolved_context": "揭示苏婉为上古凤族后裔",
      "priority": "medium",
      "related_characters": ["苏婉"],
      "tags": ["支线", "身世"]
    }
  ]
}
```

**更新时机**: 每章 Phase 2 结算时更新
**加载策略**: 第一层，只加载 pending 状态的条目

### 3. recent.md - 最近章节摘要（滚动窗口）

```markdown
# 最近章节摘要

## 第10章 古物初醒
- **核心事件**: 林风在密室中激活古物共鸣，引发异象
- **出场人物**: 林风、苏婉、张长老
- **地点**: 青云宗密室
- **新增伏笔**: 密室壁画中出现了与玉佩相同的符文（fh_010）
- **回收伏笔**: 无
- **角色变化**: 林风获得古物共鸣能力
- **章末钩子**: 壁画中浮现出一幅地图

## 第9章 暗流涌动
...
```

**滚动规则**: 保留最近10章详细摘要
**升级规则**: 超过10章的摘要 → 压缩为卷摘要（每卷一章总结）
**加载策略**: 第一层，每次必加载

### 4. scenes_index.md - 场景描写索引（防重复）

```markdown
# 场景描写索引

## 战斗场景
- [第3章] 密林遭遇战：林风 vs 二阶妖兽，以速度取胜（环境：雾气弥漫的密林）
- [第7章] 宗门大比：林风 vs 赵天，灵力对轰（环境：宗门擂台，围观弟子众多）
- [第10章] 古物共鸣激活：林风体内力量暴走（环境：密室，符文发光）

## 日常场景
- [第1章] 宗门晨练：外门弟子集合（环境：清晨，薄雾）
- [第5章] 药园采药：林风与苏婉偶遇（环境：药园，夕阳）

## 情感场景
- [第5章] 药园偶遇：林风对苏婉产生好感（氛围：温暖、微妙）
- [第8章] 生死离别：师兄为保护林风牺牲（氛围：悲壮、紧张）
```

**更新时机**: 每章 Phase 2 结算时追加
**加载策略**: 第三层，Writer 根据大纲判断是否需要加载（如写战斗场景时加载战斗索引）

### 5. strand_balance.json - 节奏平衡表

```json
{
  "_meta": {
    "version": "1.0",
    "last_updated_chapter": 10,
    "ideal_ratio": { "quest": 60, "fire": 20, "constellation": 20 }
  },
  "history": [
    { "chapter": 8, "strand": "quest", "note": "主线推进，探索古物" },
    { "chapter": 9, "strand": "fire", "note": "苏婉关心林风伤势" },
    { "chapter": 10, "strand": "quest", "note": "古物共鸣激活" }
  ],
  "stats": {
    "total": 10,
    "quest_count": 6,
    "fire_count": 2,
    "constellation_count": 2,
    "quest_ratio": 60,
    "fire_ratio": 20,
    "constellation_ratio": 20
  },
  "alerts": [
    "Quest连续已达3章，建议下一章切换Fire或Constellation"
  ]
}
```

**规则**:
- Quest连续不超过5章
- Fire断档不超过10章
- Constellation断档不超过15章

**加载策略**: 第二层，每次加载 alerts 部分

### 6. readability.json - 追读力量化

```json
{
  "_meta": {
    "version": "1.0",
    "last_updated_chapter": 10
  },
  "history": [
    {
      "chapter": 10,
      "hook_strength": 0.85,
      "hook_type": "悬念",
      "cool_point_count": 2,
      "cool_point_density": 0.4,
      "micro_payoffs": [
        { "promise": "林风会去密室", "fulfilled": true, "chapter": 10 }
      ],
      "strand_type": "quest"
    }
  ],
  "trend": "stable"
}
```

**指标定义**:
- `hook_strength` (0-1): 章末钩子强度
- `hook_type`: 悬念/反转/期待/危机
- `cool_point_count`: 本章爽点数量
- `cool_point_density`: 爽点密度（爽点数/千字）
- `micro_payoffs`: 微兑现记录

**加载策略**: 第二层，加载最近5章的趋势 + alerts

### 7. character_relations.json - 角色关系图谱

```json
{
  "_meta": {
    "version": "1.0",
    "last_updated_chapter": 10
  },
  "nodes": [
    { "id": "林风", "type": "protagonist" },
    { "id": "苏婉", "type": "supporting" },
    { "id": "张长老", "type": "mentor" },
    { "id": "赵天", "type": "rival" }
  ],
  "edges": [
    { "source": "林风", "target": "苏婉", "relation": "同门师姐，互有好感", "since_chapter": 1, "evolution": "第5章药园偶遇后关系升温" },
    { "source": "林风", "target": "张长老", "relation": "师徒", "since_chapter": 1 },
    { "source": "林风", "target": "赵天", "relation": "对手/敌对", "since_chapter": 2, "evolution": "第7章宗门大比后敌意加深" }
  ]
}
```

**加载策略**: 第三层，涉及复杂人物关系时加载

## Writer 上下文加载流程

### 步骤1: 读取索引
```
read(context/index.md) → 确定项目基本信息、当前进度
```

### 步骤2: 第一层加载（必选）
```
read(context/state/characters.json) → 提取本章涉及角色状态
read(context/state/foreshadowing.json) → 提取 pending 伏笔
read(context/summaries/recent.md) → 最近10章摘要
```

### 步骤3: 第二层加载（条件）
```
根据大纲判断需要加载的详细设定文件
read(context/tracking/strand_balance.json) → 检查节奏 alerts
read(context/tracking/readability.json) → 检查追读力趋势
```

### 步骤4: 第三层加载（按需）
```
如果写战斗场景 → read(context/descriptions/fights_index.md)
如果涉及复杂关系 → read(context/tracking/character_relations.json)
如果涉及之前卷的内容 → read(context/summaries/vol_X_summary.md)
```

### 步骤5: 组装上下文
```
将所有加载内容组装成 Writer 的输入 prompt
总上下文控制在 7K 字以内
```

## 摘要层级系统

```
第1章 ─┐
第2章 ─┤
第3章 ─┤
第4章 ─┤→ 压缩为 vol_1_summary.md（~500字）
第5章 ─┘

第6章 ─┐                    ┌→ 压缩为全书摘要（~1000字）
第7章 ─┤→ vol_2_summary.md ─┤
...    ─┘                    └→ 只在需要全书概览时加载
```

**压缩规则**:
- 10章详细摘要 → 1章卷摘要（~500字）
- 10卷摘要 → 全书摘要（~1000字）
- 保留关键转折点、核心角色变化、重要伏笔

## Phase 2 结算增强

每章写完后，Phase 2 状态结算需要额外更新：

1. **characters.json** - 更新角色状态
2. **foreshadowing.json** - 更新伏笔（新增/回收）
3. **recent.md** - 追加本章摘要，滚动窗口
4. **scenes_index.md** - 追加新描写的场景
5. **strand_balance.json** - 更新节奏统计
6. **readability.json** - 评估追读力指标
7. **character_relations.json** - 更新关系变化

## 与现有7真相文件的兼容

渐进式系统是对现有真相文件的**升级**，不是替换：

| 现有文件 | 新系统对应 | 变化 |
|---------|-----------|------|
| story_bible.md | outline/世界观设定*.md | 保持不变 |
| character_matrix.md | state/characters.json | 升级为结构化JSON |
| current_state.md | state/world_state.json + state/timeline.json | 拆分+结构化 |
| particle_ledger.md | 保留 | 保持不变 |
| pending_hooks.md | state/foreshadowing.json | 升级为结构化JSON |
| chapter_summaries.md | summaries/recent.md + 卷摘要 | 分层+滚动窗口 |
| subplot_board.md | tracking/strand_balance.json | 升级+新增节奏控制 |

**迁移策略**: 新项目直接使用新结构，旧项目逐步迁移。

## 实施计划

| 阶段 | 任务 | 工作量 | 优先级 |
|------|------|--------|--------|
| A | 创建 context 目录结构和模板文件 | 半天 | P0 |
| B | 创建 state/characters.json 模板和规范 | 半天 | P0 |
| C | 创建 state/foreshadowing.json 模板和规范 | 半天 | P0 |
| D | 创建 summaries/recent.md 模板和滚动规则 | 半天 | P0 |
| E | 创建 descriptions/*.md 索引模板 | 半天 | P1 |
| F | 创建 tracking/strand_balance.json 模板 | 半天 | P1 |
| G | 创建 tracking/readability.json 模板 | 半天 | P1 |
| H | 创建 tracking/character_relations.json 模板 | 半天 | P1 |
| I | 更新 Writer Phase 2 结算流程 | 1天 | P0 |
| J | 更新 Writer SOUL.md 中的上下文加载逻辑 | 1天 | P0 |
| K | 更新 Editor 审核维度（追读力+节奏） | 半天 | P1 |
| L | 创建 context-builder.py 脚本（自动化组装上下文） | 1天 | P1 |
| M | 用「末世古物共鸣」项目测试全流程 | 半天 | P0 |
