---
name: social-structure-review
description: "社会结构专项审计-修复循环。支持 create（从零设计）和 modify（审核现有）两种模式。8维度深度审计，最多4轮自动循环直到达到准出标准。由 Supervisor 按本协议编排执行。"
version: "1.0.0"
owner: workspace-critic
orchestrator: workspace-main
---

# 社会结构专项审计 Skill

## 概述

本 Skill 实现社会结构设定的质量闭环：设计（或修改）→ 审计 → 修复 → 再审计 → 循环直到准出。

与通用 18 维度审计的区别：本 Skill 聚焦社会结构单文件，使用独立的 8 维度审计体系（43 个检查项），准出标准更严格。

**执行者**：本 Skill 由 Supervisor（workspace-main）按以下协议编排执行。Critic 保持独立审计者身份，不直接调用其他 Agent。

---

## 触发条件

| 触发方式 | 示例 |
|----------|------|
| 用户显式请求 | "审核社会结构" / "检查势力设定" / "社会结构专项审计" |
| 通用审计 C2 升级 | 通用 18 维度审计中 C2（社会结构合理性）被评为 critical 时，建议升级为本 Skill |
| Supervisor 判断 | 在世界观构建流程中，Supervisor 判断社会结构需要深度审计 |

---

## 两种模式

### create 模式

社会结构文件不存在时触发。流程：Planner 生成初稿 → 审计-修复循环。

```
判定: outline/世界观设定-社会结构.md 不存在
  → Supervisor 调用 Planner Mode 5 (social_structure_draft) 生成初稿
  → 进入审计-修复循环
```

### modify 模式

社会结构文件已存在时触发。流程：直接进入审计-修复循环。

```
判定: outline/世界观设定-社会结构.md 存在
  → 直接进入审计-修复循环
```

---

## 审计-修复循环

### 循环工作流

