# Checker 工具手册 v2.0

> **核心能力**: 两阶段逐段检查引擎 + 规则系统 + 自学习
> **共享协议**: `.openclaw/skills/content-scanner/`
> **脚本目录**: `.openclaw/skills/content-scanner/scripts/`

---

## 确定性工具（Python 脚本）

> 所有脚本通过 `python3` 执行，Agent 不再心智模拟算法。
> `{baseDir}` = `.openclaw/skills/content-scanner/scripts/`

### 1. split_text — 文本分片

```bash
python3 {baseDir}/split_text.py \
  --input <文本文件路径> \
  --config context/domain-config.yaml
```

输出: JSON `{ l1_units[], l2_units[], l2_to_l1, metadata }`

### 2. run_deterministic — Phase 1 确定性检查

```bash
python3 {baseDir}/run_deterministic.py \
  --input <文本文件路径> \
  --rules-dir rules/deterministic/ \
  --config context/domain-config.yaml \
  --context-dir context/ \
  --genre <xianxia|xuanhuan|urban>
```

输出: JSON `{ violations[], summary }`

覆盖 11 种规则类型（D001-D019），零 LLM 成本。

### 3. update_context — 累积上下文更新

```bash
# 初始化空上下文
python3 {baseDir}/update_context.py \
  --context-json /tmp/context.json \
  --extractions /dev/null \
  --config context/domain-config.yaml \
  --context-sources context/context-sources.yaml \
  --unit-index 0 --init

# 逐段更新
python3 {baseDir}/update_context.py \
  --context-json /tmp/context.json \
  --extractions /tmp/extractions.json \
  --config context/domain-config.yaml \
  --context-sources context/context-sources.yaml \
  --unit-index <N> --unit-text "段落原文..."
```

Agent 每检查完一段后写 extractions.json，脚本处理 FIFO 修剪、置信度标记、矛盾覆盖。

### 4. calculate_score — 评分计算

```bash
python3 {baseDir}/calculate_score.py \
  --violations /tmp/all_violations.json \
  --config context/domain-config.yaml
```

输出: JSON `{ score, grade, deduction, critical_count, warning_count, ... }`

### 5. generate_report — 报告生成

```bash
python3 {baseDir}/generate_report.py \
  --violations /tmp/all_violations.json \
  --score /tmp/score.json \
  --split /tmp/split.json \
  --config context/domain-config.yaml \
  --project <项目名> --content-id <章节标识>
```

输出: 完整检查报告 JSON（符合 SKILL.md 定义的输出格式）

---

## Agent 职责（非脚本化）

### 6. Phase 2 LLM 逐段检查

Agent 自己做语义判断。每段一次 LLM 调用，检查：
- 静态规则（rules/llm/，L001-L019）
- 动态规则（知识库/技巧库匹配）
- 学习规则（rules/learned/，status=active）

### 7. load_relevant_techniques — 加载关联写作技巧

根据章节场景标签从 knowledge/techniques/ 加载匹配技巧。

**转化规则**:

| 技巧文件字段 | 转化方向 |
|-------------|---------|
| 核心要点 | 每条 → 正向检查规则 |
| 注意事项 | 每条 → 负向检查规则 |
| 应用场景 | 规则激活条件 |

### 8. build_check_context — 构建小说累积上下文

合并 truth files + 已检查段落摘要 → 构建当前段落的检查上下文。

> 上下文源声明: `context/context-sources.yaml`

### 9. 自学习工具

- process_human_feedback: 处理人工反馈
- generate_candidate_rule: 从漏报提取候选规则 → rules/learned/

---

## 标准检查流程

```
Step 1: exec split_text.py → L1/L2 结构
Step 2: exec run_deterministic.py → Phase 1 违规 + 统计数据
Step 3: Agent 做 Phase 2（语义判断）
  FOR 每段:
    构建检查 prompt（含 Phase 1 hints + 累积上下文）
    LLM 语义判断
    写 extractions.json
    exec update_context.py → 上下文持久化
Step 4: exec calculate_score.py → 得分 + 等级
Step 5: exec generate_report.py → 完整报告
```
