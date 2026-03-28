# 多Agent配置说明

## 📋 配置概述

本项目遵循OpenClaw官方Subagent最佳实践，配置了完整的多Agent协作系统。

## ✅ 已完成的配置

### 1. openclaw.json 配置

#### Agent注册 (`agents`)
- ✅ 7个Agent已正确注册在顶层
- ✅ `ai-novel-agent` 标记为入口Agent (`is_entry: true`)
- ✅ 每个Agent有独立的workspace配置
- ✅ 不同Agent配置了不同的模型参数

```json
"agents": {
  "ai-novel-agent": {
    "is_entry": true,
    "subagents": {
      "allowAgents": ["planner", "writer", "editor", "analyst", "operator", "learner"]
    }
  },
  "planner": { ... },
  "writer": { ... },
  "editor": { ... },
  "analyst": { ... },
  "operator": { ... },
  "learner": { ... }
}
```

#### Subagent默认配置 (`agents.defaults.subagents`)
- ✅ 配置了子智能体的默认模型
- ✅ 设置了思考级别: `basic`
- ✅ 限制最大并发数: `5`
- ✅ 配置了自动归档时间: `60分钟`

```json
"agents": {
  "defaults": {
    "subagents": {
      "model": {
        "provider": "anthropic",
        "model": "claude-sonnet-4-6",
        "temperature": 0.7,
        "max_tokens": 8192
      },
      "thinking": "basic",
      "maxConcurrent": 5,
      "archiveAfterMinutes": 60
    }
  }
}
```

#### Agent级别Subagent配置
- ✅ `planner`: temperature=0.8, max_tokens=16384
- ✅ `writer`: temperature=0.9, max_tokens=16384
- ✅ `editor`: temperature=0.5, max_tokens=8192

这些配置覆盖默认设置，为不同Agent提供最适合的参数。

#### 工具策略配置 (`tools.subagents.tools`)
- ✅ 禁用了危险工具: `gateway`, `cron`

```json
"tools": {
  "subagents": {
    "tools": {
      "deny": ["gateway", "cron"]
    }
  }
}
```

#### 通信渠道绑定 (`bindings`)
- ✅ 只有入口Agent `ai-novel-agent` 绑定到通信渠道
- ✅ 支持CLI和飞书两种渠道

```json
"bindings": [
  {
    "agentId": "ai-novel-agent",
    "match": {"channel": "cli"}
  },
  {
    "agentId": "ai-novel-agent",
    "match": {"channel": "feishu", "accountId": "main"}
  }
]
```

### 2. 文档配置

#### AGENTS.md
- ✅ 定义了7个Agent的职责和调用场景
- ✅ 定义了任务路由规则
- ✅ **新增**: 调用方式选择指南（Subagent vs 直接通信）
- ✅ **新增**: 串行协作示例（使用sessions_spawn）
- ✅ **新增**: 并行协作示例（使用sessions_spawn）
- ✅ **新增**: 直接通信模式说明（使用sessions_send）

#### TOOLS.md
- ✅ **新增**: `sessions_spawn` 工具详细说明
- ✅ **新增**: 子智能体查询命令
- ✅ **更新**: `sessions_send` 工具说明，明确使用场景
- ✅ 包含文件操作、存储等工具说明

## 🎯 架构设计

### Agent调用流程

```
用户请求
    ↓
ai-novel-agent (Supervisor/入口)
    ↓
分析任务类型
    ↓
┌─────────────────┴─────────────────┐
│                                   │
 sessions_spawn()          sessions_send()
(Subagent模式)            (直接通信模式)
│                                   │
├─ planner          ├─ planner
├─ writer           ├─ writer
├─ editor           ├─ editor
├─ analyst          ├─ analyst
├─ operator         ├─ operator
└─ learner          └─ learner
│                                   │
异步通告返回                       同步返回
│                                   │
└─────────────────┬─────────────────┘
                  ↓
            返回用户
```

### Subagent模式优势

1. **并行执行**: 可同时启动多个子智能体
2. **独立会话**: 子智能体在独立会话中运行，避免干扰
3. **自动管理**: 完成后自动通告、自动归档
4. **资源控制**: 可限制并发数，避免资源耗尽
5. **模型优化**: 不同Agent使用不同temperature

### 直接通信模式适用场景

1. **多轮对话**: 需要与Agent进行实时交互
2. **上下文传递**: 需要传递完整会话历史
3. **Agent调用Agent**: 子Agent需要调用其他Agent

## 📖 使用示例

### 场景1: 创建新小说（串行）

