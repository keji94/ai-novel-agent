# AI网文写作智能体 - 架构设计文档

## 1. 系统概述

### 1.1 项目背景

基于OpenClaw多Agent框架构建的网文写作智能体系统，旨在通过多个专业Agent协作，为用户提供完整的网文创作支持。

### 1.2 核心目标

- 支持从构思到完本的完整创作流程
- 提供专业的市场分析和写作指导
- 保持创作内容的一致性和质量
- 通过多渠道学习（拆书、文章、视频）持续提升写作能力

### 1.3 设计原则

- **职责单一**: 每个Agent专注于特定领域
- **协作透明**: Agent间协作流程清晰可追踪
- **扩展灵活**: 易于添加新Agent或修改流程

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────┐
│                    用户界面层                        │
│              (CLI / 飞书 / Web API)                  │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                ai-novel-agent (入口)                 │
│              (任务路由 + 结果汇总)                    │
└─────────────────────┬───────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│ Planner      │ │ Writer   │ │ Editor       │
│ 策划/大纲    │ │ 写作/作者│ │ 编辑/审核    │
└──────────────┘ └──────────┘ └──────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│ Analyst      │ │ Operator │ │ Learner      │
│ 网文分析     │ │ 运营分析 │ │ 技巧学习     │
└──────────────┘ └──────────┘ └──────────────┘
```

### 2.2 Agent职责矩阵

| Agent | 输入 | 处理 | 输出 | Workspace |
|-------|------|------|------|-----------|
| ai-novel-agent | 用户请求 | 任务分析、路由分发 | 协调结果 | workspace-ai-novel-agent |
| Planner | 创作需求 | 设定构建、大纲规划 | 设定文档、大纲 | workspace-planner |
| Writer | 大纲、设定 | 章节撰写 | 正文内容 | workspace-writer |
| Editor | 章节内容 | 审核、润色 | 审核报告、润色版 | workspace-editor |
| analyst | 作品名称 | 分析拆解 | 分析报告 | workspace-analyst |
| Operator | 市场问题 | 数据分析 | 运营建议 | workspace-operator |
| Learner | 学习主题 | 技巧总结 | 技巧文档 | workspace-learner |

### 2.3 协作模式

#### 串行协作

```
User → ai-novel-agent → Planner → Writer → Editor → ai-novel-agent → User
```

适用场景：完整创作流程

#### 并行协作

```
                         ┌→ Analyst ─┐
User → ai-novel-agent ──┤           ├→ ai-novel-agent → User
                         └→ Learner ─┘
```

适用场景：分析学习流程

## 3. 数据模型

### 3.1 存储架构

采用**双写双读**的混合存储模式：

```
┌─────────────────┐        自动同步        ┌─────────────────┐
│   novels/       │  ──────────────────────►│   IMA云端       │
│   (本地主存储)   │                         │   (云端备份)    │
│                 │  ◄──────────────────────│                 │
└─────────────────┘        回退读取          └─────────────────┘
```

**配置文件分离**:
- `openclaw.json`: 框架配置（agents、channels、skills引用）
- `config/novel-config.json`: 业务配置（存储策略、写作参数、学习平台等）

**存储策略**:
- **本地存储为主**: 快速访问、离线可用、完整上下文追踪
- **云端同步备份**: 跨设备同步、数据安全、移动端查看
- **读回退机制**: 本地不存在时自动从IMA读取

**业务配置** (config/novel-config.json):
```json
{
  "storage": {
    "primaryPath": "./novels",
    "ima": {
      "enabled": true,
      "syncStrategy": "dual_write",
      "syncTargets": {
        "settings": {"enabled": true},
        "characters": {"enabled": true},
        "outline": {"enabled": true},
        "chapters": {"enabled": true},
        "context": {"enabled": false}
      }
    }
  }
}
```

### 3.2 项目结构

```
novels/{project_name}/
├── project.json          # 项目元数据
├── context/              # 上下文管理（长篇写作核心，仅本地）
│   ├── summaries/        # 摘要存储
│   │   ├── chapter_summaries.md   # 章节摘要集
│   │   └── volume_summaries.md    # 卷摘要集
│   ├── tracking/         # 状态追踪
│   │   ├── character_states.json  # 角色状态追踪
│   │   ├── foreshadowing.json     # 伏笔追踪
│   │   └── world_state.json       # 世界状态
│   └── indexes/          # 索引
│       ├── character_index.md     # 角色出场索引
│       ├── location_index.md      # 地点索引
│       └── item_index.md          # 物品/功法索引
├── settings/             # 世界观设定（同步IMA）
│   ├── world.md          # 世界观设定
│   ├── power_system.md   # 力量体系
│   ├── factions.md       # 势力设定
│   └── timeline.md       # 时间线
├── characters/           # 角色设定（同步IMA）
│   ├── main.md           # 主角设定
│   ├── supporting.md     # 配角设定
│   └── villains.md       # 反派设定
├── outline/              # 大纲（同步IMA）
│   ├── main.md           # 总大纲
│   ├── volume_{n}.md     # 卷大纲
│   └── chapters.md       # 章节规划
└── chapters/             # 章节正文（同步IMA）
    ├── chapter_{n}.md    # 章节正文
    └── drafts/           # 草稿
