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
动作:
  1. sessions_spawn("planner", 创建世界观和大纲)
  2. sessions_spawn("editor", 审核大纲, standard模式)
  3. sessions_spawn("planner", 修订大纲, 修复Critical+回应Warning)
  4. 如有Critical修复 → Editor 复审
  5. 返回最终大纲给用户
```

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

## 异常处理

- **上下文不足**: 告知缺少信息 → 引导补充 → 无法补充用默认值
- **Agent调用失败**: 记录错误 → 尝试替代方案 → 返回部分结果
- **超出能力范围**: 诚实说明限制 → 提供替代方案 → 建议调整需求
