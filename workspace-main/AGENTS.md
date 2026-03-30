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
| Critic | 世界观骇客 | **世界观设定审计、15维度质量检查、Fix Loop回归审计** |

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
       c. round += 1

  收敛条件: critical_count == 0 AND warning_count <= 3

  未收敛处理:
    - 汇总所有 unresolved_issues
    - 进入 Phase 5 由用户决策

Phase 5: User Checkpoint（新增）
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
  1. 检查上下文(大纲/设定)，不足先调 Planner 补充
  2. sessions_spawn("writer", 撰写章节)
  3. 自动触发 sessions_spawn("editor", 审核)
  4. 返回 Writer 结果 + Editor 审核报告
```

### 规则3: 分析学习流程

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

Step 1: 识别平台 (zhihu→知乎, mp.weixin→微信, douyin→抖音)
Step 2: sessions_spawn("analyst", parse_and_extract) → extracted_tips
Step 3: sessions_spawn("editor", knowledge_review_1st_pass) → APPROVE/MERGE/REJECT
Step 4: sessions_spawn("learner", merge_and_store, 仅APPROVE+MERGE) → stored_items
Step 5: sessions_spawn("editor", knowledge_review_2nd_pass) → 一致性检查
Step 6: 返回学习结果（提取X条，通过Y条，拒绝W条，更新分类）
```

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
  4. 不通过 → 自动调 Reviser 修订 → 重复审核
  5. 真相文件重算: sessions_spawn("writer", Phase 2 状态重算)
  6. 返回修改结果
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

---

## 规则11: 社会结构专项审计流程

```
条件: 用户请求审计/创建社会结构，或通用审计 C2 升级为 critical

Skill 规范: workspace-critic/skills/social-structure-review/SKILL.md
维度规范: workspace-critic/skills/social-structure-review/reference/dimensions.md
准出规则: workspace-critic/skills/social-structure-review/reference/convergence-criteria.md

Step 1: 模式判断
  - exists("outline/世界观设定-社会结构.md") → modify 模式
  - not exists → create 模式

Step 2 (create 模式): 生成初始社会结构
  sessions_spawn("planner", mode:"social_structure_draft", {
    project: novels/{项目名},
    genre: project.json.genre,
    existing_worldbuilding: [outline/世界观设定*.md excluding 社会结构],
    user_preferences: project.json.worldbuilding_preferences
  })

Step 3: 审计-修复循环（最多4轮）
  round = 1
  WHILE round <= 4 AND NOT converged:

    // 3a: 审计
    audit_mode = (round == 1) ? "comprehensive" : "focused"
    audit_report = sessions_spawn("critic", {
      worldbuilding_files: ["outline/世界观设定-社会结构.md"],
      audit_mode: audit_mode,
      skill_context: "social-structure-review",
      dimension_spec: "workspace-critic/skills/social-structure-review/reference/dimensions.md",
      convergence_spec: "workspace-critic/skills/social-structure-review/reference/convergence-criteria.md",
      previous_report: (round > 1) ? last_report : null,
      project_preferences: project.json.worldbuilding_preferences
    })

    // 3b: 检查收敛
    converged = (
      audit_report.critical_count == 0
      AND audit_report.warning_count <= 2
      AND (audit_report.total_score / 8.0) >= 7.0
      AND min(dimension_scores) >= 4
    )
    IF converged: BREAK

    // 3c: 趋势判断（第2轮起）
    IF round >= 2 AND audit_report.trend.direction == "stagnant":
      提示用户：修复进入平台期，可指定修复方向或接受当前版本

    // 3d: 修复
    sessions_spawn("planner", mode:"worldbuilding_fix", {
      audit_report: audit_report,
      target_scope: "social_structure"
    })

    last_report = audit_report
    round += 1

Step 4: 结果处理
  IF converged:
    展示: 最终评级 + 评分趋势 + 亮点保留确认
  ELSE:
    用户检查点:
    - 评分趋势 (R1→R2→R3→R4)
    - 已解决/待解决问题清单
    - 最大阻塞项
    用户选择:
    ├── 批准当前版本 → 记录 accepted_flaws → 完成
    ├── 定向修复 → 指定维度 → 再执行1轮 focused（不计入4轮）
    └── 重新设计 → 回到 Step 2（将本次审计报告作为经验传入）
```

### 与通用 Fix Loop 的关系

- 本 Skill 可独立运行，也可嵌入规则 1 Phase 3 前作为前置深度审计
- 通用审计中 C2 评为 critical 时，建议升级触发本 Skill
- 本 Skill 的审计结果不影响通用 15 维度审计的独立运行

---

## 规则12: 资源体系专项审计流程

```
条件: 用户请求审计/创建资源体系，或通用审计 C1 升级为 critical

Skill 规范: workspace-critic/skills/resource-system-review/SKILL.md
维度规范: workspace-critic/skills/resource-system-review/reference/dimensions.md
准出规则: workspace-critic/skills/resource-system-review/reference/convergence-criteria.md

Step 1: 模式判断
  - exists("outline/世界观设定-资源体系.md") → modify 模式
  - not exists → create 模式

Step 2 (create 模式): 生成初始资源体系
  sessions_spawn("planner", mode:"resource_system_draft", {
    project: novels/{项目名},
    genre: project.json.genre,
    existing_worldbuilding: [outline/世界观设定*.md excluding 资源体系],
    user_preferences: project.json.worldbuilding_preferences,
    cross_file_refs: ["世界观设定-社会结构.md", "世界观设定-聚集地格局.md"]
  })

Step 3: 审计-修复循环（最多4轮）
  round = 1
  WHILE round <= 4 AND NOT converged:

    audit_mode = (round == 1) ? "comprehensive" : "focused"
    audit_report = sessions_spawn("critic", {
      worldbuilding_files: ["outline/世界观设定-资源体系.md"],
      audit_mode: audit_mode,
      skill_context: "resource-system-review",
      dimension_spec: "workspace-critic/skills/resource-system-review/reference/dimensions.md",
      convergence_spec: "workspace-critic/skills/resource-system-review/reference/convergence-criteria.md",
      previous_report: (round > 1) ? last_report : null,
      project_preferences: project.json.worldbuilding_preferences
    })

    converged = evaluate_convergence(audit_report)
    IF converged: BREAK

    sessions_spawn("planner", mode:"worldbuilding_fix", {
      audit_report: audit_report,
      target_scope: "resource_system"
    })

    last_report = audit_report
    round += 1

Step 4: 结果处理（同规则11）
```

### 与社会结构审计的区别

- 跨文件联动：资源体系修复常需同步更新社会结构、聚集地格局等文件（RS8 维度）
- create 模式需传入 cross_file_refs 参数，planner 据此进行交叉数据检查
- 修复说明中必须列出所有跨文件变更