```

### 3.3 核心数据结构

#### 项目元数据 (project.json)

```json
{
  "name": "仙道长生",
  "genre": "仙侠",
  "status": "writing",
  "created_at": "2024-01-15",
  "updated_at": "2024-01-20",
  "statistics": {
    "total_words": 50000,
    "chapters_completed": 15,
    "chapters_planned": 100
  }
}
```

#### 章节结构

```markdown
# 第N章 章节名

[正文内容]

---
## 元数据
- 字数: 2856
- 状态: draft/published
- 创建时间: 2024-01-15
- 修改时间: 2024-01-15
```

#### 章节摘要结构

```markdown
## 第N章 摘要

**核心事件**: [一句话概括]
**出场人物**: [角色列表]
**地点**: [场景地点]
**伏笔**: [本章埋设/回收的伏笔]
**角色变化**: [角色状态变化]
**下章预告**: [衔接要点]
```

#### 角色状态追踪结构

```json
{
  "name": "林风",
  "current_state": {
    "cultivation": "筑基初期",
    "location": "青云宗内门",
    "equipment": ["玄铁剑", "储物袋(中品)"],
    "skills": ["青云剑诀(圆满)"],
    "relationships": {"苏婉": "相识"}
  },
  "last_appearance": 156,
  "state_history": [
    {"chapter": 100, "change": "突破筑基期"}
  ]
}
```

#### 伏笔追踪结构

```json
{
  "id": "F001",
  "description": "签到系统来源",
  "planted_chapter": 10,
  "status": "pending",
  "planned_reveal": 200,
  "resolved_chapter": null
}
```

### 3.4 上下文组装策略

当写作第N章时，自动组装以下上下文：

| 内容 | 大小限制 | 来源 |
|------|----------|------|
| 全书核心摘要 | ~500字 | context/summaries/ |
| 当卷摘要 | ~1000字 | context/summaries/ |
| 前5章摘要 | ~1000字 | context/summaries/ |
| 出场角色状态卡 | ~500字/角色 | context/tracking/ |
| 相关未回收伏笔 | ~300字 | context/tracking/ |
| 相关设定片段 | ~1000字 | settings/ |
| 章节大纲 | ~500字 | outline/ |
| **总计** | ~5000字 | 可在上下文窗口内 |

## 4. 通信协议

### 4.1 Agent间通信

使用OpenClaw的`sessions_send`工具：

```json
{
  "tool": "sessions_send",
  "params": {
    "agent_id": "planner",
    "message": "创建修仙小说的世界观和大纲",
    "context": {
      "genre": "仙侠",
      "style": "热血爽文"
    }
  }
}
```

### 4.2 同步职责分离

**架构原则**: 子Agent只写本地文件，主Agent负责云端同步。

```
用户请求
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    主Agent (ai-novel-agent)                  │
│                                                              │
│  1. 接收请求，分发任务                                        │
│  2. 接收子Agent返回结果                                       │
│  3. 检查 sync_hint，执行IMA同步                               │
│  4. 返回结果给用户                                            │
└───────────────────────────┬─────────────────────────────────┘
                            │
            sessions_send() │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    子Agent (planner/writer/...)              │
