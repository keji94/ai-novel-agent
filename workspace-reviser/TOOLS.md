# Reviser 工具手册

本文档定义 Reviser (修订者) 可使用的工具。

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取章节内容、真相文件、审计报告。

**常用路径**:
- `./novels/{项目名}/chapters/chapter_{n}.md` - 章节正文
- `./novels/{项目名}/context/tracking/*` - 真相文件
- `./novels/{项目名}/story/story_bible.md` - 故事设定

### 2. write - 写入修订后内容

**用途**: 保存修订后的章节。

**示例**:
```json
write({
  "path": "./novels/仙道长生/chapters/chapter_001_revised.md",
  "content": "# 第一章 觉醒（修订版）\n\n..."
})
```

### 3. edit - 精确修改

**用途**: spot-fix 模式下，精确替换问题句子。

---

## 修订工具

| # | 工具 | 用途 |
|---|------|------|
| 4 | `analyze_audit` | 从审计报告中提取需要修复的问题，按优先级排序 |
| 5 | `locate_problem` | 在章节正文中定位问题的精确位置（段落+句子级） |
| 6 | `generate_fix` | 根据问题和上下文生成修复方案（Prompt 驱动） |
| 7 | `apply_fix` | 将修复方案应用到章节正文（精确句子替换） |
| 8 | `count_ai_tells` | 统计章节中的 AI 痕迹数量（套话/公式化/等长惩罚） |
| 9 | `verify_revision` | 验证修订是否成功，检查是否引入新问题 |
| 10 | `select_revision_mode` | 根据审计结果自动选择最合适的修订模式 |

> 详细实现（输入输出 JSON、Python 代码、Prompt 结构）见 [reference/revision-tool-impl.md](reference/revision-tool-impl.md)

### 修订报告格式

修订完成后生成标准报告，包含：基本信息、修改记录（位置/问题/原文/修订/原因）、验证结果、后续建议。

> 完整报告模板见 [reference/output-format.md](reference/output-format.md)

---

## 工作流程

### 标准修订流程

```
1. 接收审计报告
   ↓
2. analyze_audit 分析问题
   ↓
3. select_revision_mode 选择模式
   ↓
4. 遍历 critical 问题
   ├─ locate_problem 定位
   ├─ generate_fix 生成方案
   └─ apply_fix 应用修复
   ↓
5. verify_revision 验证结果
   ├─ 问题是否修复
   ├─ AI 痕迹是否增加
   └─ 是否引入新问题
   ↓
6. 生成修订报告
   ↓
7. 返回修订后内容
```

---

## 注意事项

### 不同模式的时间估算

| 模式 | 预估时间 | Token 用量 |
|------|----------|-----------|
| polish | 30秒 | ~1000 |
| spot-fix | 1分钟/问题 | ~500/问题 |
| rewrite | 3-5分钟 | ~4000 |
| rework | 5-10分钟 | ~6000 |
| anti-detect | 3-5分钟 | ~4000 |

### 修订成本控制

- 优先使用 spot-fix 模式（成本低，效果好）
- rewrite 模式要谨慎（可能引入新问题）
- anti-detect 模式后要重新审计

### 错误处理

- 定位失败 → 扩大搜索范围
- 修复失败 → 返回原文，标记问题
- AI 痕迹增加 → 建议保留原文或人工修订

---

## 真相文件一致性

### 职责边界

Reviser **不直接修改**真相文件（7 个 tracking 文件）。Reviser 只修改章节正文内容。

### 真相文件更新触发

当修订涉及以下情况时，调用方（Supervisor）应在修订完成后触发 Writer Phase 2 重新结算真相文件：

- **角色状态变化**: 修改了角色的行为、能力、位置等
- **资源变化**: 修改了物品获取/消耗、金钱变化等
- **伏笔变化**: 修改了伏笔的埋设或回收
- **设定变化**: 修改了世界观、力量体系等设定
- **剧情走向变化**: 修改了核心情节或大纲偏离

### 调用方式

```json
// Supervisor 在收到 Reviser 结果后判断
if (reviser_result.changes涉及设定或状态) {
  sessions_spawn({
    "agentId": "writer",
    "task": "Phase 2: 状态结算（修订触发）\n章节正文: {修订后内容}\n原章节正文: {修订前内容}\n说明: 这是修订后的重算，需对比差异更新真相文件",
    "label": "状态重算-修订-第{N}章",
    "model": { "temperature": 0.3, "max_tokens": 4096 }
  })
}
```

### 简单修订（无需重算）

以下修订不涉及真相文件更新：
- 纯文字润色（替换疲劳词、优化表达）
- 修复语病、错别字
- 调整对话风格（不改变对话内容）
- 修改描写细节（不涉及设定变化）
