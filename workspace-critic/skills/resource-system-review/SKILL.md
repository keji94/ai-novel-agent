---
name: resource-system-review
description: "资源体系专项审计-修复循环。支持 create（从零设计）和 modify（审核现有）两种模式。8维度深度审计（RS1-RS8），最多4轮自动循环直到达到准出标准。由 Supervisor 按本协议编排执行。"
version: "1.0.0"
owner: workspace-critic
orchestrator: workspace-main
---

# 资源体系专项审计 Skill

## 概述

本 Skill 实现资源体系设定的质量闭环：设计（或修改）→ 审计 → 修复 → 再审计 → 循环直到准出。

与 social-structure-review Skill 并列，共享相同的工作流架构和收敛标准，但使用独立的 8 维度审计体系（41 个检查项）。

**执行者**：本 Skill 由 Supervisor（workspace-main）按以下协议编排执行。Critic 保持独立审计者身份。

---

## 触发条件

| 触发方式 | 示例 |
|----------|------|
| 用户显式请求 | "审核资源体系" / "检查资源设定" / "资源体系专项审计" |
| 通用审计升级 | 通用 15 维度审计中 C1（资源/经济体系）被评为 critical 时 |
| Supervisor 判断 | 在世界观构建流程中需要深度审计资源体系 |

---

## 两种模式

### create 模式

资源体系文件不存在时触发。流程：Planner 生成初稿 → 审计-修复循环。

### modify 模式

资源体系文件已存在时触发。流程：直接进入审计-修复循环。

---

## 审计-修复循环

工作流与 social-structure-review 完全一致，替换维度规范路径即可：

```
dimension_spec: "workspace-critic/skills/resource-system-review/reference/dimensions.md"
convergence_spec: "workspace-critic/skills/resource-system-review/reference/convergence-criteria.md"
target_file: "outline/世界观设定-资源体系.md"
```

### 跨文件联动（RS8 专项）

资源体系审计的特殊之处：RS8（跨文件数值一致性）要求在 focused 审计中同步检查关联文件：

```
RS8 关联文件:
  - outline/世界观设定-社会结构.md
  - outline/世界观设定-聚集地格局.md
  - outline/世界观设定-总览.md
  - outline/世界观设定-古物共鸣体系.md（共鸣者数量相关）
```

修复资源数据后，planner 必须检查这些文件是否需要同步更新，并在修复说明中列出跨文件变更。

---

## 输入

```json
{
  "project_path": "novels/{项目名}",
  "mode": "create | modify",
  "user_preferences": {
    "worldbuilding_preferences": {},
    "resource_focus": ["RS2", "RS4"],
    "accepted_flaws": [],
    "critic_overrides": {}
  },
  "cross_file_check": ["世界观设定-社会结构.md", "世界观设定-聚集地格局.md"]
}
```

---

## 输出

审计报告 JSON Schema 与 social-structure-review 格式一致，维度前缀从 SS 替换为 RS。

---

## 关键参数速查

| 参数 | 值 |
|------|---|
| 审计维度 | 8（RS1-RS8） |
| 满分 | 80 |
| 收敛条件 | critical=0 AND warning≤2 AND avg≥7.0 AND min≥4 |
| 最大轮次 | 4 |
| 跨文件联动 | RS8 专项：修复后同步检查社会结构、聚集地格局等文件 |
| 维度规范 | `reference/dimensions.md` |
| 准出标准 | `reference/convergence-criteria.md` |