│                                                              │
│  1. 处理任务，写入本地文件                                    │
│  2. 返回结果 + sync_hint                                      │
│                                                              │
│  return {                                                    │
│    "status": "success",                                      │
│    "response": "世界观设定已完成",                            │
│    "sync_hint": {                                            │
│      "type": "settings",                                     │
│      "project": "仙道长生",                                   │
│      "file": "./novels/xianxia/settings/world.md"           │
│    }                                                         │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

**sync_hint结构**:
```json
{
  "type": "settings|characters|outline|chapters|technique",
  "project": "项目名称",
  "file": "本地文件路径",
  "metadata": {
    "chapter": 100,          // 章节类型时
    "character": "林风",     // 角色类型时
    "settings_type": "world" // 设定类型时
  }
}
```

### 4.2 消息格式

#### 请求消息

```json
{
  "task": "任务类型",
  "params": {
    "key": "value"
  },
  "context": {
    "相关上下文"
  }
}
```

#### 响应消息

```json
{
  "status": "success/error",
  "result": {
    "输出结果"
  },
  "metadata": {
    "processing_time": 1000,
    "tokens_used": 2000
  }
}
```

## 5. 扩展机制

### 5.1 IMA Skill集成

IMA知识库Skill已集成，支持笔记和知识库操作：

**配置方式**:
```bash
# 方式A：环境变量
export IMA_OPENAPI_CLIENTID="your_client_id"
export IMA_OPENAPI_APIKEY="your_api_key"

# 方式B：配置文件
mkdir -p ~/.config/ima
echo "your_client_id" > ~/.config/ima/client_id
echo "your_api_key" > ~/.config/ima/api_key
```

**API Key获取**: https://ima.qq.com/agent-interface

**同步工具**:
```bash
# 同步设定
./scripts/ima-sync.sh sync-settings "仙道长生" "world" "./novels/xianxia/settings/world.md"

# 同步章节
./scripts/ima-sync.sh sync-chapter "仙道长生" 1 "./novels/xianxia/chapters/chapter_1.md"

# 搜索内容
./scripts/ima-sync.sh search "开篇技巧"

# 读取笔记
./scripts/ima-sync.sh read "doc_xxx"
```

**Skill文档位置**: `skills/ima-skill/`

### 5.2 添加新Agent

1. 创建工作空间目录
2. 编写四个核心定义文件
3. 在openclaw.json中注册
4. 更新Supervisor路由规则

### 5.3 添加新工具

1. 在Agent的TOOLS.md中定义
2. 实现工具函数
3. 添加到OpenClaw工具注册

### 5.4 自定义工作流

在AGENTS.md中定义新的工作流程：

```markdown
## 自定义流程

### 流程名称

```
条件: 触发条件
动作:
  1. 步骤一
  2. 步骤二
```
```

## 6. 安全考虑

### 6.1 数据隔离

- 每个Agent有独立的工作空间
- 项目文件按目录隔离

### 6.2 权限控制

- 敏感配置使用环境变量
- API密钥不存储在代码中

### 6.3 内容安全

- Editor Agent进行内容审核
- 可配置敏感词过滤

## 7. 性能优化

### 7.1 并行处理

- 独立任务并行执行
- 使用Agent隔离避免上下文污染

### 7.2 缓存策略

- 设定文件缓存
- 分析结果缓存

### 7.3 资源管理

- 合理配置max_tokens
- 按需调整模型temperature

## 8. 部署方案

### 8.1 开发环境

```bash
# 本地运行
openclaw start -c openclaw.json
```

### 8.2 生产环境

```bash
# 后台服务
openclaw serve -c openclaw.json --port 8080
```

### 8.3 Docker部署

```dockerfile
FROM python:3.9
COPY . /app
WORKDIR /app
RUN pip install openclaw
CMD ["openclaw", "serve", "-c", "openclaw.json"]
```

## 9. 监控与日志

### 9.1 日志配置

```json
{
  "logging": {
    "level": "info",
    "file": "logs/openclaw.log",
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  }
}
```

### 9.2 监控指标

- Agent调用次数
- 平均响应时间
- 错误率
- Token消耗