```python
# Step 1: 启动Planner创建大纲
sessions_spawn({
  "agentId": "planner",
  "task": "创建修仙小说世界观和大纲",
  "label": "创建大纲"
})
# 等待Planner通告...

# Step 2: 根据大纲撰写章节
sessions_spawn({
  "agentId": "writer",
  "task": "根据大纲撰写第一章",
  "label": "撰写第1章"
})
# 等待Writer通告...

# Step 3: 审核内容
sessions_spawn({
  "agentId": "editor",
  "task": "审核第一章内容",
  "label": "审核第1章"
})
# 等待Editor通告...
```

### 场景2: 学习写作技巧（并行）

```python
# 同时启动多个分析任务
sessions_spawn({
  "agentId": "analyst",
  "task": "分析《诡秘之主》的节奏控制",
  "label": "分析诡秘节奏"
})

sessions_spawn({
  "agentId": "analyst",
  "task": "分析知乎热文的开篇技巧",
  "label": "分析开篇技巧"
})

sessions_spawn({
  "agentId": "learner",
  "task": "学习并整理写作技巧",
  "label": "学习技巧"
})

# 所有任务并行执行，完成后分别发送通告
```

### 场景3: 多轮协作（直接通信）

```python
# 与Writer进行多轮交互
sessions_send("writer", {
  "task": "撰写第三章打斗场面"
})

# 继续交流
sessions_send("writer", {
  "feedback": "动作描写不够细致，需要加强"
})

# 再次修改
sessions_send("writer", {
  "feedback": "很好，保持这个风格"
})
```

## 🔧 配置调优

### 调整并发数

根据系统性能调整子智能体并发数：

```json
"agents": {
  "defaults": {
    "subagents": {
      "maxConcurrent": 10  // 增加到10个
    }
  }
}
```

### 调整归档时间

根据任务时长调整自动归档：

```json
"agents": {
  "defaults": {
    "subagents": {
      "archiveAfterMinutes": 120  // 2小时后归档
    }
  }
}
```

### 调整思考级别

根据任务复杂度调整：

```json
"agents": {
  "defaults": {
    "subagents": {
      "thinking": "detailed"  // 更深入的思考
    }
  }
}
```

或针对单个Agent：

```python
sessions_spawn({
  "agentId": "writer",
  "task": "撰写复杂章节",
  "thinking": "detailed"  // 这次使用详细思考
})
```

## 📊 监控与管理

### 查看子智能体状态

```bash
# 列出所有子智能体
/subagents list

# 查看特定子智能体详情
/subagents info <runId>

# 查看子智能体日志
/subagents log <runId> [limit] [tools]

# 停止子智能体
/subagents kill <runId>
```

### 子智能体通告内容

子智能体完成后会发送通告，包含：

- **Status**: `success` | `error` | `timeout` | `unknown`
- **Result**: 任务结果摘要
- **Notes**: 错误详情或其他信息
- **Statistics**:
  - 运行时间 (如: `runtime 5m12s`)
  - Token使用量 (输入/输出/总计)
  - 估算成本
  - Session信息

## ⚠️ 注意事项

### Subagent限制

1. **无会话工具**: 子智能体默认无法调用 `sessions_list/sessions_send/sessions_spawn`
2. **上下文限制**: 只注入 `AGENTS.md` + `TOOLS.md`，无 `SOUL.md` 等
3. **不能嵌套**: 子智能体不能生成子智能体

### 允许列表

入口Agent只能调用 `allowAgents` 中列出的Agent：

```json
"subagents": {
  "allowAgents": ["planner", "writer", "editor", "analyst", "operator", "learner"]
}
```

如需调用其他Agent，需要添加到此列表。

### 成本控制

每个子智能体都有独立的token使用量：
- 复杂任务使用更便宜的模型
- 设置合理的 `max_tokens`
- 监控子智能体的成本

## 🚀 最佳实践

1. **优先使用 sessions_spawn**：除非需要多轮对话
2. **合理设置标签**：便于识别和管理子智能体
3. **控制并发数**：避免同时启动过多子智能体
4. **设置超时**：长时间任务设置 `runTimeoutSeconds`
5. **定期归档**：旧的子智能体会话自动清理
6. **监控成本**：使用 `/subagents info` 查看token使用

## 📚 参考文档

- [OpenClaw官方文档 - Subagents](https://docs.openclaw.ai/zh-CN/tools/subagents)
- [OpenClaw官方文档 - Configuration](https://docs.openclaw.ai/zh-CN/config)
- 项目文档: `CLAUDE.md`
