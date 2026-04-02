# Agent协作流程定义

## 可调用的Agent列表

| Agent | 职责 | 调用场景 |
|-------|------|----------|
| Planner | 策划/大纲 | 新小说创作、世界观构建、大纲规划 |
| Writer | 写作/作者 | 章节撰写、场景描写、对话编写 |
| Editor | 编辑/审核 | 内容审核、33维度审计、一致性检查、**知识审核** |
| Reviser | 修订者 | 根据审计结果修复问题、去AI味 |
| ChapterAnalyzer | 章节分析器 | 导入已有章节、逆向工程真相文件 |
| StyleAnalyzer | 文风分析器 | 分析文风、提取风格指纹、生成风格指南 |
| Detector | AI痕迹检测器 | 检测AI生成痕迹、提供修订建议 |
| Analyst | 网文分析 | 作品分析、结构拆解、**多渠道技巧提取** |
| Operator | 运营/分析 | 市场分析、读者研究、运营策略 |
| Learner | 知识管理 | **技巧入库、知识检索、反馈处理** |
| Critic | 世界观骇客 | **世界观设定审计、18维度质量检查、Fix Loop回归审计** |
| Checker | 章节逐行扫描器 | **行级内容检查、两阶段扫描(确定性+LLM)、自学习规则、Fix Loop** |

## 任务路由规则

### 规则0: 灵感探索流程

```
条件: 用户表达模糊创作意向，缺少明确要素
触发: "我想写小说" / "有个想法想完善" / 需求缺少核心要素

动作:
  1. check_project_recovery() → 查找 brainstorming 阶段项目
  2. 有 → 恢复上下文（读取状态、提醒进度）
  3. 无 → create_draft_project(hint) → 生成临时书名
  4. sessions_send("planner", mode:"brainstorm", context:用户想法)
```

### 规则1: 新小说创作流程

```
条件: 用户要创作新小说

Phase 1-2: 构建初始框架（已有）
  1. sessions_send("planner", mode:"brainstorm") → 引导用户明确方向
  2. sessions_spawn("planner", mode:"create") → 构建世界观和大纲

Phase 3: 世界观审计（新增）
  3. sessions_spawn("critic", {
       worldbuilding_files: outline/世界观设定*.md,
       audit_mode: "comprehensive",
       project_preferences: project.json.worldbuilding_preferences
     }) → comprehensive_report

Phase 4: Fix Loop（新增，最多3轮）
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

Phase 3.5: 专项审计（新增）
  // 通用审计收敛后，根据文件和 critical 维度自动触发专项审计
  skill_map = {
    "social-structure-review": {
      files: "世界观设定-社会结构*.md",
      trigger_dimension: "C2",
      rule: "规则11"
    },
    "resource-system-review": {
      files: "世界观设定-资源体系*.md",
      trigger_dimension: "C1",
      rule: "规则12"
    },
    "race-faction-review": {
      files: "世界观设定-*族*.md | *势力*.md | *敌*.md | *种族*.md",
      trigger_dimension: "B3",
      rule: "规则13"
    },
    "power-system-review": {
      files: "世界观设定-*修炼*.md | *力量*.md | *功法*.md | *共鸣*.md | *魔法*.md | *能力*.md | *灵力*.md",
      trigger_dimension: "B1",
      rule: "规则14"
    },
    "protagonist-review": {
      files: "主角设定.md | 主角*.md | *主角*.md | 角色设定.md | characters/*.md",
      trigger_dimension: "B2",
      rule: "规则15"
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
    // 每个 Skill 内部：comprehensive → fix → focused → fix → ... (最多4轮)

  // 汇总结果
  all_specialized_issues = merge_all(specialized_results.*.issues)
  not_converged_skills = [name FOR name, result IN specialized_results IF NOT result.converged]

Phase 5: User Checkpoint（增强版）
  展示给用户:
  - 通用审计: 评级 + 评分趋势 + 亮点 + 待解决
  - 专项审计: 每个 Skill 的触发情况 + 评级 + 关键发现（如有）
  - 专项未收敛的 Skill 列表（如有）
  用户选择:（同原 Phase 5）
  6. 展示给用户:
     - 审计评级 + 评分趋势
     - 亮点列表（已解决的重要问题）
     - 待解决问题清单（如有）
     - 收敛/未收敛状态
  7. 用户选择:
     ├── 批准 → 进入 Phase 7
     ├── 要求修改 → 指定修改方向 → 进入 Phase 6
     └── 调整方向 → 回到 Phase 1-2

Phase 6: 定向修复（新增，按需）
  8. sessions_spawn("planner", mode:"worldbuilding_fix", {
       audit_report: report,
       user_feedback: 用户指定方向
     })
  9. sessions_spawn("critic", { audit_mode: "focused", ... })
  10. 回到 Phase 5

Phase 7: 衔接 Editor（已有）
  11. sessions_spawn("editor", 审核大纲, standard模式)
  12. 如有Critical修复 → Editor 复审
  13. 返回最终大纲给用户
```

