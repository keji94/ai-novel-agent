---
name: protagonist-review
description: "主角设定专项审计-修复循环。支持 create（从零设计主角）和 modify（审核现有）两种模式。8维度深度审计（PC1-PC8），最多4轮自动循环直到达到准出标准。适用于末世、修仙、都市、玄幻、科幻等所有类型的主角设定。由 Supervisor 按本协议编排执行。"
version: "1.0.0"
owner: workspace-critic
orchestrator: workspace-main
---

# 主角设定专项审计 Skill

## 概述

本 Skill 实现主角设定的质量闭环：设计（或修改）→ 审计 → 修复 → 再审计 → 循环直到准出。

**通用性**：本 Skill 适用于任何小说类型的主角设定：
- 末世/废土：觉醒者、穿越者、幸存者
- 修仙/玄幻：废材逆袭、天才陨落、转世重修
- 都市/异能：普通人获得超能力、隐藏身份回归
- 科幻/末日后：基因改造、意识上传、星际流亡
- 历史/架空：重生者、穿越者、宿命之子

**为什么需要专项审计**：主角设定是全书的锚点。主角有问题，全书都有问题。通用15维度审计中的 B2（金手指合理性）只覆盖一小块，但主角设定的问题远不止金手指——角色内核、成长弧线、身世悬念、世界观融合、关系生态、叙事驱动力，每一块出问题都会拖垮整本书。

**执行者**：本 Skill 由 Supervisor（workspace-main）按以下协议编排执行。Critic 保持独立审计者身份，不直接调用其他 Agent。

---

## 触发条件

| 触发方式 | 示例 |
|----------|------|
| 用户显式请求 | "审核主角设定" / "检查苏辰的人设" / "主角设定专项审计" / "设计主角" |
| 通用审计 B2 升级 | 通用 15 维度审计中 B2（金手指合理性）被评为 critical 时，建议升级为本 Skill |
| Supervisor 判断 | 在世界观构建流程中需要深度审计主角设定 |
| Phase 3.5 自动触发 | 新书创建流程中，检测到主角设定文件或通用审计 B2 为 critical |

---

## 两种模式

### create 模式

主角设定文件不存在时触发。流程：Planner 生成初稿 → 审计-修复循环。

### modify 模式

主角设定文件已存在时触发。流程：直接进入审计-修复循环。

---

## 目标文件检测

```
检测优先级:
  1. 用户显式指定 target_file → 使用指定文件
  2. 用户指定 protagonist_name → 搜索 outline/ 下包含该名称的文件
  3. Glob 匹配:
     - outline/主角设定.md
     - outline/主角*.md
     - outline/*主角*.md
     - outline/角色设定.md
     - outline/characters/*.md（若使用子目录）
  4. 无匹配 → 进入 create 模式
```

---

## 关联文件收集

主角设定必须在世界观中成立。审计前需收集以下关联文件：

```
related_files 分类:
  必传（直接影响主角合理性）:
    - outline/世界观设定-*力量*.md, *修炼*.md, *共鸣*.md, *功法*.md  // 力量体系
    - outline/世界观设定-*社会*.md, *势力*.md, *阶层*.md             // 社会结构
    - outline/世界观设定-*种族*.md, *异族*.md, *势力*.md             // 种族/势力

  建议传（提升审计深度）:
    - outline/总大纲.md                                              // 主线剧情
    - outline/世界观设定-*资源*.md, *经济*.md                        // 资源体系
    - outline/世界观设定-*独特*.md, *特殊*.md                        // 独特设定

  上下文控制:
    - 如果关联文件总大小 > 30000 token，只传入必传类
    - 关联文件传入 Critic 时附上文件名列表，Critic 可按需读取
```

---

## 审计-修复循环

### 循环工作流

