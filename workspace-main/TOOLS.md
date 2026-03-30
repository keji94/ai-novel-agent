# Supervisor 工具手册

本文档定义 Supervisor (ai-novel-agent) 可使用的工具。

## 核心工具

### 1. sessions_spawn - 启动子智能体

**用途**: 启动专业的子 Agent 处理特定任务。

**语法**:
```json
{
  "tool": "sessions_spawn",
  "params": {
    "agentId": "planner|writer|editor|reviser|chapter-analyzer|style-analyzer|detector|analyst|operator|learner",
    "task": "任务描述",
    "label": "任务标签（可选）",
    "model": {
      "temperature": 0.7,
      "max_tokens": 8192
    }
  }
}
```

**示例**:
```json
// 启动 Planner 创建大纲
sessions_spawn({
  "agentId": "planner",
  "task": "创建修仙小说世界观和大纲",
  "label": "创建大纲"
})

// 启动 Writer 撰写章节
sessions_spawn({
  "agentId": "writer",
  "task": "根据大纲撰写第一章",
  "label": "撰写第1章"
})
```

### 2. sessions_send - 直接通信

**用途**: 与已存在的 Agent 会话进行多轮对话。

**语法**:
```json
{
  "tool": "sessions_send",
  "params": {
    "agentId": "writer",
    "message": "消息内容"
  }
}
```

**适用场景**:
- 需要多轮交互
- 需要传递完整会话上下文
- 子 Agent 需要调用其他 Agent

### 3. subagents - 子智能体管理

**用途**: 查看、管理当前会话的子智能体。

**操作**:
- `list`: 列出所有子智能体
- `kill <runId>`: 终止指定子智能体
- `steer <runId> "message"`: 向子智能体发送指令

## 文件操作工具

### 4. read - 读取文件

**用途**: 读取项目文件、配置、设定等。

**语法**:
```json
{
  "tool": "read",
  "params": {
    "path": "文件路径"
  }
}
```

**示例**:
```json
// 读取项目配置
read({"path": "./novels/xianxia/project.json"})

// 读取世界观设定
read({"path": "./novels/xianxia/settings/world.md"})
```

### 5. write - 写入文件

**用途**: 创建或更新项目文件。

**语法**:
```json
{
  "tool": "write",
  "params": {
    "path": "文件路径",
    "content": "文件内容"
  }
}
```

**注意事项**:
- 会覆盖已有文件
- 自动创建父目录

### 6. edit - 编辑文件

**用途**: 精确修改文件内容。

**语法**:
```json
{
  "tool": "edit",
  "params": {
    "path": "文件路径",
    "oldText": "要替换的文本",
    "newText": "替换后的文本"
  }
}
```

## 项目管理工具

### 7. check_project_recovery
检查是否有进行中的项目，用于灵感探索流程。

### 8. create_draft_project
为灵感探索创建临时项目。

> 详细实现见 [reference/project-management.md](reference/project-management.md)

## 存储路径说明

### 项目存储结构
```
./novels/{项目名}/
├── project.json          # 项目元数据
├── settings/             # 世界观设定
├── characters/           # 角色设定
├── outline/              # 大纲
├── chapters/             # 章节
├── context/              # 上下文追踪
└── brainstorm/           # 灵感探索
```

### 知识库路径
```
./knowledge/
├── techniques/           # 写作技巧
└── analysis/             # 作品分析
```

## 使用建议

### 优先使用 sessions_spawn
- 后台任务
- 并行处理
- 长时间运行

### 使用 sessions_send 的场景
- 多轮对话
- 实时交互
- 需要完整上下文

### 错误处理
1. 子智能体失败 → 查看日志，重试或简化任务
2. 文件不存在 → 引导用户创建或使用默认值
3. 权限问题 → 检查文件权限，提示用户

## IMA云端同步工具

主Agent统一负责云端同步（工具 9-13），子Agent只写本地文件并返回 `sync_hint`。

> IMA云端同步工具（工具 9-13）详见 [reference/ima-sync.md](reference/ima-sync.md)
