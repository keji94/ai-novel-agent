# Writer 工具手册 v3.0

> **v3.0 重大升级**: 渐进式上下文管理系统 + Phase 0 上下文组装 + 增强版 Phase 2 状态结算

---

## 核心能力：三阶段写作架构

### Phase 0: 上下文组装（新增）
- **输入**: 项目索引 + 章节大纲
- **输出**: ~7K字的写作上下文
- **机制**: 三级渐进式加载（必选→条件→按需）

> 详细实现见 reference/two-phase-prompts.md Phase 0 部分
> 完整规范见 reference/progressive-context-system.md（主工作区）

### Phase 1: 创意写作
- **输入**: Phase 0 组装的上下文 + 章节大纲 + 风格指南
- **输出**: 章节标题 + 正文（2000-3000字）
- **模型**: temperature 0.7, max_tokens 8192

> 详细实现见 reference/two-phase-prompts.md Phase 1 部分

### Phase 2: 状态结算（增强版）
- **输入**: Phase 1 章节正文 + 当前上下文文件
- **输出**: 更新 11 个文件（7个状态 + 4个追踪）
- **模型**: temperature 0.3, max_tokens 4096

> 详细实现见 reference/two-phase-prompts.md Phase 2 部分

---

## 写后验证器

11 条确定性规则，零 LLM 成本，每章写完立刻触发。error 级别违规自动 spot-fix。

> 详细实现见 reference/post-write-validator.md

---

## 上下文文件管理（v3.0 渐进式系统）

### 文件结构

```
novels/{项目}/context/
├── state/                              ← 状态文件（Phase 2 更新）
│   ├── characters.json                 ← 角色当前状态卡
│   ├── foreshadowing.json              ← 伏笔债务表
│   ├── world_state.json                ← 世界当前状态
│   └── timeline.json                   ← 时间线
├── summaries/                          ← 摘要文件（滚动窗口）
│   ├── recent.md                       ← 最近10章详细摘要
│   └── vol_X_summary.md                ← 卷摘要
├── descriptions/                       ← 防重复索引
│   └── scenes_index.md                 ← 场景/战斗/情感描写索引
└── tracking/                           ← 追踪文件（Phase 2 更新）
    ├── strand_balance.json             ← Strand Weave 节奏平衡
    ├── readability.json                ← 追读力量化指标
    ├── character_relations.json        ← 角色关系图谱
    ├── particle_ledger.md              ← 资源账本
    └── character_states.json           ← 角色矩阵（兼容旧版）
```

### Phase 2 结算写入顺序

```
1. characters.json      - 角色状态变化
2. foreshadowing.json   - 伏笔新增/回收
3. world_state.json     - 世界状态变化
4. timeline.json        - 时间线推进
5. recent.md            - 追加本章摘要
6. strand_balance.json  - 节奏统计
7. readability.json     - 追读力指标
8. character_relations.json - 关系变化
9. scenes_index.md      - 场景索引
10. particle_ledger.md  - 资源变化
11. character_states.json - 角色矩阵
```

### 摘要滚动规则
- recent.md 保留最近10章
- 超过10章 → 最早的5章压缩为卷摘要
- 卷摘要超10卷 → 压缩为全书摘要

---

## 完整写作流程（v3.0）

```
1. 接收写作任务
   ↓
2. Phase 0: 渐进式上下文组装
   ├─ 第一层: characters.json + foreshadowing.json + recent.md
   ├─ 第二层: 相关设定 + strand_alerts + readability_trend
   └─ 第三层: scenes_index + relations（按需）
   ↓
3. Phase 1: 创意写作 (temp 0.7)
   ├─ 基于组装上下文生成正文
   └─ 输出标题+正文
   ↓
4. 写后验证器
   ├─ 11条规则检测
   ├─ 发现 error → 自动 spot-fix
   └─ 发现 warning → 记录日志
   ↓
5. Phase 2: 状态结算增强版 (temp 0.3)
   ├─ 更新 7个状态文件
   ├─ 更新 4个追踪文件
   ├─ 检查摘要滚动（>10章时压缩）
   └─ 一致性校验
   ↓
6. 写入章节文件
   ↓
7. 返回结果
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
