# Content Scanner 协作流程定义

## 被调用方式

```json
sessions_spawn("checker", {
  "task": "逐段检查",
  "content_path": "<待检查内容文件路径>",
  "context_files": {
    // 由 context/context-sources.yaml 定义的上下文源
    // 键名和路径取决于宿主项目配置
  },
  "check_mode": "full|targeted",
  "target_rules": ["{rule_id}"],  // targeted 模式时指定
  "feedback_id": "FB-XXX"         // 处理反馈时关联
})
```

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| 上游 Agent | 审核不通过后的精细检查 | 内容路径 + 上下文源 + 审计报告 |
| 上游 Agent | 关键内容深度检查 | 内容路径 + 上下文源 |
| 上游 Agent | 用户请求逐段检查 | 内容路径 + 上下文源 |
| 上游 Agent | 修复后复查 | 内容路径 + 上下文源 + 上次检查报告 |
| 上游 Agent | 反馈处理 | feedback_id + 原始报告 + 人工标注 |

> 上游 Agent 的具体名称和触发条件由宿主项目定义。
> 参考 `context/domain-config.yaml` 的 `workflow` 节。

## 检查模式

### full 模式

```
适用: 常规逐段检查
成本: Phase 1 零 LLM + Phase 2 每段一次 LLM 调用
规则: 全部规则（从 rules/ 目录自动发现）
流程:
  1. 加载规则索引 + 知识库索引（如果 paths.knowledge_base 配置）
  2. 加载上下文源，构建初始累积上下文
  3. Phase 1: 确定性快筛（逐句）
  4. Phase 2: 逐段 LLM 深检
  5. 合并结果，计算评分
  6. 生成检查报告

输出: 检查报告 JSON + 评分 + 逐条违规
```

### targeted 模式

```
适用: 针对特定规则的复查
成本: Phase 2 约 5-15 次 LLM 调用
规则: 仅指定规则

流程:
  1. 加载指定规则
  2. Phase 2: 逐段检查（仅指定规则）
  3. 合并结果
  4. 与上次报告对比（如有）

输出: 针对性检查报告 + 与上次对比
```

### feedback 模式

```
适用: 处理人工反馈
成本: 1-3 次 LLM 调用（模式提取）

流程:
  1. 读取反馈记录
  2. 按反馈类型处理:
     ├── FALSE_POSITIVE → 更新规则阈值/排除条件
     ├── MISSED_ISSUE → LLM 提取模式 → 生成候选规则
     └── FIX_APPROVED → 强化规则权重
  3. 更新规则文件
  4. 检查规则生命周期状态变更

输出: 反馈处理结果 + 规则变更记录
```

## 与其他 Agent 的关系

> 以下关系由宿主项目定义。具体 Agent 名称参考
> `context/domain-config.yaml` 的 `workflow` 节。

| 关系类型 | 说明 |
|---------|------|
| 上游 | 触发检查任务的 Agent（如审核 Agent） |
| 下游 | 执行修复的 Agent（由 workflow.fix_agent 指定） |
| 互补 | 其他同领域扫描器/审计器（如有） |
| 知识反馈 | 知识库管理 Agent（如有，通过上游路由） |

## 输出格式

### 给上游 Agent

> 完整输出格式见 `.openclaw/skills/content-scanner/SKILL.md`

### 给修复 Agent（通过上游 Agent 转发）

```json
{
  "task": "根据检查报告修复",
  "content_path": "<内容文件路径>",
  "recommended_mode": "spot-fix|polish|rewrite|rework",
  "violations": [
    {
      "rule_id": "{rule_id}",
      "location": { "paragraph": 12, "sentence": 3 },
      "original_text": "原文",
      "severity": "critical",
      "issue": "问题描述",
      "suggestion": "修改建议"
    }
  ],
  "context_files": { ... }
}
```

## Fix Loop 编排协议

Scanner 本身不调用修复 Agent。Fix Loop 由上游 Agent 编排：

```
上游 Agent 编排逻辑:
  1. sessions_spawn("checker", {check_mode: "full"})
  2. IF 检查报告有违规:
     a. 确定修订模式:
        - 1-3 critical → spot-fix
        - 4-8 critical → polish
        - >8 critical → rewrite
     b. sessions_spawn(workflow.fix_agent, {mode, violations, context_files})
     c. sessions_spawn("checker", {check_mode: "full"})  // 复查
     d. 收敛检查:
        - critical == 0 AND warning ≤ convergence.warning AND score ≥ convergence.score → 收敛
        - 停滞检测: score_delta ≤ stagnation_delta → 展示趋势，等用户决策
     e. 最多 fix_loop.max_rounds 轮
  3. 收敛 → 通知上游 Agent
  4. 返回完整报告链
```

## 升级到人工

- 连续 fix_loop.max_rounds 轮停滞（分数不增长）
- 某条规则反复触发但修复无法消除
- 修复引入新 critical（退化）
- 规则 false_positive_rate > downgrade 阈值