```
FUNCTION social_structure_review(project_path, user_request):

  // Phase 1: 模式判断
  social_file = project_path + "/outline/世界观设定-社会结构.md"
  IF file_exists(social_file):
    mode = "modify"
  ELSE:
    mode = "create"

  // Phase 2: create 模式 — 生成初稿
  IF mode == "create":
    other_worldbuilding = glob(project_path + "/outline/世界观设定*.md")
      .filter(f => f NOT contains "社会结构")

    planner_result = sessions_spawn("planner", {
      mode: "social_structure_draft",
      project: project_path,
      genre: read(project_path + "/project.json").genre,
      existing_worldbuilding: other_worldbuilding,
      user_preferences: read(project_path + "/project.json").worldbuilding_preferences
    })

    social_file = planner_result.output_file
    // 验证文件已生成，否则报告错误

  // Phase 3: 审计-修复循环（最多4轮）
  round = 1
  max_rounds = 4
  last_report = null
  converged = false
  score_history = []

  WHILE round <= max_rounds AND NOT converged:

    // 3a: 审计
    IF round == 1:
      audit_mode = "comprehensive"
    ELSE:
      audit_mode = "focused"

    audit_report = sessions_spawn("critic", {
      worldbuilding_files: [social_file],
      audit_mode: audit_mode,
      skill_context: "social-structure-review",
      dimension_spec: "workspace-critic/skills/social-structure-review/reference/dimensions.md",
      convergence_spec: "workspace-critic/skills/social-structure-review/reference/convergence-criteria.md",
      previous_report: (round > 1) ? last_report : null,
      project_preferences: read(project_path + "/project.json").worldbuilding_preferences
    })

    // 3b: 检查收敛
    score_history.append(audit_report.audit_summary.total_score)
    converged = (
      audit_report.audit_summary.critical_count == 0
      AND audit_report.audit_summary.warning_count <= 2
      AND (audit_report.audit_summary.total_score / 8.0) >= 7.0
      AND min(dimension_scores.values().score) >= 4
    )

    IF converged:
      BREAK

    // 3c: 趋势判断
    IF round >= 2 AND audit_report.trend.direction == "stagnant":
      // 修复进入平台期，提示用户介入
      present_stagnation_warning(audit_report)
      // 继续循环，但用户可选择提前介入

    // 3d: 修复
    fix_result = sessions_spawn("planner", {
      mode: "worldbuilding_fix",
      audit_report: audit_report,
      target_scope: "social_structure"
    })

    last_report = audit_report
    round += 1

  // Phase 4: 结果处理
  IF converged:
    RETURN success_summary(audit_report, score_history)
  ELSE:
    // 用户检查点
    present_user_checkpoint(audit_report, score_history)
    user_choice = await_user_input()

    SWITCH user_choice:
      CASE "approve_as_is":
        // 记录 accepted_flaws
        update_project_preferences(accepted_flaws: audit_report.issues)
        RETURN approved_with_notes(audit_report)
      CASE "targeted_fix":
        // 用户指定维度，再执行 1 轮 focused 审计
        extra_report = sessions_spawn("critic", {
          audit_mode: "focused",
          focus_dimensions: user_choice.dimensions,
          ...
        })
        RETURN final_result(extra_report)
      CASE "restart":
        // 重新设计，将本次审计作为经验教训
        GOTO Phase 2 WITH lessons_learned = audit_report
```

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
  "mode": "create | modify（可选，默认自动判断）",
  "user_preferences": {
    "worldbuilding_preferences": {},
    "social_structure_focus": ["SS4", "SS5"],
    "accepted_flaws": ["SS3-2"],
    "critic_overrides": {}
  }
}
```

| 参数 | 说明 |
|------|------|
| project_path | 项目路径 |
| mode | 可选覆盖，默认根据文件是否存在自动判断 |
| social_structure_focus | 用户指定重点关注的维度（可选） |
| accepted_flaws | 用户已接受的已知缺陷，降级显示 |
| critic_overrides | 用户对维度的覆盖规则（可选） |

---

## 输出

### 审计报告 JSON Schema

```json
{
  "audit_summary": {
    "project": "项目名",
    "skill": "social-structure-review",
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
    "SS1": {"score": 8, "status": "pass", "note": "权力结构逻辑通顺，觉醒者悖论设计精巧"},
    "SS2": {"score": 5, "status": "warning", "note": "经济可持续性有基本描述，但三环内外经济纽带缺失"},
    "SS3": {"score": 4, "status": "critical", "note": "拾荒者15-25万人无组织结构描述，商会/教派内部结构过薄"},
    "SS4": {"score": 7, "status": "pass", "note": "势力间关系基本合理，但交叉依赖需加强"},
    "SS5": {"score": 6, "status": "pass", "note": "公会和世家动机清晰，商会和教派动机模糊"},
    "SS6": {"score": 7, "status": "pass", "note": "三环结构+三锁体系设计扎实，阶层流动通道明确"},
    "SS7": {"score": 7, "status": "pass", "note": "知识垄断和信息管控设计好，鉴心堂信任真空有创意"},
    "SS8": {"score": 8, "status": "pass", "note": "拾荒者起点+信任真空+知识碾压，切入角度多且好"}
  },
  "issues": [
    {
      "id": "SS3-C001",
      "dimension": "SS3",
      "severity": "critical",
      "title": "拾荒者内部组织完全缺失",
      "location": "世界观设定-社会结构.md#拾荒者",
      "description": "三环外有15-25万拾荒者，但设定只给了两句话描述。在末世废墟中，无组织的拾荒者活不过三天。缺少：组织形态（头人制/帮派）、与内城的交易机制、内部资源争夺规则。",
      "fix_direction": "补充拾荒者的组织形态（建议：松散联盟+头人制）、与内城的灰色交易渠道、内部地盘划分规则",
      "effort": "medium"
    }
  ],
  "highlights": [
    {
      "dimension": "SS1",
      "title": "觉醒者悖论设计精巧",
      "description": "需要觉醒者维持生存又害怕觉醒者动摇统治，这个根本性矛盾是自洽的、动态的、越挣扎越紧的绞索，能支撑前100万字的内部政治线"
    },
    {
      "dimension": "SS6",
      "title": "三锁体系闭环精密",
      "description": "接触锁控制谁能觉醒、压力锁控制觉醒率、知识锁控制觉醒上限，三道锁从不同维度闭环，且每一道锁都自然解释了社会现象"
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
# 社会结构专项审计 — 通过

评分趋势: R1(52) → R2(61) → R3(67) → R4(71)
最终评级: B（71/80，0 critical，2 warning）

## 亮点保留
✅ 觉醒者悖论 — 从始至终保持，未因修复受损
✅ 三锁体系 — 结构完整，未引入矛盾

## 修复记录
- R1→R2: 修复了拾荒者组织结构(SS3)、补充了经济纽带(SS2)
- R2→R3: 强化了势力间交叉依赖(SS4)、明确了商会动机(SS5)
- R3→R4: 修复了信息泄露渠道(SS7)、优化了主角嵌入点(SS8)

## 遗留 Warning（已接受）
- [W-003] SS2 三环内外经济纽带细节可进一步丰富（当前够用）
- [W-006] SS5 教派内部动态可在后续章节中展开（当前框架足够）
```

---

## 关键参数速查

| 参数 | 值 |
|------|---|
| 审计维度 | 8（SS1-SS8），详见 `reference/dimensions.md` |
| 满分 | 80 |
| 收敛条件 | critical=0 AND warning≤2 AND avg≥7.0 AND min≥4 |
| 最大轮次 | 4 |
| 首轮模式 | comprehensive |
| 后续轮模式 | focused |
| 修复 Agent | planner (mode: worldbuilding_fix) |
| 修复范围 | target_scope: "social_structure" |
| 维度规范 | `reference/dimensions.md` |
| 准出标准 | `reference/convergence-criteria.md` |

---

## 与通用 Fix Loop 的集成

本 Skill 可独立运行，也可嵌入通用世界观构建流程（规则 1）：

1. **独立触发**：用户直接请求"审核社会结构"
2. **前置深度审计**：在规则 1 Phase 3（通用审计）之前，先运行本 Skill 做社会结构专项审计，提前发现问题
3. **C2 升级触发**：通用审计中 C2 评为 critical 时，自动升级为本 Skill

无论哪种触发方式，本 Skill 的审计结果不影响通用 18 维度审计的独立运行。两者是互补关系。
