---
name: outline-creation
description: "爽文大纲创建 Skill Loop — 融合写作方法论（起承转合/冲突设计/爽点公式）与网文特征（黄金一章/爽点密度/平台适配），通过分阶段交付+内置审计循环生成高质量大纲"
version: "1.0.0"
owner: workspace-planner
orchestrator: workspace-main
---

# 爽文大纲创建 Skill

## 概述

本 Skill 将成熟的写作方法论（起承转合、冲突设计五步法、爽点设计公式等）与网文行业特征（黄金一章、爽点密度规则、平台节奏差异）融合为一套可执行的大纲创建流程。

**执行模型**：由 workspace-main 编排调用 workspace-planner 执行，分 4 个阶段推进，每阶段有用户检查点。

**与 Critic 的关系**：本 Skill 的内置审计是轻量级"好不好看"检查，不替代 Critic 的深度"合不合理"审计。两者互补。

---

## 触发条件

| 触发方式 | 示例 |
|---------|------|
| 新小说创作 | "帮我写一部末世题材的300万字爽文" |
| 大纲重构 | "这个大纲节奏有问题，重新规划" |
| 大纲扩展 | "把3卷大纲扩展到6卷" |
| 用户显式调用 | "使用 outline-creation skill" |

---

## 工作流

### Phase 1: 核心设计 → 用户检查点 ①

**加载参考**：`reference/satisfaction-design.md` + `reference/conflict-design.md`

**输入**：用户创意简报

```json
{
  "genre": "玄幻/都市/末世/科幻/...",
  "theme": "核心主题",
  "target_words": 3000000,
  "platform": "qidian|tomato|feiqiu|custom",
  "core_selling_point": "一句话卖点",
  "golden_finger_hint": "金手指方向（可选）",
  "tone": "燃/搞笑/黑暗/温馨/...",
  "additional_notes": "其他要求"
}
```

**输出**：核心设计文档

1. **核心爽点矩阵** — 从 13 类爽点中选 3-5 个作为主线爽感来源
   - 规则：不能只选同维度、至少1个情感类、长篇需"低调深沉"或"推理叠加"
2. **金手指/核心优势设计** — 核心爽感、限制/代价、成长路径
3. **冲突阶梯设计** — 每卷/阶段的冲突类型，避免同模式循环
4. **主角成长路径** — 力量成长 + 认知成长 + 社会成长

**检查点**：暂停，展示核心设计，等待用户确认/调整。

---

### Phase 2: 多级结构生成 → 用户检查点 ②

**加载参考**：`reference/methodology-guide.md` + `reference/pacing-design.md` + `reference/golden-chapter.md`

基于 Phase 1 的核心设计，按三个层级展开：

**Level 3: 全书框架**
- 卷数 = 目标字数 ÷ 每卷字数（建议 40-55万字/卷）
- 每卷：卷名、主题、地域、核心冲突类型、主角成长维度
- 贯穿全书的伏笔链（长线/中线/短线）
- 世界观激活规划

**Level 2: 卷结构**
- 每卷章节规划（按起承转合分段）
- 爽点分布（大爽点位置 + 小爽点密度）
- 情绪曲线（波峰波谷）
- 角色引入/退场

**Level 1: 单元故事**（每卷内 3-6 个单元故事）
- **起**（0.5-2章）：目标建立
- **承**（2-5章）：铺设 + 情绪亏欠（信息差/权力差/时间压力/赌注升级）
- **转**（1-2章）：逆转/揭示
- **合**（2-4章）：爽点释放 + 延续 + 钩子

**黄金一章设计**
- 前300字：直接切入冲突/危机
- 500-1500字：建立主角 + 核心问题 + 金手指暗示
- 1500-2300字：悬念收尾
- 详见 `reference/golden-chapter.md`

**检查点**：暂停，展示完整大纲结构，等待用户确认/调整。

---

### Phase 3: 内置质量审计 → 用户检查点 ③

**加载参考**：`reference/quality-criteria.md`

对 Phase 2 生成的大纲执行 8 维度审计，详见 `reference/quality-criteria.md`：

| # | 维度 | 核心检查 |
|---|------|---------|
| A1 | 爽点密度 | 大爽点间隔 ≤ 5000字（3-5章/个） |
| A2 | 爽点多样性 | 连续5个大爽点中至少3种不同类型 |
| A3 | 节奏波浪 | 无超过5章无任何爽点的"平段" |
| A4 | 冲突类型 | 相邻卷冲突类型不重复 |
| A5 | 伏笔链 | 所有长线伏笔有明确收束规划 |
| A6 | 黄金一章 | 通过黄金一章检查清单 |
| A7 | 世界观利用 | 核心设定均有对应剧情冲突 |
| A8 | 主角困境 | 不存在连续3卷同模式困境 |

**审计输出**：

```json
{
  "audit_result": "pass|fail",
  "score": 7.5,
  "dimensions": [
    {"id": "A1", "name": "爽点密度", "status": "pass|warning|fail", "detail": "..."}
  ],
  "issues": [
    {
      "severity": "critical|warning",
      "dimension": "A3",
      "location": "第二卷17-23章",
      "description": "连续7章无任何爽点",
      "suggestion": "建议在第20章插入一个小爽点..."
    }
  ]
}
```

**检查点**：暂停，展示审计报告，用户决定是否进入修复循环。

---

### Phase 4: 修复循环

```
max_rounds = 3
round = 1
converged = false

WHILE round <= max_rounds AND NOT converged:
    IF round == 1:
        issues = Phase3 审计结果.issues
    ELSE:
        issues = 重新审计.issues

    // 收敛判断
    converged = (
        critical_issues.count == 0
        AND warning_issues.count <= 2
        AND score >= 7.0
    )
    IF converged: BREAK

    // 针对性修复
    FOR each issue IN issues:
        根据 issue.suggestion 修复大纲

    // 用户确认
    展示修复内容，等待用户确认

    // 重新审计
    重新执行 Phase 3 审计
    round += 1

IF NOT converged:
    输出未收敛报告 + 用户决定：接受当前版本 OR 手动调整
```

---

## 输出格式

最终输出为标准大纲文档，存入 `novels/{项目名}/outline/总大纲.md`，结构如下：

```markdown
# 主线剧情大纲

## 整体规划
## 卷结构总览
## 第N卷：卷名
### 卷简介
### 双线设计（如适用）
### 章节规划
### 本卷核心爽点
### 伏笔埋设/收束
### 世界观激活
## 情感节奏设计
## 黄金一章设计（或独立文件）
```

---

## 渐进式加载

| 阶段 | 加载的参考文件 |
|------|--------------|
| Phase 1 | satisfaction-design.md, conflict-design.md |
| Phase 2 | methodology-guide.md, pacing-design.md, golden-chapter.md |
| Phase 3 | quality-criteria.md |
| Phase 4 | quality-criteria.md |

SKILL.md 始终加载（本文件），参考文件按需加载以节省 token。