#### Critic 调用说明

| 参数 | 说明 |
|------|------|
| worldbuilding_files | 世界观设定文件路径列表，从 outline/ 目录匹配 `世界观设定*.md` |
| audit_mode | `comprehensive`（首轮全面审计）/ `focused`（回归审计） |
| project_preferences | 从 project.json 读取 worldbuilding_preferences |
| previous_report | focused 模式时必需，传入上一轮审计报告 |

#### 偏好学习触发

| 用户行为 | 学习动作 |
|---------|---------|
| 批准带有 warning 的版本 | 将该 warning 类型写入 project.json → accepted_flaws |
| 手动修改 Critic 建议的修复方向 | 写入 project.json → critic_overrides |
| brainstorm 阶段强调某方面 | 写入 project.json → priorities |
| 多个项目中一致偏好 | 从 project.json 提升到 USER.md |

### 规则2: 内容撰写流程

```
条件: 用户要撰写具体内容
动作:
  1. 检查上下文(大纲/设定 + settings_release.json)，不足先调 Planner 补充
  2. sessions_spawn("writer", 撰写章节)
     → Phase 0: 加载索引 + 本章相关设定详情
     → Phase 1: 写作（遵守设定门控）
     → Phase 2: 结算（更新设定状态）
  3. 自动触发 sessions_spawn("editor", 审核)
     → Mode 0: 含设定校验 3 条规则
     → IF 设定 error → Writer spot-fix → re-verify（max 2轮）
  4. 草稿存档: copy chapter → chapters/drafts/第X章-标题_draft.md
     (仅当 drafts/ 下尚无此章草稿时保存)
  5. 返回 Writer 结果 + Editor 审核报告
```

### 规则2.5: 深度行检流程

```
条件（满足任一）:
  - Editor 审核不通过（C/D 级）
  - 关键章节写完（首章、高潮章、转折章）
  - 用户显式请求逐行检查
  - Reviser 修复后需验证

Phase 1: 深度检查
  1. sessions_spawn("checker", {
       chapter_path: "novels/{project}/chapters/第X章-标题.md",
       truth_files: {characters, foreshadowing, settings_release, timeline, recent_summary},
       check_mode: "full"
     }) → check_report

  ⚠️ 自检: 收到 check_report 后，立即检查 converged 状态。
     若 converged == false，必须立即进入 Phase 2 Fix Loop。
     不得停留在 Phase 1 等待用户指示。

Phase 2: Fix Loop（最多3轮，如有违规）
  2. WHILE round <= 3 AND NOT check_report.converged:
       a. 确定修订模式:
          - 1-3 critical → spot-fix
          - 4-8 critical → polish
          - >8 critical → rewrite
          - AI 痕迹为主 → anti-detect
       b. sessions_spawn("reviser", {
            mode: determined_mode,
            chapter_path: ...,
            violations: check_report.violations,
            truth_files: ...
          }) → revised_content
       c. sessions_spawn("checker", {
            chapter_path: ...,
            truth_files: ...,
            check_mode: "full"
          }) → check_report (复查)
       d. 收敛检查:
          - converged: critical == 0 AND warning ≤ 3 AND score ≥ 85
          - 停滞: score_delta ≤ 2 (round >= 2) → 展示趋势，等用户决策
       e. round += 1

Phase 3: 收敛后 Editor 复审
  3. sessions_spawn("editor", {
       mode: 1,  // 标准审计
       chapter_path: ...
     }) → final_editor_report

Phase 4: 返回结果
  4. 返回完整报告链:
     Checker 报告 + Reviser 修复记录 + Editor 复审结果

异常处理:
  - Editor C/D 级但 Checker 无违规 → 判定矛盾 → 展示双方报告，用户决策
  - 连续 3 轮停滞 → 上报用户
  - 修复引入新 critical（退化）→ 上报用户
```

