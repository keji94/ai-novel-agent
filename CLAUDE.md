# AI网文写作智能体

基于 OpenClaw 多Agent架构的网文写作智能体系统，通过 Supervisor 统一协调 10 个专业 Agent 协作完成网文创作任务。

## 项目结构

```
workspace-ai-novel-agent/
├── openclaw.json                           # 主配置文件
├── install.sh                              # 安装脚本（注册到 ~/.openclaw）
├── claude.sh                               # Claude CLI 启动脚本
├── config/
│   └── novel-config.json                   # 小说通用配置
├── skills/                                 # 技能集成
│   └── ima-skill/                          # IMA云端同步技能
├── workspace-main/                         # Supervisor (总协调器)
├── workspace-planner/                      # 策划/大纲师
├── workspace-writer/                       # 写作/作者
├── workspace-editor/                       # 编辑/审核
├── workspace-reviser/                      # 修订者
├── workspace-chapter-analyzer/             # 章节分析器
├── workspace-style-analyzer/               # 文风分析器
├── workspace-detector/                     # AI痕迹检测器
├── workspace-analyst/                      # 网文分析
├── workspace-operator/                     # 运营/分析
├── workspace-learner/                      # 写作技巧学习
├── novels/                                 # 小说内容存储
│   └── {小说名}/
│       ├── project.json                    # 项目元信息
│       ├── brainstorm/                     # 灵感记录
│       ├── settings/                       # 世界观设定
│       ├── characters/                     # 角色设定
│       ├── outline/                        # 大纲
│       ├── chapters/                       # 章节
│       └── context/                        # 上下文追踪
│           ├── indexes/                    # 索引 (角色/物品/地点)
│           ├── tracking/                   # 真相文件
│           │   ├── .snapshots/             # 版本快照
│           │   ├── world_state.json        # 世界状态
│           │   ├── particle_ledger.md      # 资源账本
│           │   ├── foreshadowing.json      # 伏笔追踪
│           │   ├── subplot_board.md        # 支线进度
│           │   ├── emotional_arcs.md       # 情感弧线
│           │   └── character_states.json   # 角色矩阵
│           └── summaries/                  # 摘要
│               ├── chapter_summaries.md
│               └── volume_summaries.md
├── scripts/
│   ├── export.sh                           # 导出 (TXT/MD/EPUB)
│   └── ima-sync.sh                         # IMA云端同步
├── knowledge/
│   └── techniques/                         # 写作技巧（按平台分类）
├── references/                             # 参考作品库
└── logs/                                   # 日志目录
```

## Agent架构

```
                         ┌───────────────────┐
                         │    Supervisor     │
                         │    (总协调器)      │
                         │   统一入口+分发    │
                         └─────────┬─────────┘
                                   │
     ┌──────────┬──────────┬───────┼───────┬──────────┬──────────┐
     │          │          │       │       │          │          │
     ▼          ▼          ▼       ▼       ▼          ▼          ▼
┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌─────────┐
│ Planner ││ Writer  ││ Editor  ││Reviser  ││Detector ││Analyst  │
│策划/大纲││写作/作者 ││编辑/审核││ 修订者  ││AI痕迹   ││网文分析 │
└─────────┘└────┬────┘└────┬────┘└────┬────┘└─────────┘└────┬────┘
                │          │          │                       │
                │          └──→ Reviser ←──┘                  │
                │               │                            │
     ┌──────────┼───────────────┼────────────────────────────┤
     ▼          ▼               ▼                            ▼
┌──────────┐┌──────────┐┌──────────┐               ┌──────────────┐
│Chapter   ││Style     ││Operator  │               │   Learner    │
│Analyzer  ││Analyzer  ││运营/分析 │               │ 写作技巧学习  │
│章节导入  ││文风分析  ││         │               │              │
└──────────┘└──────────┘└──────────┘               └──────────────┘
```

### Agent分组

