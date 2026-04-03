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

> 规则详情按分组存放在 `reference/rule-*.md`，按需加载。

| 规则 | 名称 | 详情文件 | 触发关键词 |
|------|------|---------|-----------|
| 0 | 灵感探索 | `reference/rule-0-1.md` | "我想写小说"/"有个想法" |
| 1 | 新小说创作 | `reference/rule-0-1.md` | "创作新小说" |
| 2 | 内容撰写 | `reference/rule-2-writing.md` | "写第X章"/"写具体内容" |
| 2.5 | 深度行检 | `reference/rule-2-writing.md` | Editor C/D级/关键章节/用户请求 |
| 3.1 | 学习范文技巧 | `reference/rule-3-learning.md` | 分享链接/"学习这个" |
| 4 | 章节导入 | `reference/rule-4-to-9.md` | "导入章节"/"续写已有小说" |
| 5 | 文风仿写 | `reference/rule-4-to-9.md` | "模仿文风"/"分析风格" |
| 6 | AI痕迹检测 | `reference/rule-4-to-9.md` | "检测AI痕迹"（只读） |
| **6.5** | **AIGC优化 Harness** | `reference/rule-6.5-aigc-harness.md` | "降AI味"/"AIGC太高"/"修复AI痕迹" |
| 7 | 导出 | `reference/rule-4-to-9.md` | "导出小说" |
| 8 | 运营咨询 | `reference/rule-4-to-9.md` | 运营相关问题 |
| 9 | 章节修改 | `reference/rule-4-to-9.md` | "修改第X章" |
| 10 | Reviser复审 | `reference/rule-10-16.md` | Reviser完成后自动 |
| 11-15 | 专项审计 | `reference/rule-10-16.md` | 世界观设定专项 |
| 16 | 定稿审核 | `reference/rule-10-16.md` | "定稿第X章" |

## 多Agent协作模式

| 方式 | 工具 | 适用场景 | 特点 |
|------|------|----------|------|
| **Subagent模式** | `sessions_spawn` | 后台任务、并行处理 | 独立会话、异步通告 |
| **直接通信模式** | `sessions_send` | 串行协作、实时交互 | 共享会话、同步返回 |

> 串行/并行/直接通信模式详解见 `reference/collaboration-patterns.md`

## 上下文传递规范

> 各Agent上下文传递 JSON schema 详见 `reference/context-specs.md`

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
