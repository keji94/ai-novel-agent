# ai-novel-agent

基于 OpenClaw workspace 架构 + Harness 工程思想的 **AI 网文写作框架**。

你需要具备 openclaw 项目的知识，我在本地给你放了一份源码，在有必要的时候查看源码：/Users/nieyi6/IdeaProjects/openclaw


## 项目定位
这是一个多 Agent 协作的网文创作系统，Main Agent 作为 Supervisor 路由用户请求到专业子 Agent，覆盖从灵感探索到成稿的完整创作流程。

## 项目配置修改约束
为了防止项目的配置文件如 AGENT.md SOUL.md过于膨胀。你在修改这类文件后，都需要重新审视一下文件的大小，如果文件过于庞大，则需要做拆分和渐进式加载

## 目录结构

```
ai-novel-agent/
├── workspace-main/          # Supervisor 总协调器（入口）
├── workspace-planner/       # Planner 策划/大纲师
├── workspace-writer/        # Writer 写作/作者
├── workspace-editor/        # Editor 编辑/审核
├── workspace-reviser/       # Reviser 修订者
├── workspace-analyst/       # Analyst 网文分析师
├── workspace-operator/      # Operator 运营/市场分析
├── workspace-learner/       # Learner 写作技巧学习
├── workspace-detector/      # Detector AI痕迹检测器
├── workspace-chapter-analyzer/  # ChapterAnalyzer 章节逆向分析
├── workspace-style-analyzer/    # StyleAnalyzer 文风分析器
├── workspace-critic/            # Critic 世界观骇客（15维度审计 + Fix Loop回归）
├── novels/                  # 小说项目存储（各 Agent 共享）
│   └── {项目名}/
│       ├── project.json     # 项目元数据 & 生命周期状态
│       ├── outline/         # 世界观/角色/大纲
│       ├── chapters/        # 章节正文
│       └── context/         # 真相文件(7类)
├── knowledge/               # 写作技巧知识库（Learner 管理）
│   └── techniques/
│       ├── _index.md        # 轻量总索引（始终加载，<2000 token）
│       ├── _sources.md      # 来源注册表
│       ├── _feedback.md     # 反馈记录 + 待复查列表
│       ├── items/           # 技巧文件池（T001.md, T002.md...）
│       ├── structure/       # 分类索引（派生视图，引用 items/）
│       ├── description/
│       ├── dialogue/
│       ├── character/
│       └── climax/
├── references/              # 参考资料存放
└── .openclaw/               # OpenClaw 框架配置 & skills
```

## 核心工作流

| 规则 | 触发场景 | 流程 |
|------|---------|------|
| 0 灵感探索 | 模糊创作意向 | 恢复/创建项目 → Planner brainstorm |
| 1 新小说创作 | 明确创作需求 | Planner创建 → Critic审计 → Fix Loop(最多3轮) → User Checkpoint → Editor审核 |
| 2 内容撰写 | 写具体章节 | Writer → Editor 自动审核 |
| 3 分析学习 | 分享链接/学技巧 | Analyst 提取 → Editor 一审 → Learner 入库 → Editor 二审 |
| 4 章节导入 | 续写已有小说 | ChapterAnalyzer → 生成真相文件 |
| 5 文风仿写 | 模仿作者风格 | StyleAnalyzer → 风格指南 |
| 6 AI检测 | 检测AI痕迹 | Detector → 检测报告 |
| 9 章节修改 | 修改已有章节 | Writer/Reviser → Editor → 真相文件重算 |

> 详细路由规则和上下文传递格式 → `workspace-main/AGENTS.md`

## 各 Workspace 标准文件

每个 `workspace-*` 目录遵循 OpenClaw 规范：

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| `SOUL.md` | Agent 灵魂/角色定义 | 始终加载 |
| `AGENTS.md` | 可调用的子 Agent 与路由规则 | 需要协作时 |
| `TOOLS.md` | 可用工具手册 | 需要工具时 |
| `MEMORY.md` | 运行时记忆 | 始终加载 |
| `IDENTITY.md` | Agent 身份（名称/形象） | 首次对话 |
| `HEARTBEAT.md` | 心跳/定期任务 | 主 Agent 专有 |
| `USER.md` | 用户偏好 | 主 Agent 专有 |

## Agent 调用方式

- **`sessions_spawn`**（推荐）: 异步子 Agent，适合并行/后台任务
- **`sessions_send`**: 同步多轮对话，适合需要实时交互的场景

## 项目生命周期

`brainstorming → basic_design → detailed_design → outlining → writing → completed`

## 存储约定

- 小说数据统一存放在 repo 根目录 `novels/`，子 Agent 通过 symlink 访问
- 知识库存放在 `knowledge/techniques/`，采用 **items/ 平坦池 + 分类索引** 架构
  - 技巧文件（items/T001.md）是单一事实来源
  - 分类索引是派生视图，一条技巧可属于多个分类
  - `_index.md` 是轻量入口（<2000 token），详情按需加载
  - 所有技巧入库前必须经过 Editor 审核（双重审核闭环）
- `*/memory/` 目录不纳入版本控制

## IMA 云端同步

主 Agent 统一负责云端同步。子 Agent 只写本地文件，返回 `sync_hint`，由主 Agent 执行 IMA API 同步。
详见 `workspace-main/TOOLS.md` 第 9-13 节。
