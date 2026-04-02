# 检查流程详细说明

> **共享协议**: 算法骨架由 `.openclaw/skills/content-scanner/` 定义。
> 本文件描述检查流程的详细步骤，所有领域特定内容由配置文件注入。
> 完整算法规范: `.openclaw/skills/content-scanner/reference/scan-algorithm.md`

## 概述

Scanner 采用两阶段检查引擎，以段落(L2)为扫描单元，句子(L1)为定位单元。
领域配置: `context/domain-config.yaml`，上下文源: `context/context-sources.yaml`。

---

## Phase 1: 确定性快筛

### 执行条件
- 所有内容检查，始终执行
- 零 LLM 成本

### 流程

```
1. 内容分片
   ├── 按 L1 (句子): 以 domain-config.text_units.l1_separator 分割
   └── 按 L2 (段落): 以 domain-config.text_units.l2_separator 分割

   exec: python3 {baseDir}/scripts/split_text.py \
     --input <内容文件> --config context/domain-config.yaml

2. 逐句规则扫描
   FOR 每个句子:
     FOR 每条确定性规则 (从 paths.deterministic_dir 自动加载):
       根据 rule.type 分派到对应 handler:
       ├── pattern / patterns: 正则匹配
       ├── density / fatigue / keyword_list: 词频统计
       ├── consecutive / length_check / consecutive_pattern: 结构检查
       ├── settings_gate: 读取上下文源交叉比对
       └── statistical: 全文统计计算

   exec: python3 {baseDir}/scripts/run_deterministic.py \
     --input <内容文件> \
     --rules-dir <paths.deterministic_dir> \
     --config context/domain-config.yaml \
     --context-dir context/

3. 收集 deterministic_violations[]
```

### 输出
每条违规记录包含: rule_id, location(paragraph, sentence), original_text, severity, weight, message

---

## Phase 2: 逐段 LLM 深检

### 执行条件
- 所有内容检查，始终执行
- 约 20-40 次 LLM 调用（取决于段落数量）

### 累积上下文初始化

上下文字段由 `context/context-sources.yaml` 声明，Scanner 加载声明的所有源：

```
初始上下文 = {
  // 静态上下文: 从 context-sources.yaml 的 static_fields 加载
  static_context: { <由宿主项目定义> },

  // 累积上下文: 从 context-sources.yaml 的 cumulative_fields 初始化（空）
  cumulative: { <由宿主项目定义，初始为空> },

  // 最近段落滑动窗口
  recent_paragraphs: []  // 最多保留 domain-config.context.recent_window 个
}
```

### 逐段扫描流程

```
FOR paragraph_index, paragraph IN enumerate(content.paragraphs):

  // Step 1: 构建当前段落的检查上下文
  context = build_context(
    static_context,          // 从 context-sources.yaml 加载
    cumulative,              // 前 N-1 段累积结果
    recent_paragraphs        // 最近段落滑动窗口
  )

  // Step 1.5: 注入 Phase 1 提示（如果启用）
  phase1_hints = []
  focus_areas = []
  IF domain-config.context.enable_phase1_hints:
    phase1_hints = deterministic_violations.filter(v => v.location.paragraph == paragraph_index)
    IF phase1_hints.length > 0:
      focus_areas = derive_focus_areas(phase1_hints)
      // Phase 1 的模式类违规为 Phase 2 提供聚焦方向
      // 具体映射由领域规则之间的关联性决定

  // Step 2: 确定适用的 LLM 规则
  // - 从 paths.llm_dir 加载全部 LLM 规则
  // - 从 paths.knowledge_base 加载匹配的技巧规则（如果配置）
  // - 从 paths.learned_dir 加载 active 状态的学习规则

  applicable_rules = get_llm_rules() + get_technique_rules(scenario_tags) + get_learned_rules(status="active")

  // Step 3: 一次 LLM 调用检查当前段落
  violations = llm_check(paragraph, context, applicable_rules, phase1_hints, focus_areas)

  // Step 4: 更新累积上下文（含置信度追踪）
  // 累积字段由 context-sources.yaml 的 cumulative_fields 定义
  // 更新策略和置信度阈值均从该配置读取
  new_extractions = extract_from_paragraph(paragraph)  // 每条附带 confidence

  update_cumulative_context(
    cumulative,
    new_extractions,
    context-sources.cumulative_fields  // 字段定义、max_size、update_strategy、threshold
  )

  recent_paragraphs.append(paragraph)
  IF len(recent_paragraphs) > recent_window:
    recent_paragraphs.pop(0)  // 滑动窗口

  // Step 5: 收集违规
  llm_violations.extend(violations)
```

### LLM Prompt 结构

每次调用的 prompt 包含四个部分：

1. **System Prompt**: 角色定位 + 当前检查位置
2. **Context**: 累积上下文（由 context-sources.yaml 定义的静态 + 累积字段 + 最近段落）
3. **Rules**: 适用的 LLM 规则及其 check_prompt
4. **Content**: 当前待检查段落

### 上下文增长控制

由 `context-sources.yaml` 的 `cumulative_fields` 定义每个字段的：
- `max_size`: 最大条目数
- `update_strategy`: append | merge
- `sample_rate`: 采样率（0 = 每段都提取）
- `confidence.tentative_threshold`: 低于此值的标记为 tentative

如果 `domain-config.context.pruning.enabled`，会根据 `field_rule_map` 按需裁剪上下文。

---

## 评分计算

> 评分参数由 `context/domain-config.yaml` 定义

```
同位置 (paragraph, sentence) 的违规按 correlation_group 分组，
每组只计最高 severity 的违规。
无 correlation_group 的违规独立计分。

grouped = group_violations(all_violations, correlation_groups)
检查得分 = 100 - Σ(max(v.weight for v in group))

等级判定: 由 domain-config.scoring.grade_thresholds 定义
```

---

## 知识库技巧动态转化

### 加载条件
仅在 `paths.knowledge_base` 配置时生效（非 null）。

### 加载时机
Phase 2 开始前，根据当前内容场景标签加载匹配技巧。

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
  positive_checks: [要点1, 要点2, ...],
  negative_checks: [注意1, 注意2, ...],
  applies_to: [场景标签列表]
}
```

---

## Fix Loop 循环

由上游 Agent 编排，Scanner 只负责检查。
Fix Loop 参数由 `context/domain-config.yaml` 的 `fix_loop` 节定义。

```
Round 1:
  Scanner 检查 → 有违规 → 上游 Agent 协调 workflow.fix_agent 修复

Round 2:
  Scanner 复查 → 仍有违规 → 上游 Agent 协调 workflow.fix_agent 修复
  停滞检测: Round2 分数 - Round1 分数 ≤ stagnation_delta → 提示用户

Round 3 (最后一轮):
  Scanner 复查 → 仍有违规 → 上报用户决策

收敛条件: 由 domain-config.fix_loop.convergence 定义
```
