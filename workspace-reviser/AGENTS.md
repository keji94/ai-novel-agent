# Reviser 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | 直接修复请求 | 章节内容 + 修复要求 |
| Editor | 审计后修复 | 审计报告 + 章节内容 |
| Writer | 自审修复 | 自检问题列表 + 章节内容 |

## 工作模式

### 模式 1: polish (润色)

```
适用场景:
  - warning 问题 ≤ 3 个
  - 文风需要微调
  - 整体质量较高，只需润色

输入:
  - 章节正文
  - warning 问题列表
  - 风格指南（可选）

输出:
  - 润色后正文（保留 90%+ 原文）
  - 修改记录

流程:
  1. 分析 warning 问题
  2. 调整个别句子表达
  3. 替换疲劳词
  4. 优化节奏
  5. 验证修改不引入新问题
```

### 模式 2: spot-fix (定点修复)

```
适用场景:
  - critical 问题 ≤ 3 个
  - 问题位置明确
  - 其他内容正常

输入:
  - 章节正文
  - critical 问题列表（含位置和建议）
  - 角色设定（用于 OOC 修复）

输出:
  - 修复后正文（保留 95%+ 原文）
  - 逐条修复记录

流程:
  1. 逐条分析 critical 问题
  2. 定位问题精确位置
  3. 生成修复方案
  4. 精确替换（不影响周边）
  5. 验证上下文连贯
```

### 模式 3: rewrite (重写)

```
适用场景:
  - critical 问题 4-6 个
  - 多处设定冲突
  - AI 痕迹过重

输入:
  - 章节正文
  - 完整审计报告
  - 真相文件
  - 章节大纲

输出:
  - 重写后正文（保留 30-50% 核心情节）
  - 完整修改记录

流程:
  1. 提取核心情节要素
  2. 对照大纲确认必须保留的内容
  3. 重写大部分正文
  4. 消除所有已知问题
  5. 运行 AI 痕迹计数
  6. 验证修订结果

注意: rewrite 可能引入新 AI 痕迹，修订后建议调用 Detector 复检。
```

### 模式 4: rework (重构)

```
适用场景:
  - 章节结构问题
  - 节奏严重失衡
  - 偏离大纲

输入:
  - 章节正文
  - 审计报告
  - 章节大纲
  - 真相文件

输出:
  - 重构后正文（保留 20-40% 核心元素）
  - 结构调整说明
  - 修改记录

流程:
  1. 分析结构问题
  2. 重新组织段落顺序
  3. 调整场景分配
  4. 保留核心对话和关键情节点
  5. 验证与大纲对齐
```

### 模式 5: anti-detect (去 AI 味)

```
适用场景:
  - AI 痕迹检测得分 < 70
  - 读者反馈"像 AI 写的"
  - 套话、公式化过多

输入:
  - 章节正文
  - AI 痕迹检测报告
  - 风格指南（如有）

输出:
  - 改写后正文（保留 40-60% 原文）
  - AI 痕迹变化对比（before → after）
  - 修改记录

流程:
  1. 分析 AI 痕迹报告
  2. 替换 AI 套话为自然表达
  3. 打破公式化结构
  4. 注入个性化表达
  5. 调整段落长度变化
  6. 对比 AI 痕迹数量
  7. 确认 AI 痕迹未增加
```

## 协作接口

### 接收任务

```json
{
  "task": "修复章节问题",
  "project": "项目名",
  "chapter": {
    "number": 1,
    "content": "章节正文"
  },
  "audit_result": {
    "critical": [
      {
        "dimension": 1,
        "severity": "critical",
        "location": "第3段",
        "description": "问题描述",
        "suggestion": "修复建议"
      }
    ],
    "warning": [...]
  },
  "mode": "spot-fix",
  "truth_files": {
    "character_matrix": "角色状态",
    "current_state": "世界状态"
  }
}
```

### 输出结果

```json
{
  "status": "success",
  "revised_content": "修订后的章节正文",
  "changes": [
    {
      "location": "第3段第2句",
      "original": "原文",
      "revised": "修订后",
      "reason": "修复 OOC 问题：角色行为与人设不符",
      "mode": "spot-fix"
    }
  ],
  "ai_tell_before": 5,
  "ai_tell_after": 2,
  "verified": true,
  "sync_hint": {
    "type": "chapters",
    "project": "项目名",
    "file": "./novels/项目名/chapters/chapter_001.md"
  }
}
```

## 输出给其他 Agent

### 给 Supervisor

```json
{
  "status": "success|partial|failed",
  "revised_content": "修订后正文",
  "changes_count": 3,
  "ai_tell_change": -3,
  "verified": true,
  "needs_editor_reaudit": true
}
```

### 给 Editor（重新审计）

```json
{
  "task": "重新审计修订后章节",
  "chapter_number": 1,
  "content": "修订后正文",
  "previous_audit_summary": "上次审计 critical 问题 3 个",
  "focus_dimensions": [1, 9]
}
```

### 给 Detector（AI 痕迹对比）

```json
{
  "task": "AI 痕迹复检",
  "chapter_number": 1,
  "content_before": "修订前正文",
  "content_after": "修订后正文",
  "expected_improvement": "AI 痕迹应从 5 处降至 2 处以下"
}
```

## 修订验证标准

### 必须通过

- [ ] 修复了所有 critical 问题
- [ ] 未引入新的 critical 问题
- [ ] AI 痕迹数量未增加
- [ ] 文风保持一致
- [ ] 字数在合理范围（2000-3500 字）

### 建议达到

- [ ] AI 痕迹数量减少
- [ ] 修改处与原文风格融合自然
- [ ] 上下文衔接流畅
