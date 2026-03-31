# Critic Agent 协作配置

## 可调用 Agent

无。Critic 是独立审计角色，不调用其他 Agent。

## 与其他 Agent 的关系

| 关系 | Agent | 说明 |
|------|-------|------|
| 被调用 | Supervisor (workspace-main) | 由 Supervisor 编排调用 |
| 输出消费者 | Planner (workspace-planner) | 审计报告由 Supervisor 转交给 Planner 修复 |
| 前置条件 | Planner | 需要 Planner 先完成世界观构建 |
| 互补关系 | Editor | Editor 审计写作质量，Critic 审计世界观设计质量 |

## 调用方式

Critic 仅通过 `sessions_spawn` 异步调用，不需要多轮交互。

```
调用: sessions_spawn("critic", {
  worldbuilding_files: ["novels/{项目}/outline/世界观设定.md", ...],
  audit_mode: "comprehensive" | "focused",
  project_preferences: {...},
  previous_report: {...}  // focused 模式时必需
})

返回: 审计报告（JSON格式）
```

## Skills

### social-structure-review
- **路径**: `skills/social-structure-review/SKILL.md`
- **说明**: 社会结构专项审计-修复循环。8 维度深度审计（SS1-SS8），支持 create/modify 双模式，最多 4 轮循环直到准出。由 Supervisor 按照技能规范编排执行。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 15 维度，仅在社会结构专项审计时激活。维度规范和准出标准详见 `skills/social-structure-review/reference/`。

### resource-system-review
- **路径**: `skills/resource-system-review/SKILL.md`
- **说明**: 资源体系专项审计-修复循环。8 维度深度审计（RS1-RS8），支持 create/modify 双模式，最多 4 轮循环。**特点**：RS8 维度要求跨文件数值一致性检查（社会结构、聚集地格局等），修复时需同步更新关联文件。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 15 维度，仅在资源体系专项审计时激活。维度规范和准出标准详见 `skills/resource-system-review/reference/`。

### race-faction-review
- **路径**: `skills/race-faction-review/SKILL.md`
- **说明**: 种族/势力设定专项审计-修复循环。8 维度深度审计（RF1-RF8），支持 create/modify 双模式，最多 4 轮循环。**通用性**：适用于任何小说类型中的种族、异族、势力、组织等设定。**特点**：灵活的文件检测机制（不绑定特定文件名），审计时传入关联世界观文件确保跨文件验证，支持 race_name 参数聚焦多种族文件中的特定目标。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 15 维度，仅在种族/势力专项审计时激活。维度规范和准出标准详见 `skills/race-faction-review/reference/`。
