# 多Agent协作模式

## 调用方式选择指南

本项目支持两种Agent调用方式，根据场景选择：

| 方式 | 工具 | 适用场景 | 特点 |
|------|------|----------|------|
| **Subagent模式** | `sessions_spawn` | 后台任务、并行处理、长时间运行 | 独立会话、异步通告、无会话工具 |
| **直接通信模式** | `sessions_send` | 串行协作、实时交互、需要上下文 | 共享会话、同步返回、完整工具 |

**推荐使用 `sessions_spawn` (Subagent模式)**：
- 更符合OpenClaw最佳实践
- 支持并行执行，提高效率
- 避免会话混乱
- 自动归档管理

**使用 `sessions_send` 的场景**：
- 需要实时交互对话
- 需要传递完整会话上下文
- 子Agent需要调用其他Agent

## 串行协作（Subagent模式）

当任务有明确依赖关系时：

```
用户 → ai-novel-agent
       ↓ sessions_spawn("planner")
       ↓ 等待通告
       ↓ sessions_spawn("writer", 传入planner结果)
       ↓ 等待通告
       ↓ sessions_spawn("editor", 传入writer结果)
       ↓ 等待通告
       → 返回用户
```

调用示例：
```python
# 1. 启动Planner子智能体
planner_result = sessions_spawn({
  "agentId": "planner",
  "task": "创建修仙小说大纲",
  "label": "创建大纲",
  "model": {
    "temperature": 0.8,
    "max_tokens": 16384
  }
})

# 2. 等待planner完成（通过通告返回结果）
# planner会自动发送通告，包含结果摘要

# 3. 启动Writer子智能体
writer_result = sessions_spawn({
  "agentId": "writer",
  "task": "根据大纲撰写第一章",
  "label": "撰写第1章",
  "model": {
    "temperature": 0.9,
    "max_tokens": 16384
  }
})
```

## 并行协作（Subagent模式）

当任务可以独立进行时：

```
用户 → ai-novel-agent
       ├─ sessions_spawn("analyst", 分析作品A) ─┐
       ├─ sessions_spawn("learner", 学习技巧B) ─┤
       └─ sessions_spawn("operator", 市场分析C) ─┘
                                                ↓
                                         汇总所有通告结果
                                                ↓
                                           → 返回用户
```

调用示例：
```python
# 同时启动多个子智能体
tasks = [
  sessions_spawn({
    "agentId": "analyst",
    "task": "分析《诡秘之主》",
    "label": "分析诡秘"
  }),
  sessions_spawn({
    "agentId": "learner",
    "task": "学习知乎写作技巧",
    "label": "学习技巧"
  }),
  sessions_spawn({
    "agentId": "operator",
    "task": "分析修仙小说市场趋势",
    "label": "市场分析"
  })
]

# 所有子智能体并行执行
# 通过runId可以查询状态
# 完成后会自动发送通告
```

## 直接通信模式（sessions_send）

适用于需要实时交互的场景：

```python
# 与Writer进行多轮对话
writer_session = sessions_send("writer", {
  "task": "撰写第一章",
  "outline":大纲内容
})

# 继续在Writer的会话中交流
writer_session = sessions_send("writer", {
  "feedback": "开头部分需要修改，要更吸引人"
})
```
