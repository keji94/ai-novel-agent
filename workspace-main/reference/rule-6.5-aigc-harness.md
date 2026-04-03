# 规则6.5: AIGC优化 Harness

> **详细协议** → `.openclaw/skills/content-scanner/aigc-harness/`
> - Harness 协议总览: `aigc-harness/SKILL.md`
> - 4阶段详细流程: `aigc-harness/reference/harness-workflow.md`
> - 规则沉淀协议: `aigc-harness/reference/precipitation.md`

## 触发条件

满足任一：
- 用户说"这段AI味太重"/"AIGC分数太高"/"降AI味"/"检测并修复AI痕迹"
- 用户报告外部检测工具的 AIGC 分数
- 规则2 步骤3.5 关键章节检测分数 < 70

## 与其他规则的关系

| 规则 | 区别 |
|------|------|
| 规则6 | 只读检测，不修复。6.5 是检测+修复闭环 |
| 规则2.5 | 面向质量违规（Checker）。6.5 面向 AI 痕迹（Detector） |
| 规则16 | 从人工修改学习。6.5 从 AIGC 分析沉淀。都写 `rules/learned/` |
| 规则10 | 6.5 的 Reviser 完成后触发规则10 Editor 复审 |

## 领域配置

AIGC Harness 参数由 `workspace-checker/context/domain-config.yaml` → `aigc_harness` 节注入：

```yaml
aigc_harness:
  semantic_dimensions:
    - {name: "句式单调", weight: 5}
    - {name: "逻辑跳跃", weight: 8}
    - {name: "情感平淡", weight: 6}
    - {name: "描写空洞", weight: 7}
    - {name: "对话生硬", weight: 6}
  revision_thresholds:
    rewrite: 60
    anti_detect: 70
    polish: 80
  convergence:
    pass_score: 75
    significant_improvement: 10
    acceptable_improvement: 5
  fix_loop:
    max_rounds: 2
    stagnation_delta: 2
  fix_agent: "reviser"
  segment_size: 3000
```

## 执行流程（摘要）

```
Phase 1 诊断 → Phase 2 规则沉淀(可选) → Phase 3 定向改写 → Phase 4 验证 + Fix Loop
```

Phase 3 中调用 `sessions_spawn("reviser", ...)` 执行修订，按 segment 分段处理（章节 > 3000字）。

Phase 4 收敛标准：post_score >= 75 AND delta >= 5。Fix Loop 最多 2 轮追加。
