# 竞品分析报告：InkOS vs ai-novel-agent

**分析日期**: 2026-03-26
**竞品**: [InkOS](https://github.com/Narcooo/inkos) by Narcooo

---

## 一、竞品概览

### InkOS 基本信息

| 属性 | 值 |
|------|-----|
| 定位 | 自主化小说写作 CLI AI Agent |
| 技术栈 | TypeScript + Node.js |
| 发布形式 | npm 包 (`@actalk/inkos`) |
| 代码量 | ~12,600 行 TypeScript |
| 版本 | v0.5.0 (活跃迭代) |
| Star | 未统计 (GitHub) |

### 核心特性

- **5-Agent 管线**: Radar → Architect → Writer → Auditor → Reviser
- **两阶段写作**: 创意写作(temp 0.7) + 状态结算(temp 0.3)
- **33 维度审计**: 连续性、战力、伏笔、文风、去 AI 味等
- **7 个真相文件**: 世界状态、角色矩阵、资源账本、伏笔钩子等
- **10 个英文题材**: LitRPG、Progression Fantasy、Isekai 等
- **文风仿写**: 分析参考文本提取风格指纹
- **续写已有作品**: 导入章节 + 逆向工程真相文件
- **同人创作**: 4 种模式 (canon/au/ooc/cp)

---

## 二、架构对比

### 2.1 Agent 架构

| 维度 | ai-novel-agent | InkOS |
|------|----------------|-------|
| **Agent 数量** | 7 个 | 5 个 (+ 辅助 agents) |
| **架构模式** | Supervisor 协调 + 独立 Subagent | 流水线管线 (Pipeline) |
| **入口 Agent** | ai-novel-agent (Supervisor) | 无固定入口，命令驱动 |
| **协作模式** | sessions_spawn / sessions_send | 函数调用 |
| **状态管理** | MEMORY.md + project.json | 7 个真相文件 |
| **模型配置** | 全局 + Agent 级别 | 全局 + Agent 级别 + 多 Provider |

### 2.2 Agent 职责对比

| ai-novel-agent | InkOS | 职责 |
|----------------|-------|------|
| Supervisor | - | 任务路由、结果汇总 |
| Planner | Architect | 世界观、大纲、章节规划 |
| Writer | Writer | 正文撰写 |
| Editor | Auditor + Reviser | 审核、修订 |
| analyst | - | 作品分析 |
| Operator | Radar | 市场趋势、读者偏好 |
| Learner | - | 技巧学习 |
| - | ChapterAnalyzer | 导入章节分析 |
| - | Consolidator | 真相文件整合 |
| - | StateValidator | 状态验证 |

**InkOS 独有 Agent**:
- **ChapterAnalyzer**: 从已有章节逆向工程真相文件
- **Consolidator**: 整合多个来源的状态信息
- **StateValidator**: 写后状态验证
- **Detector**: AI 内容检测

---

## 三、功能对比

### 3.1 核心写作功能

| 功能 | ai-novel-agent | InkOS | 差距分析 |
|------|:--------------:|:-----:|----------|
| 创建新小说 | ✅ | ✅ | 相当 |
| 章节撰写 | ✅ | ✅ | 相当 |
| 大纲规划 | ✅ | ✅ | 相当 |
| 世界观设定 | ✅ | ✅ | 相当 |
| 角色设定 | ✅ | ✅ | 相当 |
| **两阶段写作** | ❌ | ✅ | **重要差距** |
| **33 维度审计** | ❌ | ✅ | **重要差距** |
| **自动修订循环** | ❌ | ✅ | **重要差距** |
| **写后验证器** | ❌ | ✅ | **重要差距** |

### 3.2 一致性保障

| 功能 | ai-novel-agent | InkOS | 差距分析 |
|------|:--------------:|:-----:|----------|
| 角色状态追踪 | ✅ (TOOLS.md 定义) | ✅ (character_matrix.md) | 实现程度不同 |
| 资源账本 | ❌ | ✅ (particle_ledger.md) | **缺失** |
| 伏笔追踪 | ✅ | ✅ (pending_hooks.md) | 相当 |
| 章节摘要 | ✅ | ✅ (chapter_summaries.md) | 相当 |
| 情感弧线 | ❌ | ✅ (emotional_arcs.md) | **缺失** |
| 支线进度板 | ❌ | ✅ (subplot_board.md) | **缺失** |
| **视角一致性** | ❌ | ✅ (POV filtering) | **缺失** |
| **信息边界** | ❌ | ✅ | **缺失** |

### 3.3 高级功能

| 功能 | ai-novel-agent | InkOS | 差距分析 |
|------|:--------------:|:-----:|----------|
| **续写已有作品** | ❌ | ✅ `import chapters` | **重要差距** |
| **同人创作** | ❌ | ✅ `fanfic init` | **重要差距** |
| **文风仿写** | ❌ | ✅ `style analyze/import` | **重要差距** |
| **AI 痕迹检测** | ❌ | ✅ `detect` | **重要差距** |
| **去 AI 味** | ❌ | ✅ (内置 + anti-detect) | **重要差距** |
| **EPUB 导出** | ❌ | ✅ `export --format epub` | **缺失** |
| **守护进程** | ❌ | ✅ `inkos up/down` | **缺失** |
| **通知推送** | ❌ | ✅ (Telegram/飞书/企业微信) | **缺失** |
| **Token 用量统计** | ❌ | ✅ | **缺失** |
| 英文写作 | ❌ | ✅ | 需求待定 |

---

## 四、技术实现对比

### 4.1 代码架构

| 维度 | ai-novel-agent | InkOS |
|------|----------------|-------|
| **语言** | 配置 + Markdown | TypeScript |
| **运行时** | OpenClaw 框架 | Node.js CLI |
| **包管理** | Git 仓库 | npm 包 |
| **测试** | 无 | Vitest 单元测试 |
| **错误处理** | 文档定义 | 代码实现 + 降级策略 |
| **日志系统** | OpenClaw 日志 | 自定义 Logger (JSON Lines) |
| **并发控制** | OpenClaw 管理 | 文件锁 + 调度器防重入 |
| **流式响应** | OpenClaw 支持 | Stream 自动降级 |

### 4.2 数据模型对比

#### ai-novel-agent 数据结构
```
novels/{项目名}/
├── project.json          # 项目元数据
├── context/
│   ├── summaries/        # 章节摘要
│   ├── tracking/         # 角色状态、伏笔
│   └── indexes/          # 角色索引、地点索引
├── settings/             # 世界观设定
├── characters/           # 角色设定
├── outline/              # 大纲
└── chapters/             # 章节
```

#### InkOS 数据结构
```
books/{book-id}/
├── book.json             # 书籍配置
├── story/
│   ├── story_bible.md    # 故事设定
│   ├── volume_outline.md # 卷大纲
│   ├── style_guide.md    # 风格指南
│   ├── current_state.md  # 世界状态
│   ├── particle_ledger.md # 资源账本
│   ├── pending_hooks.md  # 伏笔钩子
│   ├── chapter_summaries.md # 章节摘要
│   ├── subplot_board.md  # 支线进度板
│   ├── emotional_arcs.md # 情感弧线
│   ├── character_matrix.md # 角色矩阵
│   ├── style_profile.json # 风格指纹
│   ├── parent_canon.md   # 正传正典 (番外用)
│   └── fanfic_canon.md   # 同人正典
├── chapters/             # 章节
└── snapshots/            # 状态快照
```

**InkOS 数据模型优势**:
1. **粒度更细**: 资源账本、情感弧线、支线进度板独立管理
2. **视角控制**: 角色矩阵支持 POV 过滤
3. **信息边界**: 记录每个角色知道什么、不知道什么
4. **快照机制**: 每章写前创建状态快照，支持回滚
5. **风格持久化**: style_profile.json + style_guide.md

### 4.3 Writer 实现对比

#### ai-novel-agent Writer
- 单阶段写作
- 手动更新追踪文件
- 依赖 TOOLS.md 指导
- 无自动验证

#### InkOS Writer (两阶段)
```
Phase 1: 创意写作 (temp 0.7)
  - 读取所有真相文件
  - 读取风格指南
  - 读取对话指纹
  - 生成章节正文
  
Phase 2: 状态结算 (temp 0.3)
  - 更新 current_state.md
  - 更新 particle_ledger.md
  - 更新 pending_hooks.md
  - 更新 chapter_summaries.md
  - 更新 subplot_board.md
  - 更新 emotional_arcs.md
  - 更新 character_matrix.md
```

**InkOS Writer 特有功能**:
- 对话指纹提取 (保持角色语言一致性)
- POV 过滤 (只传递当前视角的信息)
- 写前自检表
- 写后结算表
- Post-write 验证器 (11 条确定性规则)

### 4.4 Auditor 实现对比

#### ai-novel-agent Editor
- 一致性检查
- 节奏检查
- 伏笔检查
- 文笔检查
- **依赖 LLM 判断**

#### InkOS Auditor (33 维度)
```typescript
const DIMENSION_MAP = {
  1: "OOC检查",
  2: "时间线检查",
  3: "设定冲突",
  4: "战力崩坏",
  5: "数值检查",
  6: "伏笔检查",
  7: "节奏检查",
  8: "文风检查",
  9: "信息越界",        // ai-novel-agent 无
  10: "词汇疲劳",       // ai-novel-agent 无
  11: "利益链断裂",     // ai-novel-agent 无
  12: "年代考据",
  13: "配角降智",       // ai-novel-agent 无
  14: "配角工具人化",   // ai-novel-agent 无
  15: "爽点虚化",       // ai-novel-agent 无
  16: "台词失真",
  17: "流水账",
  18: "知识库污染",     // ai-novel-agent 无
  19: "视角一致性",     // ai-novel-agent 无
  20: "段落等长",       // ai-novel-agent 无
  21: "套话密度",       // ai-novel-agent 无
  22: "公式化转折",     // ai-novel-agent 无
  23: "列表式结构",     // ai-novel-agent 无
  24: "支线停滞",
  25: "弧线平坦",       // ai-novel-agent 无
  26: "节奏单调",
  27: "敏感词检查",
  28-37: 番外/同人专属维度
}
```

**InkOS Auditor 特有维度**:
- 信息越界检测 (角色知道不该知道的事)
- 词汇疲劳检测 (同一词过多)
- 利益链断裂 (角色行为动机不合理)
- 配角降智/工具人化检测
- 视角一致性检测
- AI 痕迹检测 (套话、公式化转折、列表式结构)

### 4.5 题材支持对比

| ai-novel-agent | InkOS (中文) | InkOS (英文) |
|----------------|--------------|--------------|
| 仙侠 | 仙侠 (xianxia) | Cultivation |
| 玄幻 | 玄幻 (xuanhuan) | Progression Fantasy |
| 都市 | 都市 (urban) | - |
| 恐怖 | 恐怖 (horror) | Horror |
| - | - | LitRPG |
| - | - | Isekai |
| - | - | Romantasy |
| - | - | Sci-Fi |
| - | - | Tower Climber |
| - | - | Dungeon Core |
| - | - | System Apocalypse |
| - | - | Cozy Fantasy |

**InkOS 题材配置示例** (xianxia.md):
```yaml
---
name: 仙侠
fatigueWords: ["冷笑", "蝼蚁", "倒吸凉气", "瞳孔骤缩", "天道", "大道"]
auditDimensions: [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26]
---

## 题材禁忌
- 主角为推剧情突然仁慈、犯蠢
- 修为无铺垫跳跃式突破
- 法宝凭空出现解决危机

## 修炼规则
- 境界突破必须有积累过程
- 同质资源重复炼化必须写明衰减
- 金手指四维约束: 上限/代价/条件/路径
```

---

## 五、关键差距总结

### 5.1 严重差距 (P0)

| 差距 | 影响 | 建议优先级 |
|------|------|-----------|
| **两阶段写作** | 状态追踪不准确，长篇一致性差 | P0 |
| **33 维度审计** | 质量控制弱，AI 痕迹重 | P0 |
| **自动修订循环** | 审计发现问题无法自动修复 | P0 |
| **写后验证器** | 低级错误无法及时捕获 | P0 |

### 5.2 重要差距 (P1)

| 差距 | 影响 | 建议优先级 |
|------|------|-----------|
| **续写已有作品** | 无法导入现有小说续写 | P1 |
| **文风仿写** | 无法模仿特定作者风格 | P1 |
| **AI 痕迹检测** | 输出太像 AI 生成 | P1 |
| **资源账本** | 数值型内容一致性问题 | P1 |
| **情感弧线** | 角色成长线不可追踪 | P1 |
| **支线进度板** | 支线故事管理混乱 | P1 |

### 5.3 一般差距 (P2)

| 差距 | 影响 | 建议优先级 |
|------|------|-----------|
| EPUB 导出 | 输出格式有限 | P2 |
| 守护进程 | 无法后台长时间运行 | P2 |
| 通知推送 | 长任务无状态通知 | P2 |
| Token 统计 | 成本不可追踪 | P2 |
| 同人创作 | 无法基于原作创作 | P2 |

---

## 六、我们可以做得更好的地方

### 6.1 架构优势

| ai-novel-agent 优势 | 说明 |
|---------------------|------|
| **Supervisor 模式** | 更灵活的任务路由，支持并行、串行、多轮对话 |
| **OpenClaw 生态** | 天然支持多渠道 (CLI、飞书、Webchat)、多模型 |
| **Subagent 隔离** | 每个 Agent 独立会话，上下文不污染 |
| **可扩展性** | 新增 Agent 只需创建 workspace + 配置 |

### 6.2 可优化方向

#### 方向 1: 实现两阶段写作

```typescript
// 在 Writer TOOLS.md 中定义
async function writeChapter(input) {
  // Phase 1: 创意写作 (temp 0.7)
  const content = await generateChapter({
    temperature: 0.7,
    context: buildContext()
  });
  
  // Phase 2: 状态结算 (temp 0.3)
  const stateUpdates = await settleState({
    temperature: 0.3,
    content,
    currentState: readTruthFiles()
  });
  
  // 更新真相文件
  await updateTruthFiles(stateUpdates);
  
  // 写后验证
  const violations = validatePostWrite(content);
  if (violations.errors.length > 0) {
    // 自动 spot-fix
    return fixViolations(content, violations.errors);
  }
  
  return content;
}
```

#### 方向 2: 扩展审计维度

从当前的 5 个维度扩展到 33 个维度：

```markdown
# Editor TOOLS.md 更新

## 审计维度

### 基础维度
1. OOC 检查
2. 时间线检查
3. 设定冲突
4. 战力崩坏
5. 数值检查
6. 伏笔检查
7. 节奏检查
8. 文风检查

### InkOS 独有维度 (需新增)
9. 信息越界检测
10. 词汇疲劳检测
11. 利益链断裂
13. 配角降智检测
14. 配角工具人化
15. 爽点虚化
19. 视角一致性
20. 段落等长
21. 套话密度
22. 公式化转折
23. 列表式结构
25. 弧线平坦

### AI 痕迹检测 (需新增)
- AI-tell 词检测
- 元叙事检测
- 作者说教检测
```

#### 方向 3: 新增真相文件

```markdown
# 新增真相文件

## particle_ledger.md (资源账本)
---
description: 追踪所有数值型资源
schema:
  - item: 物品名称
  - quantity: 数量
  - unit: 单位
  - source: 来源 (获得/消耗)
  - chapter: 章节
---

## emotional_arcs.md (情感弧线)
---
description: 追踪角色情绪变化
schema:
  - character: 角色
  - arc_type: 成长/堕落/觉醒
  - start_state: 初始状态
  - current_state: 当前状态
  - key_events: 关键事件
  - target_state: 目标状态
---

## subplot_board.md (支线进度板)
---
description: 管理支线故事进度
schema:
  - subplot_id: 支线ID
  - name: 支线名称
  - status: active/dormant/completed
  - chapters_involved: 涉及章节
  - last_update: 最后更新
  - stagnation_check: 停滞检测
---
```

#### 方向 4: 新增 Agents

```markdown
# 新增 Agent 建议

## ChapterAnalyzer (章节分析器)
- 职责: 从已有章节逆向工程真相文件
- 输入: 章节 Markdown 文件
- 输出: 7 个真相文件

## StyleAnalyzer (风格分析器)
- 职责: 分析参考文本提取风格指纹
- 输入: 参考文本
- 输出: style_profile.json + style_guide.md

## Detector (AI 检测器)
- 职责: 检测 AI 生成痕迹
- 输入: 章节内容
- 输出: AI 痕迹报告

## Reviser (修订者)
- 职责: 根据审计结果修订内容
- 模式: polish/spot-fix/rewrite/rework/anti-detect
```

#### 方向 5: 新增功能模块

```bash
# 新增 CLI 命令 (如果作为独立工具)

# 导入已有章节
inkos import chapters <book-id> --from ./novel.txt

# 文风分析
inkos style analyze reference.txt
inkos style import reference.txt <book-id>

# AI 检测
inkos detect <book-id> [--all]

# 导出 EPUB
inkos export <book-id> --format epub

# 守护进程
inkos up   # 后台运行
inkos down # 停止
```

---

## 七、行动计划

### Phase 1: 核心能力补齐 (2 周)

| 任务 | 优先级 | 预估工时 |
|------|--------|----------|
| 实现两阶段写作 | P0 | 3 天 |
| 扩展审计维度到 20+ | P0 | 2 天 |
| 实现写后验证器 | P0 | 1 天 |
| 新增资源账本 | P1 | 1 天 |
| 新增情感弧线 | P1 | 1 天 |
| 新增支线进度板 | P1 | 1 天 |

### Phase 2: 高级功能 (2 周)

| 任务 | 优先级 | 预估工时 |
|------|--------|----------|
| 章节导入 + 逆向工程 | P1 | 3 天 |
| 文风仿写 | P1 | 2 天 |
| AI 痕迹检测 | P1 | 2 天 |
| 自动修订循环 | P0 | 2 天 |
| POV 过滤 | P2 | 1 天 |

### Phase 3: 用户体验 (1 周)

| 任务 | 优先级 | 预估工时 |
|------|--------|----------|
| EPUB 导出 | P2 | 1 天 |
| Token 用量统计 | P2 | 1 天 |
| 通知推送 (可选) | P2 | 1 天 |
| 同人创作模式 (可选) | P2 | 2 天 |

---

## 八、总结

### InkOS 的核心优势

1. **工程化程度高**: TypeScript 实现，完整的测试覆盖
2. **状态管理细粒度**: 7 个真相文件，支持回滚
3. **质量控制强**: 33 维度审计 + 写后验证器 + 自动修订
4. **功能丰富**: 续写、同人、文风仿写、AI 检测
5. **迭代活跃**: v0.5.0，持续改进

### ai-novel-agent 的核心优势

1. **架构灵活**: Supervisor + Subagent 模式，支持复杂协作
2. **生态整合**: OpenClaw 框架，多渠道、多模型
3. **可扩展**: 新增 Agent 成本低
4. **学习曲线平缓**: Markdown 配置，无需编程

### 核心差距

1. **状态追踪精度**: InkOS 的两阶段写作 + 7 真相文件远超我们的设计
2. **质量控制**: 33 维度审计 + 写后验证器 + 自动修订循环是我们的致命短板
3. **AI 痕迹处理**: InkOS 从 prompt 层 + 审计层 + 修订层三管齐下
4. **功能完整性**: 续写、同人、文风仿写都是我们没有的功能

### 建议

**短期**: 重点补齐 P0 差距 (两阶段写作、审计维度、自动修订、写后验证)

**中期**: 实现 P1 功能 (章节导入、文风仿写、AI 检测、更多真相文件)

**长期**: 考虑是否需要独立 CLI 版本，还是继续基于 OpenClaw

---

**报告完成日期**: 2026-03-26
**下次更新**: 实现核心能力补齐后