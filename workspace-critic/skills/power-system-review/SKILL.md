---
name: power-system-review
description: "力量/修炼体系专项审计-修复循环。支持 create（从零设计）和 modify（审核现有）两种模式。8维度深度审计（PS1-PS8），最多4轮自动循环直到达到准出标准。适用于修仙、奇幻魔法、末世觉醒、都市异能、科幻超能力等所有力量体系设定。由 Supervisor 按本协议编排执行。"
version: "1.0.0"
owner: workspace-critic
orchestrator: workspace-main
---

# 力量/修炼体系专项审计 Skill

## 概述

本 Skill 实现力量/修炼体系设定的质量闭环：设计（或修改）→ 审计 → 修复 → 再审计 → 循环直到准出。

**通用性**：本 Skill 适用于任何小说类型：
- 修仙/武侠：功法境界、经脉内力
- 奇幻/魔法：元素魔法、符文体系
- 末世/觉醒：异能觉醒、变异进化
- 都市/异能：超能力、精神力
- 科幻/超人类：基因改造、纳米增强

**执行者**：本 Skill 由 Supervisor（workspace-main）按以下协议编排执行。Critic 保持独立审计者身份，不直接调用其他 Agent。

---

## 触发条件

| 触发方式 | 示例 |
|----------|------|
| 用户显式请求 | "审核古物共鸣体系" / "检查修炼设定" / "力量体系专项审计" / "设计魔法系统" |
| 通用审计 B1 升级 | 通用 18 维度审计中 B1（力量体系独特性）被评为 critical 时，建议升级为本 Skill |
| Supervisor 判断 | 在世界观构建流程中需要深度审计力量体系 |
| Phase 3.5 自动触发 | 新书创建流程中，检测到力量体系文件或通用审计 B1 为 critical |

---

## 两种模式

### create 模式

力量体系文件不存在时触发。流程：Planner 生成初稿 → 审计-修复循环。

### modify 模式

力量体系文件已存在时触发。流程：直接进入审计-修复循环。

---

## 目标文件检测

```
检测优先级:
  1. 用户显式指定 target_file → 使用指定文件
  2. 用户指定 system_name → 搜索 outline/ 下包含该名称的文件
  3. Glob 匹配:
     - outline/世界观设定-*修炼*.md
     - outline/世界观设定-*力量*.md
     - outline/世界观设定-*功法*.md
     - outline/世界观设定-*共鸣*.md
     - outline/世界观设定-*魔法*.md
     - outline/世界观设定-*能力*.md
     - outline/世界观设定-*灵力*.md
  4. 无匹配 → 进入 create 模式
```

---

## 审计-修复循环

### 循环工作流

```
FUNCTION power_system_review(project_path, user_request):

  // Phase 1: 目标文件检测
  system_name = user_request.system_name || extract_from(user_request)
  target_file = detect_target_file(project_path, system_name, user_request.target_file)

  IF target_file:
    mode = "modify"
  ELSE:
    mode = "create"

  // Phase 2: create 模式 — 生成初稿
  IF mode == "create":
    other_worldbuilding = glob(project_path + "/outline/世界观设定*.md")
      .filter(f => f NOT contains system_name)

    planner_result = sessions_spawn("planner", {
      mode: "power_system_draft",
      project: project_path,
      genre: read(project_path + "/project.json").genre,
      system_name: system_name,
      existing_worldbuilding: other_worldbuilding,
      user_preferences: read(project_path + "/project.json").worldbuilding_preferences
    })

    target_file = planner_result.output_file

  // Phase 3: 收集关联世界观文件
  related_files = glob(project_path + "/outline/世界观设定*.md")
    .filter(f => f != target_file)

  // Phase 4: 审计-修复循环（最多4轮）
  round = 1
  max_rounds = 4
  last_report = null
  converged = false
  score_history = []

  WHILE round <= max_rounds AND NOT converged:

    // 4a: 审计
    IF round == 1:
      audit_mode = "comprehensive"
    ELSE:
      audit_mode = "focused"

    audit_report = sessions_spawn("critic", {
      worldbuilding_files: [target_file] + related_files,
      audit_mode: audit_mode,
      skill_context: "power-system-review",
      dimension_spec: "workspace-critic/skills/power-system-review/reference/dimensions.md",
      convergence_spec: "workspace-critic/skills/power-system-review/reference/convergence-criteria.md",
      previous_report: (round > 1) ? last_report : null,
      system_name: system_name,
      project_preferences: read(project_path + "/project.json").worldbuilding_preferences
    })

    // 4b: 检查收敛
    score_history.append(audit_report.audit_summary.total_score)
    converged = (
      audit_report.audit_summary.critical_count == 0
      AND audit_report.audit_summary.warning_count <= 2
      AND (audit_report.audit_summary.total_score / 8.0) >= 7.0
      AND min(dimension_scores.values().score) >= 4
    )

    IF converged:
      BREAK

    // 4c: 趋势判断
    IF round >= 2 AND audit_report.trend.direction == "stagnant":
      present_stagnation_warning(audit_report)

    // 4d: 修复（传入完整世界观上下文）
    fix_result = sessions_spawn("planner", {
      mode: "worldbuilding_fix",
      audit_report: audit_report,
      target_scope: "power_system",
      system_name: system_name,
      existing_worldbuilding: glob(project_path + "/outline/世界观设定*.md")
    })

    last_report = audit_report
    round += 1

  // Phase 5: 结果处理
  IF converged:
    RETURN success_summary(audit_report, score_history)
  ELSE:
    present_user_checkpoint(audit_report, score_history)
    user_choice = await_user_input()

    SWITCH user_choice:
      CASE "approve_as_is":
        update_project_preferences(accepted_flaws: audit_report.issues)
        RETURN approved_with_notes(audit_report)
      CASE "targeted_fix":
        extra_report = sessions_spawn("critic", {
          audit_mode: "focused",
          focus_dimensions: user_choice.dimensions,
          ...
        })
        RETURN final_result(extra_report)
      CASE "restart":
        GOTO Phase 2 WITH lessons_learned = audit_report
```