| 分组 | Agent | 说明 |
|------|-------|------|
| **创作流水线** | Planner → Writer → Editor → Reviser | 核心创作流程 |
| **质量保障** | Editor + Detector + Reviser | 审核、检测、修订闭环 |
| **导入分析** | ChapterAnalyzer + StyleAnalyzer | 导入已有作品、分析文风 |
| **知识学习** | Analyst → Learner | 分析优秀作品、学习技巧入库 |
| **运营支持** | Operator | 市场分析、运营策略 |

## Agent职责

| Agent | 职责 | Workspace |
|-------|------|-----------|
| **Supervisor** | 接收用户需求，分析任务类型，分发给对应Agent | `workspace-main` |
| Planner | 世界观构建、角色设定、剧情大纲、灵感探索 | `workspace-planner` |
| Writer | 两阶段写作(创意+状态结算)、场景描写、对话编写 | `workspace-writer` |
| Editor | 33维度审计、文字润色、一致性检查 | `workspace-editor` |
| Reviser | 5种修订模式(polish/spot-fix/rewrite/rework/anti-detect) | `workspace-reviser` |
| ChapterAnalyzer | 导入已有章节、逆向工程生成真相文件 | `workspace-chapter-analyzer` |
| StyleAnalyzer | 分析文风指纹、生成风格指南 | `workspace-style-analyzer` |
| Detector | AI痕迹检测(11规则+统计+语义分析) | `workspace-detector` |
| Analyst | 分析优秀网文的结构、风格、节奏、爽点设计 | `workspace-analyst` |
| Operator | 市场趋势分析、读者偏好研究、更新策略建议 | `workspace-operator` |
| Learner | 学习写作技巧、总结最佳实践、提供写作指导 | `workspace-learner` |

## 工作流程

```
用户需求 → Supervisor解析
    │
    ├─→ 灵感探索 → Planner(引导式头脑风暴) → 逐步明确创作方向
    │
    ├─→ 创作新小说 → Planner(大纲设定) → Writer(两阶段撰写)
    │                                       ├─ Phase 1: 创意写作 (temp 0.7)
    │                                       └─ Phase 2: 状态结算 (temp 0.3)
    │                                    → Editor(33维审计) → Reviser(修订) → 返回用户
    │
    ├─→ 章节修改 → Writer(修改) → Editor(审核) → 真相文件重算
    │
    ├─→ 导入续写 → ChapterAnalyzer(导入+生成真相文件) → Writer(续写)
    │
    ├─→ 文风仿写 → StyleAnalyzer(分析风格) → Writer(按风格指南写作)
    │
    ├─→ AI检测 → Detector(11规则+统计分析) → Reviser(去AI味) → Detector(复检)
    │
    ├─→ 分析作品 → Analyst(拆解分析) → Learner(提取技巧入库)
    │
    ├─→ 运营咨询 → Operator(分析建议)
    │
    └─→ 学习技巧 → Learner(提供写作指导)
```

## 核心机制

### 两阶段写作架构

| 阶段 | 温度 | 输出 | 目的 |
|------|------|------|------|
| Phase 1: 创意写作 | 0.7 | 章节正文 (2000-3000字) | 创造性表达 |
| Phase 2: 状态结算 | 0.3 | 7个真相文件更新 | 精确追踪一致性 |

写后自动运行 11 条确定性规则验证器，error 级别违规自动触发 spot-fix。

### 真相文件（7个）

长篇写作（500万字级）的核心上下文管理机制：

| 文件 | 用途 |
|------|------|
| `world_state.json` | 世界状态：地点、势力、已知信息 |
| `particle_ledger.md` | 资源账本：物品、金钱、修炼资源 |
| `foreshadowing.json` | 伏笔追踪：未闭合伏笔 |
| `character_states.json` | 角色矩阵：关系、信息边界 |
| `subplot_board.md` | 支线进度板 |
| `emotional_arcs.md` | 情感弧线 |
| `chapter_summaries.md` | 章节摘要 |

支持版本快照（`.snapshots/`），Phase 2 结算前自动创建，保留最近 5 个版本。

### 33维度审计系统

Editor 审计覆盖 7 大类 33 个维度：

