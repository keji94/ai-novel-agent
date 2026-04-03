# 规则4-9: 导入/文风/检测/导出/运营/修改

## 规则4: 章节导入流程

```
条件: 用户要导入已有小说章节续写
动作:
  1. 确认模式（单文件/目录/断点续导）
  2. sessions_spawn("chapter-analyzer", 导入章节)
  3. 返回导入结果（章节数、角色数、资源数、伏笔数）
```

## 规则5: 文风仿写流程

```
条件: 用户要分析/模仿某个作者的文风
动作:
  1. sessions_spawn("style-analyzer", 分析文风)
  2. 询问用户是否应用到某本书
  3. 确认 → 复制风格文件到书籍目录
```

## 规则6: AI痕迹检测流程

```
条件: 用户要检测章节的AI生成痕迹（只读，不修复）
动作:
  1. sessions_spawn("detector", 检测AI痕迹)
     // Detector 使用 rules/deterministic/ (D001-D012, D016-D019) + 独有语义分析
     // 替换参考: rules/replacements/ai-traces.yaml
  2. 返回结果（AI痕迹得分 0-100 + 问题定位 + 修改建议）
```

> 如需检测+修复闭环，使用 **规则6.5 AIGC优化 Harness**（详见 `reference/rule-6.5-aigc-harness.md`）

## 规则7: 导出流程

```
条件: 用户要导出小说
动作:
  1. 确认参数（格式txt/md/epub、章节范围、是否只导出已审核章节）
  2. exec(./scripts/export.sh)
  3. 返回导出结果
```

## 规则8: 运营咨询流程

```
条件: 用户咨询运营相关问题
动作: sessions_spawn("operator", 分析) → 返回结果
```

## 规则9: 章节修改流程

```
条件: 用户要修改已有章节
动作:
  1. 确认修改范围（整章重写/部分修改/审计问题修复）
  2. 路由:
     ├── 整章重写 → sessions_spawn("writer", 两阶段写作)
     ├── 部分修改 → sessions_spawn("writer", 定向修改)
     └── 审计修复 → sessions_spawn("reviser", 根据审计报告)
  3. 自动触发 sessions_spawn("editor", 审核)
  4. 不通过 → 自动调 Reviser 修订 → 重复审核（最多3轮，超过后报告用户决策）
  5. 真相文件重算: sessions_spawn("writer", Phase 2 状态重算)
     IF Phase 2 返回失败: 记录警告，下次 Writer 写作时自动触发完整重算
  6. 草稿存档: copy chapter → chapters/drafts/第X章-标题_draft.md
     (仅当 drafts/ 下尚无此章草稿时保存)
  7. 返回修改结果
```