```
FUNCTION protagonist_review(project_path, user_request):

  // Phase 1: 目标文件检测
  protagonist_name = user_request.protagonist_name || extract_from(user_request)
  target_file = detect_target_file(project_path, protagonist_name, user_request.target_file)

  IF target_file:
    mode = "modify"
  ELSE:
    mode = "create"

  // Phase 2: create 模式 — 生成初稿
  IF mode == "create":
    other_worldbuilding = glob(project_path + "/outline/世界观设定*.md")

    planner_result = sessions_spawn("planner", {
      mode: "protagonist_draft",
      project: project_path,
      genre: read(project_path + "/project.json").genre,
      protagonist_name: protagonist_name,
      existing_worldbuilding: other_worldbuilding,
      user_preferences: read(project_path + "/project.json").worldbuilding_preferences
    })

    target_file = planner_result.output_file

  // Phase 3: 收集关联文件（按上下文控制策略）
  related_files = collect_related_files(project_path, context_budget=30000)

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
      target_files: [target_file],
      related_files: related_files,
      audit_mode: audit_mode,
      skill_context: "protagonist-review",
      dimension_spec: "workspace-critic/skills/protagonist-review/reference/dimensions.md",
      convergence_spec: "workspace-critic/skills/protagonist-review/reference/convergence-criteria.md",
      previous_report: (round > 1) ? last_report : null,
      protagonist_name: protagonist_name,
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

    // 4d: 修复（传入主角设定 + 世界观上下文）
    fix_result = sessions_spawn("planner", {
      mode: "worldbuilding_fix",
      audit_report: audit_report,
      target_scope: "protagonist",
      protagonist_name: protagonist_name,
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
| Critic spawn | `target_files` = [主角设定文件] | 审计目标 |
| Critic spawn | `related_files` = [世界观关联文件，受 30000 token 预算控制] | 主角必须在世界中成立，需要跨文件验证金手指、社会定位、成长路径 |
| Critic spawn | `previous_report`（Round 2+） | 聚焦上轮问题，避免重复扫描 |
| Critic spawn | `protagonist_name` | 当文件包含多个角色时定位审计目标 |
| Planner spawn | `existing_worldbuilding` = [全部世界观文件] | 主角修改最容易引发连锁反应（金手指→力量天花板→社会阶层→种族平衡） |
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
  "protagonist_name": "苏辰 / 叶凡（可选，用于聚焦审计范围）",
  "target_file": "outline/主角设定.md（可选，默认自动检测）",
  "mode": "create | modify（可选，默认自动判断）",
  "user_preferences": {
    "worldbuilding_preferences": {},
    "protagonist_focus": ["PC2", "PC3"],
    "accepted_flaws": ["PC5-2"],
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
    "skill": "protagonist-review",
    "protagonist_name": "苏辰",
    "mode": "modify",
    "round": 1,
    "total_score": 52,
    "max_score": 80,
    "grade": "C",
    "critical_count": 2,
    "warning_count": 3,
    "suggestion_count": 2,
    "converged": false,
    "average_score": 6.5,
    "min_dimension_score": 3
  },
  "dimension_scores": {
    "PC1": {"score": 8, "status": "pass", "note": "博物馆保安+独臂少年辨识度高"},
    "PC2": {"score": 4, "status": "critical", "note": "金手指过多（星河+造化炉+知识碾压+双回响+宽频率），且所有弱点都有即时解决方案"},
    "PC3": {"score": 3, "status": "critical", "note": "精神容量不足被造化炉完全缓冲，独臂后期有义肢方案——弱点是假的"},
    "PC4": {"score": 7, "status": "pass", "note": "三段成长弧线清晰，但32岁灵魂表现为16岁性格"},
    "PC5": {"score": 5, "status": "warning", "note": "三层身世叠太满，'钥匙'设定让主角沦为命运傀儡"},
    "PC6": {"score": 7, "status": "pass", "note": "与世界观耦合度尚可，但金手指'灵敏感由科学知识激活'解释牵强"},
    "PC7": {"score": 6, "status": "warning", "note": "配角描述缺乏，多数配角功能单一"},
    "PC8": {"score": 7, "status": "pass", "note": "穿越者+混血身份提供多重驱动力，但部分驱动力冲突"}
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
| 审计维度 | 8（PC1-PC8），详见 `reference/dimensions.md` |
| 满分 | 80 |
| 收敛条件 | critical=0 AND warning≤2 AND avg≥7.0 AND min≥4 |
| 最大轮次 | 4 |
| 首轮模式 | comprehensive |
| 后续轮模式 | focused |
| 修复 Agent | planner (mode: worldbuilding_fix) |
| 修复范围 | target_scope: "protagonist" |
| 关联文件预算 | 30000 token（必传类优先） |
| 目标文件检测 | 用户指定 > protagonist_name 搜索 > Glob 匹配 > create 模式 |
| 维度规范 | `reference/dimensions.md` |
| 准出标准 | `reference/convergence-criteria.md` |

---

## 与通用 Fix Loop 的集成

本 Skill 可独立运行，也可嵌入通用世界观构建流程（规则 1）：

1. **独立触发**：用户直接请求"审核主角设定" / "检查XX人设"
2. **Phase 3.5 自动触发**：新书创建流程中，检测到主角设定文件或 B2 为 critical 时自动触发
3. **B2 升级触发**：通用审计中 B2 评为 critical 时，自动升级为本 Skill

无论哪种触发方式，本 Skill 的审计结果不影响通用 15 维度审计的独立运行。两者是互补关系。
