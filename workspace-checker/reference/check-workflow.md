# 检查流程详细说明

> **共享协议**: 算法骨架由 `.openclaw/skills/content-scanner/` 定义。
> 本文件描述小说 Checker 的领域特有实现细节（规则分类、上下文字段、知识库转化）。
> 完整算法规范: `.openclaw/skills/content-scanner/reference/scan-algorithm.md`

## 概述

Checker 采用两阶段检查引擎，以段落(L2)为扫描单元，句子(L1)为定位单元。
领域配置: `context/domain-config.yaml`，上下文源: `context/context-sources.yaml`。

---

## Phase 1: 确定性快筛

### 执行条件
- 所有章节检查，始终执行
- 零 LLM 成本

### 流程

```
1. 章节分片
   ├── 按 L1 (句子): 以 。！？ 分割
   └── 按 L2 (段落): 以 \n 分割

2. 逐句规则扫描
   FOR 每个句子:
     FOR 每条确定性规则 (D001-D019):
       ├── 正则匹配类 (D001-D003, D008, D011): 直接匹配
       ├── 密度类 (D004-D007): 计算词频 vs 阈值
       ├── 结构类 (D009-D010, D012): 段落级统计
       ├── 设定门控 (D013-D015): 读取 settings_release.json 交叉比对
       └── 统计类 (D016-D019): 全章统计计算

3. 收集 deterministic_violations[]
```

### 输出
每条违规记录包含: rule_id, location(paragraph, sentence), original_text, severity, weight, message

---

## Phase 2: 逐段 LLM 深检

### 执行条件
- 所有章节检查，始终执行
- 约 20-40 次 LLM 调用/章

### 累积上下文初始化

```
初始上下文 = {
  chapter_summary: 从 context/summaries/recent.md 加载前5章摘要,
  truth_snapshot: {
    characters: 从 context/state/characters.json 加载,
    foreshadowing: 从 context/state/foreshadowing.json 加载,
    settings_release: 从 context/state/settings_release.json 加载,
    timeline: 从 context/state/timeline.json 加载
  },
  checked_lines_summary: {
    key_facts: [],
    character_states: {},
    information_revealed: [],
    emotional_arc: []
  },
  recent_paragraphs: []  // 最多保留3段
}
```

### 逐段扫描流程

```
FOR paragraph_index, paragraph IN enumerate(chapter.paragraphs):

  // Step 1: 构建当前段落的检查上下文
  context = build_context(
    chapter_summary,
    truth_snapshot,
    checked_lines_summary,
    recent_paragraphs
  )

  // Step 1.5: 注入 Phase 1 提示（如果启用）
  phase1_hints = []
  focus_areas = []
  IF domain_config.context.enable_phase1_hints:
    phase1_hints = deterministic_violations.filter(v => v.location.paragraph == paragraph_index)
    IF phase1_hints.length > 0:
      focus_areas = derive_focus_areas(phase1_hints)
      // 例: D013 设定越级 → focus on L003 设定冲突
      // 例: D001 禁止句式 → focus on L012 流水账

  // Step 2: 确定适用的 LLM 规则
  // - 全部 L001-L019 始终适用
  // - 加载匹配的技巧规则（从 knowledge/techniques/）
  // - 加载 active 状态的学习规则

  applicable_rules = get_llm_rules() + get_technique_rules(scenario_tags) + get_learned_rules(status="active")

  // Step 3: 一次 LLM 调用检查当前段落
  violations = llm_check(paragraph, context, applicable_rules, phase1_hints, focus_areas)

  // Step 4: 更新累积上下文（含置信度追踪）
  new_facts = extract_key_facts(paragraph)  // 每条附带 confidence
  FOR fact IN new_facts:
    fact.tentative = fact.confidence < 0.7  // tentative_threshold
    existing = find_contradictory(fact, checked_lines_summary.key_facts)
    IF existing AND existing.tentative AND fact.confidence > existing.confidence:
      checked_lines_summary.key_facts.replace(existing, fact)  // correction override
    ELSE IF NOT existing:
      checked_lines_summary.key_facts.append(fact)
  END

  state_changes = extract_character_state_changes(paragraph)  // 每项附带 confidence
  update_with_confidence(checked_lines_summary.character_states, state_changes, threshold=0.6)

  new_info = extract_information_revealed(paragraph)  // 每条附带 confidence
  update_with_confidence(checked_lines_summary.information_revealed, new_info, threshold=0.7)

  emotion = extract_emotion_point(paragraph)
  checked_lines_summary.emotional_arc.append(emotion)

  recent_paragraphs.append(paragraph)
  IF len(recent_paragraphs) > 3:
    recent_paragraphs.pop(0)  // 滑动窗口

  // Step 5: 收集违规
  llm_violations.extend(violations)
```

### LLM Prompt 结构

每次调用的 prompt 包含四个部分：

1. **System Prompt**: 角色定位 + 当前检查位置
2. **Context**: 累积上下文（前文摘要 + 角色状态 + 已知信息 + 最近段落）
3. **Truth Files**: 角色设定 + 伏笔状态 + 设定释放
4. **Content**: 当前待检查段落
5. **Output Format**: JSON 数组格式要求

### 上下文增长控制

- key_facts: 最多保留 50 条（超过后压缩旧条目），每条附带 confidence + tentative
- character_states: 只保留最新状态，每项附带 confidence + tentative
- information_revealed: 最多保留 30 条，每条附带 confidence + tentative
- emotional_arc: 每 3 段采样一次
- recent_paragraphs: 最多 3 段原文

---

## 评分计算

> 评分参数由 `context/domain-config.yaml` 定义

```
同位置 (paragraph, sentence) 的违规按 correlation_group 分组，
每组只计最高 severity 的违规。
无 correlation_group 的违规独立计分。

grouped = group_violations(all_violations, correlation_groups)
检查得分 = 100 - Σ(max(v.weight for v in group))

等级判定:
- A (90-100): 无 critical，warning ≤ 3
- B (80-89): 无 critical，warning ≤ 5
- C (70-79): critical ≤ 2 或 warning > 5
- D (<70): critical > 2
```

---

## 知识库技巧动态转化

### 加载时机
Phase 2 开始前，根据当前章节场景标签加载匹配技巧。

### 转化规则

| 技巧文件字段 | 转化方向 | 说明 |
|-------------|---------|------|
| 核心要点 | 正向检查规则 | 检查是否遵循 |
| 注意事项 | 负向检查规则 | 检查是否违反 |
| 应用场景 | 激活条件 | 匹配场景标签 |

### 运行时格式

```
技巧规则 = {
  id: "T-{NNN}",
  name: 技巧名称,
  positive_checks: [要点1, 要点2, ...],  // 应该做的
  negative_checks: [注意1, 注意2, ...],  // 不该做的
  applies_to: [场景标签列表]
}
```

---

## Fix Loop 循环

由 Supervisor 编排，Checker 只负责检查。
Fix Loop 参数由 `context/domain-config.yaml` 的 fix_loop 节定义。

```
Round 1:
  Checker 检查 → 有违规 → Supervisor 协调 Reviser 修复

Round 2:
  Checker 复查 → 仍有违规 → Supervisor 协调 Reviser 修复
  停滞检测: Round2 分数 - Round1 分数 ≤ 2 → 提示用户

Round 3 (最后一轮):
  Checker 复查 → 仍有违规 → 上报用户决策

收敛条件: critical == 0 AND warning ≤ 3 AND score ≥ 85
```
