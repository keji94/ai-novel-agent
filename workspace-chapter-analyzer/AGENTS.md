# ChapterAnalyzer 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | 用户导入请求 | 源文件路径 + 导入模式 + 项目名 |

## 工作模式

### 模式 1: 单文件导入

```
适用场景:
  - 用户提供单个小说文件（txt/md）
  - 文件包含多个章节

输入:
  - source_path: 源文件路径
  - mode: "single"
  - project_name: 项目名称
  - split_pattern: "chinese|chinese_num|english|custom"

输出:
  - 7 个真相文件
  - 导入报告

流程:
  1. 读取源文件
  2. 按章节标记拆分
     - chinese: "第一章"/"第二章" 模式
     - chinese_num: "第1章"/"第2章" 模式
     - english: "Chapter 1"/"Chapter 2" 模式
     - custom: 自定义正则
  3. 逐章分析提取信息
     - 角色出场与状态变化
     - 资源获取与消耗
     - 伏笔埋设与回收信号
     - 情感变化
     - 支线进度
  4. 跨章整合信息
     - 角色信息合并（同名角色去重）
     - 资源变化汇总
     - 伏笔状态更新
  5. 生成 7 个真相文件
  6. 输出导入报告
```

### 模式 2: 目录导入

```
适用场景:
  - 用户提供章节目录（每章一个文件）
  - 文件按顺序排列

输入:
  - source_path: 目录路径
  - mode: "directory"
  - project_name: 项目名称
  - file_pattern: "chapter_*.md"（文件匹配模式）

输出:
  - 7 个真相文件
  - 导入报告

流程:
  1. 扫描目录，按文件名排序
  2. 逐文件读取并分析
  3. 跨章整合信息
  4. 生成 7 个真相文件
  5. 输出导入报告
```

### 模式 3: 断点续导

```
适用场景:
  - 已导入部分章节，需要继续导入
  - 上次导入中断

输入:
  - source_path: 源文件/目录路径
  - mode: "resume"
  - project_name: 项目名称
  - resume_from: 从第 N 章开始续导

输出:
  - 更新后的 7 个真相文件（增量更新）
  - 续导报告

流程:
  1. 读取已有真相文件，确认当前状态
  2. 从指定章节开始导入
  3. 增量更新真相文件（与已有数据合并）
  4. 输出续导报告
```

### 模式 4: 补充导入

```
适用场景:
  - 已有项目，需要导入额外章节
  - 用户提供了新的内容补充

输入:
  - source_path: 新增内容路径
  - mode: "supplement"
  - project_name: 项目名称
  - start_chapter: 新内容对应的起始章节号

输出:
  - 更新后的 7 个真相文件
  - 补充导入报告

流程:
  1. 读取已有真相文件
  2. 分析新内容
  3. 与已有数据整合（处理冲突）
  4. 更新真相文件
  5. 输出补充报告
```

## 协作接口

### 接收任务

```json
{
  "task": "导入章节",
  "project": "项目名",
  "source": {
    "path": "./source/novel.txt",
    "mode": "single|directory|resume|supplement",
    "split_pattern": "chinese",
    "resume_from": 50,
    "file_pattern": "chapter_*.md"
  },
  "options": {
    "detect_foreshadowing": true,
    "track_resources": true,
    "generate_summaries": true
  }
}
```

### 输出结果

```json
{
  "status": "success",
  "import_report": {
    "total_chapters": 120,
    "imported_chapters": 120,
    "characters_identified": 15,
    "resources_tracked": 23,
    "foreshadowing_planted": 8,
    "foreshadowing_resolved": 3,
    "foreshadowing_pending": 5,
    "uncertain_inferences": 2
  },
  "truth_files": {
    "current_state": "./novels/仙道长生/context/tracking/current_state.md",
    "particle_ledger": "./novels/仙道长生/context/tracking/particle_ledger.md",
    "pending_hooks": "./novels/仙道长生/context/tracking/foreshadowing.json",
    "chapter_summaries": "./novels/仙道长生/context/summaries/chapter_summaries.md",
    "subplot_board": "./novels/仙道长生/context/tracking/subplot_board.md",
    "emotional_arcs": "./novels/仙道长生/context/tracking/emotional_arcs.md",
    "character_matrix": "./novels/仙道长生/context/tracking/character_states.json"
  },
  "sync_hint": {
    "type": "chapters",
    "project": "仙道长生",
    "files": ["./novels/仙道长生/context/tracking/*"]
  }
}
```

## 输出给其他 Agent

### 给 Supervisor

```json
{
  "status": "success|partial|failed",
  "summary": "导入 120 章，识别 15 角色，追踪 23 资源，5 个伏笔待回收",
  "warnings": ["第 45 章角色「林风」修为变化不明确"]
}
```

### 给 Writer（真相文件就绪通知）

```json
{
  "task": "真相文件已就绪",
  "project": "仙道长生",
  "current_chapter": 120,
  "ready_for_continuation": true,
  "notes": "角色「林风」当前筑基中期，位于秘境"
}
```

## 章节拆分规则

### 中文数字章节

```
匹配模式: 第[一二三四五六七八九十百千万零\d]+章
示例: 第一章、第一百二十章、第1章
```

### 英文章节

```
匹配模式: Chapter \d+|CHAPTER [IVXLCDM]+
示例: Chapter 1、CHAPTER XII
```

### 自定义模式

```
用户提供正则表达式，如:
"卷[一二三四五].*节"
```

## 信息整合规则

### 角色合并

- 同名角色自动合并，取最新状态
- 同一角色不同称呼（别名/外号）需人工确认
- 不确定推断标记为 `[待确认]`

### 资源追踪

- 获取资源记录来源章节
- 消耗资源核对余额
- 来源不明的资源标记为 `[来源未说明]`

### 伏笔识别

**埋设信号**: "心中隐隐觉得"、"似乎有些不对"、"总觉得哪里见过"
**回收信号**: "原来如此"、"难怪"、"这才明白"

### 冲突处理

- 优先信任后出现的信息（后章覆盖前章）
- 标记所有冲突为 `[冲突: 描述]`
- 在报告中列出所有冲突供人工确认
