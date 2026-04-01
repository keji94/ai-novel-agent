---
name: race-faction-review
description: "种族/势力设定专项审计-修复循环。支持 create（从零设计）和 modify（审核现有）两种模式。8维度深度审计（RF1-RF8），最多4轮自动循环直到达到准出标准。适用于任何小说类型中的种族、异族、势力、组织等设定。由 Supervisor 按本协议编排执行。"
version: "1.0.0"
owner: workspace-critic
orchestrator: workspace-main
---

# 种族/势力设定专项审计 Skill

## 概述

本 Skill 实现种族/势力设定的质量闭环：设计（或修改）→ 审计 → 修复 → 再审计 → 循环直到准出。

**通用性**：本 Skill 适用于任何小说类型：
- 奇幻：精灵、矮人、兽人、龙族等
- 科幻/末世：异族、变异体、AI 集体意识等
- 都市/历史：门派、帮会、秘密组织、政治势力等
- 任何具有集体身份和独立行为的群体设定

**执行者**：本 Skill 由 Supervisor（workspace-main）按以下协议编排执行。Critic 保持独立审计者身份，不直接调用其他 Agent。

---

## 触发条件

| 触发方式 | 示例 |
|----------|------|
| 用户显式请求 | "审核异族设定" / "检查XX种族设计" / "种族设定专项审计" / "设计XX势力" |
| 通用审计 B3 升级 | 通用 18 维度审计中 B3（敌人行为逻辑）被评为 critical 时，建议升级为本 Skill |
| Supervisor 判断 | 在世界观构建流程中需要深度审计某个种族/势力 |

---

## 两种模式

### create 模式

种族/势力设定文件不存在时触发。流程：Planner 生成初稿 → 审计-修复循环。

```
判定: 目标种族/势力文件不存在
  → Supervisor 调用 Planner (mode: race_faction_draft) 生成初稿
  → 进入审计-修复循环
```

### modify 模式

种族/势力设定文件已存在时触发。流程：直接进入审计-修复循环。

```
判定: 目标种族/势力文件存在
  → 直接进入审计-修复循环
```

---

## 目标文件检测

本 Skill 不绑定特定文件名，通过以下优先级检测目标文件：

```
检测优先级:
  1. 用户显式指定 target_file → 使用指定文件
  2. 用户指定 race_name → 搜索 outline/ 下包含该名称的文件
  3. Glob 匹配:
     - outline/世界观设定-*族*.md
     - outline/世界观设定-*势力*.md
     - outline/世界观设定-*敌*.md
     - outline/世界观设定-*种族*.md
  4. 无匹配 → 进入 create 模式
```

---

## 审计-修复循环

### 循环工作流

```
FUNCTION race_faction_review(project_path, user_request):

  // Phase 1: 目标文件检测
  race_name = user_request.race_name || extract_from(user_request)
  target_file = detect_target_file(project_path, race_name, user_request.target_file)

  IF target_file:
    mode = "modify"
  ELSE:
    mode = "create"

  // Phase 2: create 模式 — 生成初稿
  IF mode == "create":
    other_worldbuilding = glob(project_path + "/outline/世界观设定*.md")
      .filter(f => f NOT contains race_name)

    planner_result = sessions_spawn("planner", {
      mode: "race_faction_draft",
      project: project_path,
      genre: read(project_path + "/project.json").genre,
      race_name: race_name,
      existing_worldbuilding: other_worldbuilding,
      user_preferences: read(project_path + "/project.json").worldbuilding_preferences
    })

    target_file = planner_result.output_file

  // Phase 3: 收集关联世界观文件（跨文件上下文）
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
      skill_context: "race-faction-review",
      dimension_spec: "workspace-critic/skills/race-faction-review/reference/dimensions.md",
      convergence_spec: "workspace-critic/skills/race-faction-review/reference/convergence-criteria.md",
      previous_report: (round > 1) ? last_report : null,
      race_name: race_name,
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

    // 4d: 修复（传入完整世界观上下文，避免修复引入跨文件矛盾）
    fix_result = sessions_spawn("planner", {
      mode: "worldbuilding_fix",
      audit_report: audit_report,
      target_scope: "race_faction",
      race_name: race_name,
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
| Critic spawn | `worldbuilding_files` = [目标文件] + [关联世界观文件] | Critic 能做跨文件验证（如种族设定的实力等级是否与世界天花板一致） |
| Critic spawn | `previous_report`（Round 2+） | 聚焦上轮问题，避免重复扫描 |
| Critic spawn | `race_name` | 明确审计焦点，当文件包含多个种族时定位目标 |
| Planner spawn | `existing_worldbuilding` = [全部世界观文件] | 修复时不与其他设定冲突 |
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
  "race_name": "异族 / XX势力（可选，用于聚焦审计范围）",
  "target_file": "outline/具体文件名.md（可选，默认自动检测）",
  "mode": "create | modify（可选，默认根据文件是否存在自动判断）",
  "user_preferences": {
    "worldbuilding_preferences": {},
    "race_faction_focus": ["RF4", "RF5"],
    "accepted_flaws": ["RF4-3"],
    "critic_overrides": {}
  }
}
```

