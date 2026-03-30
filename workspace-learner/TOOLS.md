# Learner 工具手册 v2.0

> **重大重构**: 伪代码工具替换为具体文件操作流程，新增反馈处理能力

---

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取知识库文件。

**关键路径**:
```
./knowledge/techniques/_index.md           # 总索引（轻量，始终加载）
./knowledge/techniques/_sources.md         # 来源注册表
./knowledge/techniques/_feedback.md        # 反馈记录
./knowledge/techniques/items/T{NNN}.md     # 技巧详情（按需加载）
./knowledge/techniques/{category}/_category_index.md  # 分类索引
```

### 2. write - 写入文件

**用途**: 创建新的技巧文件。

**注意**: 仅用于创建新文件（merge_and_store），已有文件更新使用 edit。

### 3. edit - 更新文件

**用途**: 更新已有文件（索引追加、反馈更新）。

---

## 知识入库工具

### 4. store_technique - 入库审核通过的技巧

**前置条件**: 技巧已通过 Editor Mode 5 (knowledge_review_1st_pass) 审核。

**实现步骤**（严格按顺序执行）:

```
Step 1: 读取当前状态
  read ./knowledge/techniques/_index.md
  → 提取"总技巧数"和最大 T-ID 编号
  → 确定 next_id = max_id + 1

Step 2: 为每条 APPROVE 的技巧创建文件
  write ./knowledge/techniques/items/T{next_id}.md
  → YAML frontmatter 从 Editor 审核结果 + 来源信息构建:
     - id: T{next_id}
     - name: 技巧名称
     - categories: Editor 建议的分类（数组）
     - tags: 从内容提取
     - difficulty: beginner/intermediate/advanced
     - quality_score: Editor 给出的评分
     - source: 来源信息（platform, title, url, extracted_at）
     - review: 审核信息（reviewed_at, review_notes）
     - effectiveness: 初始值 {times_applied: 0, times_effective: 0, feedback: []}
  → Markdown body 从技巧内容构建:
     - 技巧描述
     - 核心要点
     - 应用场景
     - 示例（含分析）
     - 注意事项
  → next_id += 1

Step 3: 更新每个相关分类索引
  FOR EACH category IN technique.categories:
    read ./knowledge/techniques/{category}/_category_index.md
    → 在注释标记处追加:
      ### T{NNN} 技巧名称
      - 评分: X | 难度: Y
      - 一句话: 描述
      - 场景: 应用场景
      - 标签: tag1, tag2
    edit (old: comment marker → new: marker + entry)

Step 4: 更新总索引
  read ./knowledge/techniques/_index.md
  → 递增"总技巧数"和"本周新增"
  → 在对应分类表格中追加行:
    | T{NNN} | 技巧名称 | 评分 | 难度 |
  → 更新"按标签"索引

Step 5: 更新来源注册
  read ./knowledge/techniques/_sources.md
  → 追加来源行:
    | S{NNN} | 平台 | 标题 | 作者 | URL | 日期 | 技巧数 |

Step 6: 更新 MEMORY.md
  → 递增 T-ID 计数器
  → 追加入库记录

Step 7: 返回结果
  → 构建返回 JSON（含 stored_items, files_updated, sync_hint）
```

**MERGE 处理**:
当 Editor 判定为 MERGE 时，不创建新文件，而是更新已有技巧:
```
  read ./knowledge/techniques/items/{merge_target}.md
  → 在 Markdown body 的"示例"区域追加新示例
  → 更新 tags（合并新标签）
  → edit 写回
```

---

## 知识检索工具

### 5. search_techniques - 检索技巧

**用途**: 根据条件检索知识库，供其他 Agent 使用。

**实现步骤**:

```
Step 1: 轻量扫描
  read ./knowledge/techniques/_index.md
  → 提取所有分类表格中的条目

Step 2: 过滤匹配
  IF filters.categories:
    → 只保留匹配分类的条目
  IF filters.tags:
    → 只保留"按标签"索引中包含指定 tag 的 T-ID
  IF filters.keyword:
    → 模糊匹配技巧名称
  IF filters.min_quality:
    → 过滤 quality_score < min_quality 的条目
  IF filters.max_results:
    → 截取前 N 条（按 quality_score 降序）

Step 3: 加载详情（可选）
  IF detail_level == "full":
    FOR EACH matched T-ID:
      read ./knowledge/techniques/items/{T-ID}.md
      → 提取核心要点、示例、注意事项
  ELSE:
    → 使用 _index.md 中的摘要信息

Step 4: 返回结果
  → 构建 matched_techniques 数组
```