#### Checker 触发时机详情

| 触发场景 | 触发方 | 说明 |
|---------|--------|------|
| Editor 审核不通过(C/D级) | Supervisor 自动 | 精确定位问题行，辅助 Reviser 修复 |
| 关键章节写完 | Supervisor 自动 | 首章、高潮章、转折章需深度保障 |
| 用户显式请求 | 用户 | "逐行检查"/"深度检查"/"行级扫描" |
| Reviser 修复后 | Supervisor 自动 | 验证修复是否引入新问题 |
| 章节修改后 | Supervisor 自动 | 规则9修改完成后可选触发 |

#### Checker 与 Editor 的关系

- **Editor 先行**: Editor Mode 0 快筛 → 通过 → 可发布；不通过 → Checker 接管
- **Checker 定位**: 行级精确定位 Editor 发现的章节级问题
- **互补而非替代**: Editor 看宏观（整章节奏、商业性），Checker 看微观（每句话的合规性）
- **Checker 后行**: Checker 收敛后必须经 Editor 复审确认整体质量

```
条件: 用户要分析作品或学习技巧
动作:
  1. 纯分析 → sessions_spawn("analyst", 分析)
  2. 分析+学习 → 规则 3.1（6步闭环）
```

### 规则3.1: 学习范文技巧流程（闭环版）

```
条件: 用户分享链接/内容要学习写作技巧
触发: 检测到URL / "学习这个" / 用户提供范文

Step 0: 创建状态文件
  写入 temp/learning_pipeline_{timestamp}.json:
  {
    "id": "lp_{timestamp}",
    "source": "URL或描述",
    "platform": "zhihu|weixin|douyin|other",
    "status": "extracting",  // extracting → reviewing → storing → verifying → done
    "created_at": "ISO8601",
    "steps": {
      "extract": { "status": "in_progress", "result_file": null },
      "review":  { "status": "pending", "result_file": null },
      "store":   { "status": "pending", "stored_count": 0 },
      "verify":  { "status": "pending" }
    }
  }

Step 1: 识别平台 (zhihu→知乎, mp.weixin→微信, douyin→抖音)

Step 2: sessions_spawn("analyst", parse_and_extract) → extracted_tips
  ✅ 成功 → 更新状态 status="reviewing", steps.extract.status="done", steps.extract.result_file=路径
  ❌ 失败 → 更新状态 steps.extract.status="failed"，通知用户

Step 3: sessions_spawn("editor", knowledge_review_1st_pass) → APPROVE/MERGE/REJECT
  ✅ 成功 → 更新状态 status="storing", steps.review.status="done", steps.review.result_file=路径
  ❌ 失败 → 更新状态 steps.review.status="failed"，通知用户

Step 4: sessions_spawn("learner", merge_and_store, 仅APPROVE+MERGE) → stored_items
  ✅ 成功 → 更新状态 status="verifying", steps.store.status="done", steps.store.stored_count=N
  ❌ 失败 → 更新状态 steps.store.status="failed"，通知用户

Step 5: sessions_spawn("editor", knowledge_review_2nd_pass) → 一致性检查
  ✅ 成功 → 更新状态 status="done", steps.verify.status="done"
  ❌ 失败 → 更新状态 steps.verify.status="failed"，通知用户

Step 6: 返回学习结果（提取X条，通过Y条，拒绝W条，更新分类）
  清理: 删除 temp/learning_pipeline_{id}.json（保留 result_file）
```

**⚠️ 断裂恢复机制**：
- 每次会话启动时，检查 `temp/learning_pipeline_*.json` 中 status != "done" 的文件
- 找到卡住的流程 → 读取最后完成的步骤 → 从下一步继续
- 恢复时通知用户："检测到上次未完成的学习流程（{source}），将从{步骤名}继续"

**状态文件约定**：
- 路径：`temp/learning_pipeline_{timestamp}.json`
- 每步完成后立即更新状态文件（不等后续步骤）
- 状态文件随最终 git commit 一起提交后删除
- result_file（提取结果、审核报告）保留在 temp/ 目录，不入知识库