| 参数 | 说明 |
|------|------|
| project_path | 项目路径 |
| race_name | 种族/势力名称，用于定位文件和聚焦审计 |
| target_file | 直接指定目标文件路径，覆盖自动检测 |
| mode | 可选覆盖，默认根据文件是否存在自动判断 |
| race_faction_focus | 用户指定重点关注的维度（可选） |
| accepted_flaws | 用户已接受的已知缺陷，降级显示 |
| critic_overrides | 用户对维度的覆盖规则（可选） |

---

## 输出

### 审计报告 JSON Schema

```json
{
  "audit_summary": {
    "project": "项目名",
    "skill": "race-faction-review",
    "race_name": "异族",
    "mode": "create | modify",
    "round": 1,
    "total_score": 62,
    "max_score": 80,
    "grade": "C",
    "critical_count": 1,
    "warning_count": 4,
    "suggestion_count": 3,
    "converged": false,
    "average_score": 7.75,
    "min_dimension_score": 4
  },
  "dimension_scores": {
    "RF1": {"score": 8, "status": "pass", "note": "本质定义清晰，'文明黑洞'概念独特"},
    "RF2": {"score": 7, "status": "pass", "note": "牧场策略动机合理，但缺少长期目标演变的弹性"},
    "RF3": {"score": 4, "status": "critical", "note": "血裔族内部铁板一块，缺少派系张力和分歧"},
    "RF4": {"score": 5, "status": "warning", "note": "血裔族外形是陈旧吸血鬼模板，与'文明黑洞'本质断裂"},
    "RF5": {"score": 6, "status": "pass", "note": "战略时间线基本合理，但王座全知全能缺少盲点"},
    "RF6": {"score": 7, "status": "pass", "note": "与古物共鸣的克制关系明确"},
    "RF7": {"score": 6, "status": "pass", "note": "四种族分工明确但过于功能化"},
    "RF8": {"score": 9, "status": "pass", "note": "隐藏维度丰富，内部矛盾线索多，独立故事价值强"}
  },
  "issues": [
    {
      "id": "RF3-C001",
      "dimension": "RF3",
      "severity": "critical",
      "title": "血裔族内部无派系张力",
      "location": "异族设定.md#血裔族",
      "description": "王座铁板一块执行120年战略，无内部分歧。高智商种族不可能在长期战略上完全一致——至少应有'直接吞噬派'vs'可持续牧场派'的路线之争。",
      "fix_direction": "补充血裔族内部派系（如：牧场派王座 vs 贪婪派少壮），或引入异界另一股势力与王座博弈",
      "effort": "medium"
    }
  ],
  "highlights": [
    {
      "dimension": "RF2",
      "title": "文明牧场概念设计精巧",
      "description": "将异族目标从'消灭人类'换成'圈养收割文明记忆'，一举解释了围而不攻、留活口等行为模式"
    }
  ],
  "trend": {
    "previous_total": null,
    "current_total": 62,
    "delta": null,
    "direction": null,
    "issues_resolved": 0,
    "issues_new": 8
  }
}
```

### 最终报告（收敛后）

```markdown
# 种族/势力设定专项审计 — 通过

评分趋势: R1(52) → R2(61) → R3(67) → R4(71)
最终评级: B（71/80，0 critical，2 warning）

## 亮点保留
✅ 文明牧场概念 — 从始至终保持，未因修复受损
✅ 失控灾难 vs 战略行为区分 — 纪元1-5年失控设定为异族增加了真实感

## 修复记录
- R1→R2: 修复了血裔族内部派系(RF3)、补充了核心概念机制(RF1)
- R2→R3: 强化了异质感设计(RF4)、补充了战略盲点(RF5)
- R3→R4: 修复了封锁线完美度问题(RF7)、优化了子类型差异化(RF3)

## 遗留 Warning（已接受）
- [W-003] RF4 外在形象独特性可进一步深化（当前够用）
- [W-006] RF7 跨势力关系的非对称性可在后续展开（当前框架足够）
```

---

## 关键参数速查

| 参数 | 值 |
|------|---|
| 审计维度 | 8（RF1-RF8），详见 `reference/dimensions.md` |
| 满分 | 80 |
| 收敛条件 | critical=0 AND warning≤2 AND avg≥7.0 AND min≥4 |
| 最大轮次 | 4 |
| 首轮模式 | comprehensive |
| 后续轮模式 | focused |
| 修复 Agent | planner (mode: worldbuilding_fix) |
| 修复范围 | target_scope: "race_faction" |
| 目标文件检测 | 用户指定 > race_name 搜索 > Glob 匹配 > create 模式 |
| 维度规范 | `reference/dimensions.md` |
| 准出标准 | `reference/convergence-criteria.md` |

---

## 与通用 Fix Loop 的集成

本 Skill 可独立运行，也可嵌入通用世界观构建流程（规则 1）：

1. **独立触发**：用户直接请求"审核XX种族设定"
2. **前置深度审计**：在规则 1 Phase 3（通用审计）之前，先运行本 Skill 做种族/势力专项审计
3. **B3 升级触发**：通用审计中 B3 评为 critical 时，自动升级为本 Skill

无论哪种触发方式，本 Skill 的审计结果不影响通用 18 维度审计的独立运行。两者是互补关系。
