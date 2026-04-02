# Checker 协作流程定义

## 被调用方式

```json
sessions_spawn("checker", {
  "task": "逐行检查",
  "chapter_path": "novels/{项目名}/chapters/第X章-标题.md",
  "truth_files": {
    "characters": "novels/{项目名}/context/state/characters.json",
    "foreshadowing": "novels/{项目名}/context/state/foreshadowing.json",
    "settings_release": "novels/{项目名}/context/state/settings_release.json",
    "timeline": "novels/{项目名}/context/state/timeline.json",
    "recent_summary": "novels/{项目名}/context/summaries/recent.md"
  },
  "check_mode": "full|targeted",
  "target_rules": ["L001", "L003"],  // targeted 模式时指定
  "feedback_id": "FB-XXX"            // 处理反馈时关联
})
```

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | Editor 审核不通过 | 章节路径 + truth files + Editor 审计报告 |
| Supervisor | 关键章节深度检查 | 章节路径 + truth files |
| Supervisor | 用户请求逐行检查 | 章节路径 + truth files |
| Supervisor | Reviser 修复后复查 | 章节路径 + truth files + 上次检查报告 |
| Supervisor | 反馈处理 | feedback_id + 原始报告 + 人工标注 |

## 检查模式

### full 模式

```
适用: 常规逐行检查
成本: Phase 1 零 LLM + Phase 2 约 20-40 次 LLM 调用
规则: 全部规则
时间: 约 15-30 分钟

流程:
  1. 加载规则索引 + 知识库索引
  2. 加载 truth files，构建初始累积上下文
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

| 关系 | Agent | 说明 |
|------|-------|------|
| 上游 | Editor | Editor 审核不通过时，Checker 接管做行级精确定位 |
| 下游 | Reviser | Checker 报告定位问题行，由 Supervisor 协调 Reviser 修复 |
| 互补 | Detector | Detector 专注 AI 痕迹统计，Checker 做更细粒度的行级检查 |
| 互补 | Editor | Editor 章节级宏观审计，Checker 行级微观扫描 |
| 知识反馈 | Learner | Checker 反馈技巧应用效果，通过 Supervisor 路由 |

## 输出给其他 Agent

### 给 Supervisor

```json
{
  "status": "success",
  "check_summary": {
    "chapter": "第5章-标题",
    "total_paragraphs": 25,
    "violations_found": 8,
    "critical_count": 2,
    "warning_count": 6,
    "score": 72,
    "grade": "C"
  },
  "convergence": {
    "converged": false,
    "round": 1,
    "score_history": [72]
  },
  "knowledge_feedback": [
    {
      "technique_id": "T013",
      "applied": true,
      "effective": true,
      "context": "第12段角色行为检查"
    }
  ],
  "sync_hint": {
    "type": "checker_report",
    "files": []
  }
}
```

### 给 Reviser（通过 Supervisor 转发）

```json
{
  "task": "根据检查报告修复",
  "chapter_path": "novels/{项目名}/chapters/第X章.md",
  "recommended_mode": "spot-fix|polish|rewrite|rework|anti-detect",
  "violations": [
    {
      "rule_id": "D001",
      "location": { "paragraph": 12, "sentence": 3 },
      "original_text": "原文",
      "severity": "critical",
      "issue": "问题描述",
      "suggestion": "修改建议"
    }
  ],
  "truth_files": { ... }
}
```

## Fix Loop 编排协议

Checker 本身不调用 Reviser。Fix Loop 由 Supervisor 编排：

```
Supervisor 编排逻辑:
  1. sessions_spawn("checker", {check_mode: "full"})
  2. IF 检查报告有违规:
     a. 确定修订模式:
        - 1-3 critical → spot-fix
        - 4-8 critical → polish
        - >8 critical → rewrite
        - AI 痕迹为主 → anti-detect
     b. sessions_spawn("reviser", {mode, violations, truth_files})
     c. sessions_spawn("checker", {check_mode: "full"})  // 复查
     d. 收敛检查:
        - critical == 0 AND warning ≤ 3 AND score ≥ 85 → 收敛
        - 停滞检测: score_delta ≤ 2 → 展示趋势，等用户决策
     e. 最多 3 轮
  3. 收敛 → sessions_spawn("editor", {mode: 1})  // Editor 复审
  4. 返回完整报告链
```

## 升级到人工

- 连续 3 轮停滞（分数不增长）
- 某条规则反复触发但修复无法消除
- 修复引入新 critical（退化）
- 规则 false_positive_rate > 30%
