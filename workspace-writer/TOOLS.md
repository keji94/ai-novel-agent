# Writer 工具手册 v2.0

> **重大升级**: 实现两阶段写作 + 写后验证器 + 7个真相文件管理

---

## 核心能力：两阶段写作架构

### 为什么需要两阶段？

**问题**:
- 单阶段写作时，创意写作（temp 0.7）和状态结算（temp 0.3）混在一起
- 创意要求高温度，但状态追踪要求精确
- 导致：状态更新不准确，长篇一致性差

**解决**:
```
Phase 1: 创意写作 (temperature: 0.7)
  - 只输出章节正文
  - 创造性表达，不受约束

Phase 2: 状态结算 (temperature: 0.3)
  - 分析正文，更新所有真相文件
  - 精确追踪，确保一致性
```

---

## 两阶段写作流程

### Phase 1: 创意写作
- **输入**: 7个真相文件（只读）、章节大纲、创作指导（可选）、风格指南（可选）
- **输出**: 章节标题 + 章节正文（2000-3000字）
- **模型**: temperature 0.7, max_tokens 8192

> 详细实现见 reference/two-phase-prompts.md

### Phase 2: 状态结算
- **输入**: Phase 1 章节正文 + 当前 7 个真相文件
- **输出**: 更新后的 7 个真相文件
- **模型**: temperature 0.3, max_tokens 4096

> 详细实现见 reference/two-phase-prompts.md

---

## 写后验证器

11 条确定性规则，零 LLM 成本，每章写完立刻触发。error 级别违规自动 spot-fix。

> 详细实现见 reference/post-write-validator.md

---

## 7 个真相文件管理

### 文件列表

| 文件 | 路径 | 用途 |
|------|------|------|
| `current_state.md` | `context/tracking/current_state.md` | 世界状态：地点、势力、已知信息 |
| `particle_ledger.md` | `context/tracking/particle_ledger.md` | 资源账本：物品、金钱、修炼资源 |
| `pending_hooks.md` | `context/tracking/foreshadowing.json` | 伏笔钩子：未闭合伏笔 |
| `chapter_summaries.md` | `context/summaries/chapter_summaries.md` | 章节摘要 |
| `subplot_board.md` | `context/tracking/subplot_board.md` | 支线进度板 |
| `emotional_arcs.md` | `context/tracking/emotional_arcs.md` | 情感弧线 |
| `character_matrix.md` | `context/tracking/character_states.json` | 角色矩阵：关系、信息边界 |

### 写入顺序

Phase 2 结算时，按以下顺序更新：
1. `current_state.md` - 世界状态
2. `particle_ledger.md` - 资源账本
3. `pending_hooks` - 伏笔
4. `character_matrix` - 角色
5. `chapter_summaries` - 摘要
6. `emotional_arcs` - 情感
7. `subplot_board` - 支线

---

## 完整写作流程（新版）

```
1. 接收写作任务
   ↓
2. 读取所有真相文件
   ↓
3. Phase 1: 创意写作 (temp 0.7)
   ├─ 读取上下文
   ├─ 生成章节正文
   └─ 输出标题+正文
   ↓
4. 写后验证器
   ├─ 11 条规则检测
   ├─ 发现 error → 自动 spot-fix
   └─ 发现 warning → 记录日志
   ↓
5. Phase 2: 状态结算 (temp 0.3)
   ├─ 分析章节正文
   ├─ 提取状态变化
   └─ 更新所有真相文件
   ↓
6. 写入章节文件
   ↓
7. 返回结果
   ├─ 章节内容
   ├─ 验证结果
   ├─ 状态更新摘要
   └─ Token 用量
```

---

## AI 痕迹检测与去除

内置去AI味规则（Prompt层）+ 7 维检测（词汇疲劳、套话密度、公式化转折等）。

> 详细实现见 reference/ai-pattern-rules.md

---

## 题材专属规则

仙侠/玄幻题材配置：疲劳词列表、题材禁忌、修炼规则、审计维度。

> 详细实现见 reference/genre-rules.md

---

## 真相文件版本控制

Phase 2 结算前自动快照，保留最近 5 章，支持一键回滚。

> 详细实现见 reference/truth-file-versioning.md

---

## 注意事项

### 必须做的事
- **写作前**: 读取所有 7 个真相文件
- **Phase 1**: 只输出正文，不输出其他内容
- **Phase 2**: 必须更新所有变化的真相文件
- **写后**: 运行验证器，error 级别必须修复

### 禁止做的事
- 跳过 Phase 2 状态结算
- 忽略验证器的 error 级别违规
- 不更新真相文件就结束
- 使用禁用的表达方式

---

## 知识检索工具

- **`query_techniques`**: 写作前从知识库检索相关技巧，纳入写作上下文
- **`report_technique_feedback`**: 写作完成后报告技巧应用效果，触发反馈闭环

> 详细实现见 reference/knowledge-query-details.md