### 上下文管理要点

| 环节 | 上下文传递 | 设计意图 |
|------|-----------|---------|
| Critic spawn | `worldbuilding_files` = [目标文件] + [关联世界观文件] | 力量体系与社会结构/资源/种族等设定高度耦合，需要跨文件验证 |
| Critic spawn | `previous_report`（Round 2+） | 聚焦上轮问题，避免重复扫描 |
| Critic spawn | `system_name` | 当文件包含多个体系时定位审计目标 |
| Planner spawn | `existing_worldbuilding` = [全部世界观文件] | 力量体系的修改最容易引发连锁反应（等级→社会阶层→经济→种族平衡） |
| Planner spawn | `audit_report` = 本轮完整报告 | 精确知道需要修复什么 |
| Supervisor 侧 | `score_history` + `round` + `converged` | 循环状态由 Supervisor 维护，Agent 无状态累积 |

### 收敛条件

```
converged = (
  critical_count == 0
  AND warning_count <= 2
  AND average_score >= 7.0
  AND min_dimension_score >= 4
)
```

详细评分和评级规则见 `reference/convergence-criteria.md`。

---

## 输入

```json
{
  "project_path": "novels/{项目名}",
  "system_name": "古物共鸣 / 修仙体系（可选，用于聚焦审计范围）",
  "target_file": "outline/具体文件名.md（可选，默认自动检测）",
  "mode": "create | modify（可选，默认自动判断）",
  "user_preferences": {
    "worldbuilding_preferences": {},
    "power_system_focus": ["PS3", "PS5"],
    "accepted_flaws": ["PS4-2"],
    "critic_overrides": {}
  }
}
```

---

## 输出

### 审计报告 JSON Schema

```json
{
  "audit_summary": {
    "project": "项目名",
    "skill": "power-system-review",
    "system_name": "古物共鸣",
    "mode": "modify",
    "round": 1,
    "total_score": 62,
    "max_score": 80,
    "grade": "C",
    "critical_count": 2,
    "warning_count": 2,
    "suggestion_count": 2,
    "converged": false,
    "average_score": 7.75,
    "min_dimension_score": 4
  },
  "dimension_scores": {
    "PS1": {"score": 9, "status": "pass", "note": "音叉隐喻贯穿五步过程，核心规则清晰且自洽"},
    "PS2": {"score": 8, "status": "pass", "note": "七阶等级定义清晰，成长条件明确"},
    "PS3": {"score": 4, "status": "critical", "note": "核心规则部分缺少代价条款，精神侵蚀仅在发现史中提及"},
    "PS4": {"score": 5, "status": "warning", "note": "音叉隐喻独特但数据过度精确（末世不应有~40%统计）"},
    "PS5": {"score": 7, "status": "pass", "note": "信息质量碾压逻辑精巧，但现代科学激活第二回响的解释偏薄"},
    "PS6": {"score": 8, "status": "pass", "note": "四回响类型+五共鸣类型+四流派支撑丰富场景"},
    "PS7": {"score": 8, "status": "pass", "note": "天赋差异的社会影响设计深入（血统论、分工固化、生产型低估）"},
    "PS8": {"score": 3, "status": "critical", "note": "六阶造化者挑战'文明记忆'定义，七阶突然引入血裔血脉但无铺垫"}
  },
  "issues": [...],
  "highlights": [...],
  "trend": {...}
}
```

---

## 关键参数速查

| 参数 | 值 |
|------|---|
| 审计维度 | 8（PS1-PS8），详见 `reference/dimensions.md` |
| 满分 | 80 |
| 收敛条件 | critical=0 AND warning≤2 AND avg≥7.0 AND min≥4 |
| 最大轮次 | 4 |
| 首轮模式 | comprehensive |
| 后续轮模式 | focused |
| 修复 Agent | planner (mode: worldbuilding_fix) |
| 修复范围 | target_scope: "power_system" |
| 目标文件检测 | 用户指定 > system_name 搜索 > Glob 匹配 > create 模式 |
| 维度规范 | `reference/dimensions.md` |
| 准出标准 | `reference/convergence-criteria.md` |

---

## 与通用 Fix Loop 的集成

本 Skill 可独立运行，也可嵌入通用世界观构建流程（规则 1）：

1. **独立触发**：用户直接请求"审核XX力量体系"
2. **Phase 3.5 自动触发**：新书创建流程中，检测到力量体系文件或 B1 为 critical 时自动触发
3. **B1 升级触发**：通用审计中 B1 评为 critical 时，自动升级为本 Skill

无论哪种触发方式，本 Skill 的审计结果不影响通用 18 维度审计的独立运行。两者是互补关系。