| 类别 | 维度 | 关键检查项 |
|------|------|-----------|
| 基础一致性 | 1-7 | OOC、时间线、设定冲突、战力崩坏、数值、伏笔、节奏 |
| 内容质量 | 8-14 | 文风、信息越界、词汇疲劳、利益链、配角降智 |
| 叙事技巧 | 15-19 | 爽点虚化、台词失真、流水账、视角一致性 |
| AI痕迹 | 20-23 | 段落等长、套话密度、公式化转折、列表式结构 |
| 支线弧线 | 24-26 | 支线停滞、弧线平坦、节奏单调 |
| 敏感内容 | 27 | 敏感词检查 |
| 番外/同人 | 28-33 | 正传冲突、未来泄露、伏笔隔离、大纲偏离 |

审计分级: A(优秀) → B(良好) → C(合格) → D(不合格)。不通过自动推荐 Reviser 修订模式。

### AI痕迹检测

Detector 三层检测体系：

| 层级 | 方法 | 成本 | 内容 |
|------|------|------|------|
| 确定性规则 | 11条规则 | 零成本 | 禁止句式、破折号、转折词密度等 |
| 统计特征 | 4项指标 | 零成本 | TTR、句长标准差、段落标准差、主动句比例 |
| 语义分析 | LLM分析 | 低成本 | 句式单调、逻辑跳跃、情感平淡、描写空洞、对话生硬 |

AI 痕迹得分 0-100，低于 70 建议修订，低于 60 建议重写。

### IMA云端同步

通过 IMA 技能实现双写双读机制：
- **写入(双写)**: 本地文件 → IMA云端笔记本
- **读取(回退)**: 尝试本地 → 不存在则从 IMA 读取 → 回写本地

## 模型配置

在 `openclaw.json` 中为不同 Agent 配置模型和温度：

| Agent | 温度 | max_tokens | 说明 |
|-------|------|-----------|------|
| Supervisor | 0.7 | 8192 | 平衡理解和决策 |
| Planner | 0.8 | 16384 | 创意构思 |
| Writer Phase 1 | 0.9 | 16384 | 高创造性写作 |
| Writer Phase 2 | 0.3 | 4096 | 精确状态追踪 |
| Editor | 0.5 | 8192 | 精确审核 |
| Reviser | 0.3 | 8192 | 精确修复 |
| ChapterAnalyzer | 0.3 | 16384 | 精确分析 |
| StyleAnalyzer | 0.3 | 16384 | 统计分析 |
| Detector | 0.3 | 16384 | 规则检测 |
| Analyst | 0.6 | 16384 | 分析需要精确度 |
| Operator | 0.7 | 8192 | 运营分析 |
| Learner | 0.7 | 16384 | 学习内容输出 |

## Agent定义文件

每个 Agent 有四个核心定义文件：

- **SOUL.md**: Agent 人格定义（角色身份、性格特质、专业能力）
- **AGENTS.md**: 工作流程定义（任务类型、协作模式、接口规范）
- **TOOLS.md**: 工具手册（可用工具和使用方法）
- **MEMORY.md**: 记忆存储（长期知识和上下文信息，跨会话持久化）

Supervisor 额外有 **HEARTBEAT.md** 定义项目状态恢复机制。

## 扩展开发

### 添加新 Agent

1. 在项目根目录创建 `workspace-{agent名}/` 目录
2. 编写 SOUL.md、AGENTS.md、TOOLS.md、MEMORY.md
3. 在 `openclaw.json` 的 `agents` 中添加配置
4. 更新 Supervisor 的 AGENTS.md 添加路由规则
5. 更新 Supervisor 的 `allowAgents` 列表

### 知识库扩展

在 `knowledge/techniques/` 下按平台分类存放写作技巧，写作时根据场景自动匹配加载。

## 注意事项

- 所有创作内容存储在 `novels/` 目录
- Agent 间通过 `sessions_spawn`（推荐）或 `sessions_send` 协作
- 子 Agent 完成后返回 `sync_hint`，由主 Agent 统一执行 IMA 云端同步
- 真相文件在 Phase 2 结算前自动创建版本快照
- 配置文件使用 JSON 格式，支持环境变量替换

## License

MIT
