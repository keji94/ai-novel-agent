# ChapterAnalyzer 工具手册

本文档定义 ChapterAnalyzer (章节分析器) 可使用的工具。

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取源文件（小说正文）。

**示例**:
```json
read({"path": "./source/我的小说.txt"})
read({"path": "./source/chapters/chapter_001.md"})
```

### 2. write - 写入真相文件

**用途**: 创建 7 个真相文件。

**示例**:
```json
write({
  "path": "./novels/仙道长生/context/tracking/current_state.md",
  "content": "# 世界状态\n\n..."
})
```

### 3. exec - 执行命令

**用途**: 列出目录、拆分文件等。

**示例**:
```json
exec({"command": "ls -1 ./source/chapters/*.md"})
exec({"command": "mkdir -p ./novels/仙道长生/context/tracking"})
```

---

## 导入工具

### 4. split_chapters - 拆分章节

**用途**: 从单文件中拆分出各章节（支持中文/英文/自定义正则）。

> 详细实现见 reference/split-chapters-details.md

### 5. analyze_chapter - 分析单章节

**用途**: 从单章节中提取信息（角色、资源变化、伏笔、情感变化）。

> 详细实现见 reference/chapter-analysis-impl.md

### 6. consolidate_info - 信息整合

**用途**: 合并多章节提取的信息，解决冲突。

> 详细实现见 reference/consolidate-impl.md

### 7. generate_truth_files - 生成真相文件

**用途**: 从整合后的信息生成 7 个真相文件。

> 详细实现见 reference/truth-file-generation.md

---

## 7 真相文件列表

| # | 文件 | 路径 | 用途 |
|---|------|------|------|
| 1 | current_state.md | context/tracking/ | 世界状态（地点、势力、时间线） |
| 2 | particle_ledger.md | context/tracking/ | 资源/物品流水账 |
| 3 | foreshadowing.json | context/tracking/ | 伏笔追踪（埋设/回收） |
| 4 | chapter_summaries.md | context/summaries/ | 各章摘要 |
| 5 | subplot_board.md | context/tracking/ | 支线剧情看板 |
| 6 | emotional_arcs.md | context/tracking/ | 角色情感弧线 |
| 7 | character_states.json | context/tracking/ | 角色状态矩阵 |

---

## 导入流程与输出格式

完整导入流程（含断点续导）见 reference/import-workflow.md，输出模板见 reference/output-templates.md。

---

## 注意事项

### 必须做的事
- 按时间顺序分析
- 记录信息来源章节
- 标注不确定推断
- 解决前后冲突

### 禁止做的事
- 凭空臆测未出现内容
- 忽略时间线矛盾
- 遗漏重要角色
- 打乱章节顺序