**检索场景速查**:

| 场景 | 推荐过滤条件 |
|------|-------------|
| 开篇章节 | categories: structure, tags: 开篇 |
| 打斗场景 | categories: [description, climax], tags: 打斗 |
| 对话优化 | categories: dialogue, min_quality: B |
| 爽点设计 | categories: climax, min_quality: B |
| 全文节奏 | categories: structure, tags: 节奏 |

---

## 反馈处理工具

### 6. process_feedback - 处理技巧应用反馈

**用途**: 接收 Writer/Editor 对技巧应用效果的反馈，更新知识库。

**实现步骤**:

```
Step 1: 定位技巧文件
  read ./knowledge/techniques/items/{T-ID}.md

Step 2: 更新 effectiveness 数据
  times_applied += 1
  IF effective: times_effective += 1
  feedback 数组追加:
    - context: 应用场景
    - effective: true/false
    - reason: 原因
    - date: YYYY-MM-DD
    - source: writer|editor

Step 3: 写回技巧文件
  edit items/{T-ID}.md (更新 YAML frontmatter)

Step 4: 更新反馈记录
  read ./knowledge/techniques/_feedback.md
  → 在 T-ID 对应区域追加反馈
  → 如需标记"待复查"，在"待复查技巧"区域追加

Step 5: 阈值检查
  effective_rate = times_effective / times_applied
  IF times_applied >= 3 AND effective_rate < 0.3:
    → 标记为"待复查"
    → 返回提示 Supervisor 安排 Editor 复查

Step 6: 返回处理结果
```

---

## 知识库目录结构

```
./knowledge/techniques/
├── _index.md              # 总索引（轻量，<2000 token）
├── _sources.md            # 来源注册表
├── _feedback.md           # 反馈记录 + 待复查列表
├── items/                 # 技巧文件池（单一事实来源）
│   ├── T001.md
│   ├── T002.md
│   └── ...
├── structure/             # 分类索引（派生视图）
│   └── _category_index.md
├── description/
│   └── _category_index.md
├── dialogue/
│   └── _category_index.md
├── character/
│   └── _category_index.md
├── climax/
│   └── _category_index.md
└── platform/
    ├── douyin_script/
    │   └── _category_index.md
    └── wechat_article/
        └── _category_index.md
```

**设计原则**:
- `items/` 是**单一事实来源**，所有技巧数据以 items/ 中的文件为准
- 分类目录的 `_category_index.md` 是**派生视图**，通过引用 T-ID 提供分类检索
- `_index.md` 是**轻量入口**，始终加载，详情按需从 items/ 读取
- 一条技巧可出现在多个分类索引中（通过 categories 数组指定）

---

## 注意事项

### ID 分配

- T-ID 格式: T{NNN}（T001, T002, ...）
- 从 `_index.md` 的"总技巧数"或已有最大编号推算下一个 ID
- **串行保证**: Supervisor 串行调用 Learner，不会出现并发冲突

### 索引一致性

- 每次入库必须同时更新 `_index.md` 和所有相关 `_category_index.md`
- 如果更新失败，优先保证 `items/` 文件已写入，索引可由 Editor 二审修复

### 效果阈值

| 条件 | 动作 |
|------|------|
| applied >= 3 且 effective_rate < 30% | 标记"待复查"，提示 Supervisor |
| applied >= 5 且 effective_rate >= 80% | 标记"最佳实践"（在 _index.md 中加注） |
| 被拒绝(Editor/Writer) >= 2 次 | 标记"适用范围待缩小" |

### sync_hint

每次入库操作后返回 `sync_hint` 给 Supervisor，由 Supervisor 决定是否执行云端同步:
```json
{
  "sync_hint": {
    "type": "technique",
    "files": ["./knowledge/techniques/items/T001.md"]
  }
}
```