**平台识别**: zhihu.com/question/*/answer→知乎回答, zhuanlan.zhihu.com/p/*→专栏, mp.weixin.qq.com/s/*→微信, douyin.com/video/*→抖音

**反馈路由**: Editor审核章节时附带 knowledge_feedback → 路由到 Learner process_feedback。Writer 报告 report_technique_feedback → 同上。

### 规则4: 章节导入流程

```
条件: 用户要导入已有小说章节续写
动作:
  1. 确认模式（单文件/目录/断点续导）
  2. sessions_spawn("chapter-analyzer", 导入章节)
  3. 返回导入结果（章节数、角色数、资源数、伏笔数）
```

### 规则5: 文风仿写流程

```
条件: 用户要分析/模仿某个作者的文风
动作:
  1. sessions_spawn("style-analyzer", 分析文风)
  2. 询问用户是否应用到某本书
  3. 确认 → 复制风格文件到书籍目录
```

### 规则6: AI痕迹检测流程

```
条件: 用户要检测章节的AI生成痕迹
动作:
  1. sessions_spawn("detector", 检测AI痕迹)
     // Detector 使用 rules/deterministic/ (D001-D012, D016-D019) + 独有语义分析
     // 替换参考: rules/replacements/ai-traces.yaml
  2. 返回结果（AI痕迹得分 0-100 + 问题定位 + 修改建议）
```

### 规则7: 导出流程

```
条件: 用户要导出小说
动作:
  1. 确认参数（格式txt/md/epub、章节范围、是否只导出已审核章节）
  2. exec(./scripts/export.sh)
  3. 返回导出结果
```

### 规则8: 运营咨询流程

```
条件: 用户咨询运营相关问题
动作: sessions_spawn("operator", 分析) → 返回结果
```

### 规则9: 章节修改流程

```
条件: 用户要修改已有章节
动作:
  1. 确认修改范围（整章重写/部分修改/审计问题修复）
  2. 路由:
     ├── 整章重写 → sessions_spawn("writer", 两阶段写作)
     ├── 部分修改 → sessions_spawn("writer", 定向修改)
     └── 审计修复 → sessions_spawn("reviser", 根据审计报告)
  3. 自动触发 sessions_spawn("editor", 审核)
  4. 不通过 → 自动调 Reviser 修订 → 重复审核（最多3轮，超过后报告用户决策）
  5. 真相文件重算: sessions_spawn("writer", Phase 2 状态重算)
     IF Phase 2 返回失败: 记录警告，下次 Writer 写作时自动触发完整重算
  6. 草稿存档: copy chapter → chapters/drafts/第X章-标题_draft.md
     (仅当 drafts/ 下尚无此章草稿时保存)
  7. 返回修改结果
```

---

## 多Agent协作模式

| 方式 | 工具 | 适用场景 | 特点 |
|------|------|----------|------|
| **Subagent模式** | `sessions_spawn` | 后台任务、并行处理 | 独立会话、异步通告 |
| **直接通信模式** | `sessions_send` | 串行协作、实时交互 | 共享会话、同步返回 |

> 串行/并行/直接通信模式详解见 `reference/collaboration-patterns.md`

---

## 上下文传递规范

> 各Agent上下文传递 JSON schema 详见 `reference/context-specs.md`

---

## 规则10: Reviser完成后自动复审

```
条件: Reviser 完成修复任务后
动作:
  1. 自动触发 Editor 复审（不询问用户）
  2. 复审重点：
     - 修复是否到位、是否引入新问题
     - 文件间引用/链接是否正确
     - 交叉引用是否形成循环
     - 各文件边界是否清晰，有无内容重复或遗漏
     - 整体一致性
  3. 复审通过 → 更新项目状态，通知用户
  4. 复审不通过 → 再次调用 Reviser 修复 → 重复复审
     （最多3轮，超过后报告用户人工决策）
```

## 异常处理

- **上下文不足**: 告知缺少信息 → 引导补充 → 无法补充用默认值
- **Agent调用失败**: 记录错误 → 尝试替代方案 → 返回部分结果
- **超出能力范围**: 诚实说明限制 → 提供替代方案 → 建议调整需求

### 场景化恢复策略

| 场景 | 检测方式 | 恢复策略 |
|------|---------|---------|
| Fix Loop 中途失败 | spawn 返回 error | 保留已完成的审计轮次，询问用户是否基于当前结果继续 |
| Critic 报告格式错误 | 字段缺失/类型不匹配 | 要求 Critic 补充，或降级为文本报告 |
| Writer Phase 2 部分失败 | 一致性校验未通过 | 标记失败的文件，下一章 Phase 0 时触发完整重算 |
| spawn 超时 | timeout | 重试1次，仍失败则通知用户并保存当前进度 |

---

## 规则11-15: 专项审计流程（通用模板）

每个专项审计 Skill 包含完整的审计-修复循环定义。Supervisor 按以下通用模板编排执行，具体参数见下表。

> **Skill 文件是单一事实来源**：审计维度、收敛条件、输入/输出 Schema 均定义在各 `workspace-critic/skills/{skill_name}/SKILL.md` 中。

### 通用编排流程

```
Step 1: 目标文件检测 → modify 模式（文件存在）/ create 模式（不存在）
Step 2 (create): sessions_spawn("planner", mode:{planner_mode}, {...}) → 生成初稿
Step 3: 审计-修复循环（最多4轮）
  WHILE round <= 4 AND NOT converged:
    3a: sessions_spawn("critic", {skill_context, dimension_spec, convergence_spec, ...})
    3b: 收敛检查（条件详见各 SKILL.md）→ converged?
    3c: 趋势判断（round>=2 且 stagnant → 提示用户）
    3d: sessions_spawn("planner", mode:"worldbuilding_fix", {target_scope, audit_report})
Step 4: 结果处理 → converged: 展示评级+趋势 | not converged: 用户检查点
  用户选择: 批准 | 定向修复（+1轮focused）| 重新设计（回Step 2）
```

### Skill 参数表

| 规则 | Skill | 触发维度 | Planner Mode | 目标文件 Glob | 特殊参数 |
|------|-------|---------|-------------|-------------|---------|
| 11 | social-structure-review | C2 | social_structure_draft | 世界观设定-社会结构*.md | - |
| 12 | resource-system-review | C1 | resource_system_draft | 世界观设定-资源体系*.md | cross_file_refs |
| 13 | race-faction-review | B3 | race_faction_draft | *族*\|*势力*\|*敌*\|*种族*.md | race_name |
| 14 | power-system-review | B1 | power_system_draft | *修炼*\|*力量*\|*功法*\|*共鸣*\|*魔法*\|*能力*\|*灵力*.md | system_name |
| 15 | protagonist-review | B2 | protagonist_draft | 主角设定\|主角*\|角色设定.md | protagonist_name, context_budget=30000 |

### 各 Skill 特殊设计

**规则11（社会结构）**：可独立运行或嵌入规则1 Phase 3 前置审计。审计结果不影响通用 18 维度审计。

**规则12（资源体系）**：RS8 维度需跨文件联动——修复后同步检查社会结构、聚集地格局等文件，修复说明必须列出跨文件变更。

**规则13（种族/势力）**：灵活文件检测（glob + 用户指定），Critic 审计传入目标文件+关联世界观做跨文件验证，修复传入全部世界观文件。

**规则14（力量/修炼）**：与社会结构/资源/种族深度耦合，修改最易引发连锁反应。修复时必须传入全部世界观文件。

**规则15（主角设定）**：关联文件受 30000 token 预算控制（必传力量体系+社会结构，建议传大纲+资源体系）。PC2 审计金手指数量，PC3 检查弱点真实性。

### 规则16: 定稿审核与差异学习

```
条件: 用户说"定稿第X章"、"第X章定稿"、"finalize chapter X"
动作:
  1. 定位章节: novels/{项目}/chapters/第X章-*.md
  2. 查找草稿: chapters/drafts/ 中对应 draft 文件
     ├── 找到草稿 → 完整流程（审核 + 差异分析 + 规则生成）
     └── 未找到草稿 → 仅审核（告知用户无初稿可供对比）
  3. sessions_spawn("editor", {
       mode: 7,
       chapter_path: "当前章节路径",
       draft_path: "草稿路径 (如有)",
       project: "项目名"
     })
  4. Editor 返回:
     - 审核报告 (定稿内容质量)
     - 差异分析 (初稿 vs 终稿，逐段对比)
     - 候选规则列表 (分类: ai_trace/style/grammar/plot)
  5. 规则直接落库（无需用户确认）:
     ├── AI痕迹替换 → 追加到 rules/replacements/ai-traces.yaml
     ├── 风格/语句规则 → 写入 rules/learned/ (新 yaml 文件)
     └── 更新 rules/_index.md 统计
     用户的修改是最高质量的反馈信号，直接生效。
  6. 真相文件重算: sessions_spawn("writer", Phase 2)
     (人工修改可能涉及情节/设定变更)
  7. 返回定稿结果: 审核报告 + 差异摘要 + 新增规则数量
```
