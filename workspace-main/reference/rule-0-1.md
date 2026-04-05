# 规则0-1: 灵感探索 & 新小说创作

## 规则0: 灵感探索流程

```
条件: 用户表达模糊创作意向，缺少明确要素
触发: "我想写小说" / "有个想法想完善" / 需求缺少核心要素

动作:
  1. check_project_recovery() → 查找 brainstorming 阶段项目
  2. 有 → 恢复上下文（读取状态、提醒进度）
  3. 无 → create_draft_project(hint) → 生成临时书名
  4. sessions_send("planner", mode:"brainstorm", context:用户想法)
```

## 规则1: 新小说创作流程

```
条件: 用户要创作新小说

Phase 1-2: 构建初始框架
  1. sessions_send("planner", mode:"brainstorm") → 引导用户明确方向
  2. sessions_spawn("planner", mode:"create") → 构建世界观和大纲

Phase 3: 世界观审计
  3. sessions_spawn("critic", {
       worldbuilding_files: outline/世界观设定*.md,
       audit_mode: "comprehensive",
       project_preferences: project.json.worldbuilding_preferences
     }) → comprehensive_report

Phase 4: Fix Loop（最多3轮）
  4. round = 1
  score_history = []
  5. WHILE round <= 3 AND NOT comprehensive_report.converged:
       a. sessions_spawn("planner", mode:"worldbuilding_fix", {
            audit_report: comprehensive_report / focused_report
          }) → 修复说明
       b. sessions_spawn("critic", {
            worldbuilding_files: outline/世界观设定*.md,
            audit_mode: "focused",
            previous_report: 上一轮报告,
            project_preferences: project.json.worldbuilding_preferences
          }) → focused_report
       c. score_history.append(focused_report.total_score)
       d. round += 1

  > 收敛条件详见 workspace-critic/TOOLS.md（通用审计：critical_count == 0 AND warning_count <= 3）

  停滞检测（第2轮起）:
    IF round >= 2 AND score_history[-1] - score_history[-2] <= 1:
      向用户展示趋势: "R1({score_history[0]}) → R2({score_history[1]})"
      选项: (a) 定向修复（指定维度） (b) 接受当前版本

  未收敛处理:
    - 汇总所有 unresolved_issues
    - 进入 Phase 5 由用户决策
```

### Phase 3.5: 专项审计

通用审计收敛后，根据文件和 critical 维度自动触发专项审计。

```
skill_map = {
  "social-structure-review": {
    files: "世界观设定-社会结构*.md", trigger_dimension: "C2", rule: "规则11"
  },
  "resource-system-review": {
    files: "世界观设定-资源体系*.md", trigger_dimension: "C1", rule: "规则12"
  },
  "race-faction-review": {
    files: "世界观设定-*族*.md | *势力*.md | *敌*.md | *种族*.md",
    trigger_dimension: "B3", rule: "规则13"
  },
  "power-system-review": {
    files: "世界观设定-*修炼*.md | *力量*.md | *功法*.md | *共鸣*.md | *魔法*.md | *能力*.md | *灵力*.md",
    trigger_dimension: "B1", rule: "规则14"
  },
  "protagonist-review": {
    files: "主角设定.md | 主角*.md | *主角*.md | 角色设定.md | characters/*.md",
    trigger_dimension: "B2", rule: "规则15"
  }
}

// 收集触发列表
skills_to_run = []
FOR skill_name, config IN skill_map:
  file_matched = glob(project_path + "/outline/" + config.files).length > 0
  dimension_critical = comprehensive_report.dimensions[config.trigger_dimension]?.severity == "critical"
  not_skipped = skill_name NOT IN project.json.worldbuilding_preferences.skip_specialized_audits
  IF (file_matched OR dimension_critical) AND not_skipped:
    skills_to_run.append({name: skill_name, ...config})

// 执行专项审计（每个 Skill 独立运行自己的审计-修复循环）
specialized_results = {}
FOR skill IN skills_to_run:
  specialized_results[skill.name] = run_specialized_audit(skill.name, project_path)

// 汇总结果
all_specialized_issues = merge_all(specialized_results.*.issues)
not_converged_skills = [name FOR name, result IN specialized_results IF NOT result.converged]
```

### Phase 3.7: 大纲结构检查

世界观审计收敛后，自动运行大纲结构诊断。与世界观审计互补——Critic 查"设定一致性"，OutlineChecker 查"叙事结构节奏"。

```
// 自动触发条件：大纲文件存在（总大纲.md + 至少一个 volumes/*.md）
outline_files = glob(project_path + "/outline/总大纲.md") + glob(project_path + "/outline/volumes/*.md")
IF outline_files.length >= 2:

  sessions_spawn("outline-checker", {
    novel_path: project_path,
    mode: "full_diagnostic",
    scope: "full",
    frameworks: ["snyder_beat", "harmon_circle", "kishotenketsu", "pacing", "setup_payoff", "character_arc", "theme"]
  }) → outline_report

  // 汇总到 Phase 5 展示给用户
  // P0/P1 问题 → 需要修复后重新检查
  // P2/P3 问题 → 列入建议，由用户决定是否修复
```

> 大纲结构检查也可由用户主动触发（规则 1.5），或在大纲修改后手动调用。

### Phase 5-7: 用户决策 + 修复 + 衔接

```
Phase 5: User Checkpoint
  展示给用户:
  - 通用审计: 评级 + 评分趋势 + 亮点 + 待解决
  - 专项审计: 每个 Skill 的触发情况 + 评级 + 关键发现（如有）
  用户选择:
     ├── 批准 → 进入 Phase 7
     ├── 要求修改 → 指定修改方向 → 进入 Phase 6
     └── 调整方向 → 回到 Phase 1-2

Phase 6: 定向修复
  sessions_spawn("planner", mode:"worldbuilding_fix", {audit_report, user_feedback})
  sessions_spawn("critic", {audit_mode:"focused"})
  回到 Phase 5

Phase 7: 衔接 Editor
  sessions_spawn("editor", 审核大纲, standard模式)
  如有Critical修复 → Editor 复审
  返回最终大纲给用户
```

### Critic 调用说明

| 参数 | 说明 |
|------|------|
| worldbuilding_files | 世界观设定文件路径列表，从 outline/ 目录匹配 `世界观设定*.md` |
| audit_mode | `comprehensive`（首轮全面审计）/ `focused`（回归审计） |
| project_preferences | 从 project.json 读取 worldbuilding_preferences |
| previous_report | focused 模式时必需，传入上一轮审计报告 |

### 偏好学习触发

| 用户行为 | 学习动作 |
|---------|---------|
| 批准带有 warning 的版本 | 将该 warning 类型写入 project.json → accepted_flaws |
| 手动修改 Critic 建议的修复方向 | 写入 project.json → critic_overrides |
| brainstorm 阶段强调某方面 | 写入 project.json → priorities |
| 多个项目中一致偏好 | 从 project.json 提升到 USER.md |
