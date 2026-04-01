# Critic Agent 协作配置

## 可调用 Agent

无。Critic 是独立审计角色，不调用其他 Agent。

## 审计流程扩展：大纲结构审计

当 Critic 对**大纲文件**（卷大纲、总大纲）执行 `comprehensive_audit` 时，除了 TOOLS.md 中的 18 维度世界观审计，还须参考 Planner 的质量审计标准对大纲进行**结构审计**。

### 引用文件

- **路径**: `workspace-planner/skills/outline-creation/reference/quality-criteria.md`
- **激活条件**: 当审计输入包含 `outline/` 目录下的大纲文件时
- **适用维度**: A1-A11（重点启用 A9-A11，A1-A8 作为补充交叉验证）

### 大纲审计额外步骤

1. 读取 quality-criteria.md 中的 A9-A11 维度定义
2. 在世界观 18 维度审计之外，对大纲文件执行 A9-A11 结构检查：
   - **A9 卷级贯穿冲突线**：每卷是否有贯穿全卷的核心冲突线
   - **A10 跨卷情绪轨迹**：相邻卷情绪走向是否有逻辑过渡，无断裂式跳变
   - **A11 优势生命周期**：主角的暂时性优势是否有衰减/追赶机制
3. A9-A11 的审计结果作为独立 section 附录在审计报告中，格式与 TOOLS.md 维度一致（维度ID、得分、状态、问题详情）
4. A9-A11 的 critical/warning 计入总体收敛条件

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
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 18 维度，仅在社会结构专项审计时激活。维度规范和准出标准详见 `skills/social-structure-review/reference/`。

### resource-system-review
- **路径**: `skills/resource-system-review/SKILL.md`
- **说明**: 资源体系专项审计-修复循环。8 维度深度审计（RS1-RS8），支持 create/modify 双模式，最多 4 轮循环。**特点**：RS8 维度要求跨文件数值一致性检查（社会结构、聚集地格局等），修复时需同步更新关联文件。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 18 维度，仅在资源体系专项审计时激活。维度规范和准出标准详见 `skills/resource-system-review/reference/`。

### race-faction-review
- **路径**: `skills/race-faction-review/SKILL.md`
- **说明**: 种族/势力设定专项审计-修复循环。8 维度深度审计（RF1-RF8），支持 create/modify 双模式，最多 4 轮循环。**通用性**：适用于任何小说类型中的种族、异族、势力、组织等设定。**特点**：灵活的文件检测机制（不绑定特定文件名），审计时传入关联世界观文件确保跨文件验证，支持 race_name 参数聚焦多种族文件中的特定目标。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 18 维度，仅在种族/势力专项审计时激活。维度规范和准出标准详见 `skills/race-faction-review/reference/`。

### power-system-review
- **路径**: `skills/power-system-review/SKILL.md`
- **说明**: 力量/修炼体系专项审计-修复循环。8 维度深度审计（PS1-PS8），支持 create/modify 双模式，最多 4 轮循环。**通用性**：适用于修仙、奇幻魔法、末世觉醒、都市异能、科幻超能力等所有力量体系设定。**特点**：灵活的文件检测机制，审计时传入关联世界观文件确保跨文件验证（力量体系与社会结构/资源/种族高度耦合），支持 system_name 参数聚焦。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 18 维度，仅在力量体系专项审计时激活。维度规范和准出标准详见 `skills/power-system-review/reference/`。

### protagonist-review
- **路径**: `skills/protagonist-review/SKILL.md`
- **说明**: 主角设定专项审计-修复循环。8 维度深度审计（PC1-PC8：角色内核辨识度、金手指平衡性、弱点真实性、成长弧线、身世悬念、世界观耦合、关系网络、叙事驱动力），支持 create/modify 双模式，最多 4 轮循环。**通用性**：适用于末世、修仙、都市、玄幻、科幻等所有类型的主角设定。**特点**：关联文件收集策略（必传力量体系+社会结构，建议传大纲+资源体系），上下文预算 30000 token 防止溢出；与通用审计 B2（金手指合理性）建立升级关系。
- **注意**: 本技能的 8 维度审计体系独立于 TOOLS.md 中的通用 18 维度，仅在主角设定专项审计时激活。维度规范和准出标准详见 `skills/protagonist-review/reference/`。
