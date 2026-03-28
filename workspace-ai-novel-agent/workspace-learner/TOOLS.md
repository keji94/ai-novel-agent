# Learner 工具手册

本文档定义 Learner (写作技巧学习师) 可使用的工具。

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取知识库中的技巧、指南等。

**常用路径**:
- `./knowledge/techniques/` - 写作技巧库
- `./knowledge/guides/` - 写作指南
- `./knowledge/analysis/` - 作品分析（来自 Analyst）

**示例**:
```json
read({"path": "./knowledge/techniques/开篇/悬念钩子.md"})
read({"path": "./knowledge/guides/打斗场面写作指南.md"})
```

### 2. write - 写入技巧文档

**用途**: 保存学到的技巧到知识库。

**示例**:
```json
write({
  "path": "./knowledge/techniques/开篇/悬念钩子.md",
  "content": "# 悬念钩子\n\n## 基本信息\n..."
})
```

### 3. edit - 更新技巧文档

**用途**: 改进已有技巧文档。

**示例**:
```json
edit({
  "path": "./knowledge/techniques/开篇/悬念钩子.md",
  "oldText": "示例：xxx",
  "newText": "示例：yyy（更好的例子）"
})
```

---

## 技巧入库工具

### 4. store_technique - 存储技巧

**用途**: 将 Analyst 提取的技巧存入知识库。

**输入格式**（来自 Analyst）:
```json
{
  "action": "learn_and_store",
  "tips": [
    {
      "name": "开篇悬念钩子",
      "category": "structure",
      "platform": "起点",
      "content_type": "novel",
      "content": "技巧详细内容...",
      "examples": ["原文示例..."]
    }
  ],
  "source_info": {
    "platform": "起点",
    "title": "诡秘之主",
    "author": "爱潜水的乌贼",
    "url": "https://..."
  }
}
```

**处理流程**:
```
1. 验证技巧有效性
   - 检查是否已存在
   - 检查描述是否完整
   - 检查示例是否充分
    ↓
2. 分类整理
   - 确定分类（structure/description/dialogue/...）
   - 确定子分类（开篇/发展/高潮/结尾）
    ↓
3. 存储到知识库
   - 创建文件 ./knowledge/techniques/{分类}/{技巧名}.md
   - 记录来源信息
   - 标记适用场景
    ↓
4. 更新索引
   - 更新 ./knowledge/techniques/index.md
```

**输出示例**:
```markdown
# 开篇悬念钩子

## 基本信息
- 分类: 结构技巧 / 开篇
- 来源: 《诡秘之主》- 爱潜水的乌贼
- 平台: 起点
- 内容类型: 长篇网文
- 难度: ⭐⭐

## 技巧描述
第一章开头设置悬念，引发读者强烈好奇，吸引继续阅读。

核心要点：
1. 制造信息差（读者想知道但不知道）
2. 设置反常（与预期不符的情节）
3. 埋设钩子（有待解答的谜题）

## 应用场景
- 新书开篇
- 新卷开篇
- 重要剧情转折

## 示例展示

### 示例1（诡秘之主）
> 周明瑞看着镜子里的自己，陷入了沉思。镜子里的年轻人有着黑发褐瞳，穿着白色衬衫，外貌平平无奇，但这不是问题。问题是，这不是他。

**分析**: 第一句就制造悬念——为什么看镜子会沉思？最后一句揭示反转——这不是他！读者立刻想知道：为什么不是他？发生了什么？

### 示例2（遮天）
> 在冰冷与黑暗的宇宙深处，九具庞大的龙尸拉着一口青铜古棺，正在缓缓地航行。

**分析**: 开篇就是极具冲击力的画面——龙尸、古棺、宇宙航行。读者立刻被吸引：这是怎么回事？要到哪里去？

## 注意事项
1. 悬念不要太晦涩，读者要能理解问题
2. 不要为悬念而悬念，要有实际剧情支撑
3. 悬念要在后续章节逐渐解开，不要一直吊着

## 练习建议
1. 尝试用一句话设置一个悬念
2. 分析3本热门小说的开篇，找出悬念钩子
3. 重写自己小说的开篇，加入悬念钩子
```

---

## 指南生成工具

### 5. generate_writing_guide - 生成写作指南

**用途**: 针对特定主题生成写作指南。

**触发场景**:
- 用户问"如何写好打斗场面"
- 用户问"怎么设计金手指"
- 用户问"如何把控节奏"

**实现**:
```json
// Step 1: 搜索相关技巧
techniques = search_techniques("打斗场面")

// Step 2: 整合技巧
guide = integrate_techniques(techniques)

// Step 3: 生成指南
write({
  "path": "./knowledge/guides/打斗场面写作指南.md",
  "content": guide
})
```

### 6. search_techniques - 搜索技巧

**用途**: 在知识库中搜索相关技巧。

**搜索维度**:
- 关键词匹配
- 分类筛选
- 场景匹配

**实现**:
```json
// 读取索引
index = read({"path": "./knowledge/techniques/index.md"})

// 搜索匹配
matched = filter(index, keyword)

// 返回技巧列表
```

---

## 知识库结构

```
./knowledge/
├── techniques/           # 写作技巧库
│   ├── structure/        # 结构技巧
│   │   ├── 开篇/
│   │   ├── 发展/
│   │   ├── 高潮/
│   │   └── 结尾/
│   ├── description/      # 描写技巧
│   │   ├── 环境描写/
│   │   ├── 动作描写/
│   │   └── 心理描写/
│   ├── dialogue/         # 对话技巧
│   ├── satisfaction/     # 爽点技巧
│   ├── character/        # 人物技巧
│   ├── pacing/           # 节奏技巧
│   └── index.md          # 技巧索引
├── guides/               # 写作指南
│   ├── 打斗场面写作指南.md
│   ├── 金手指设计指南.md
│   └── 节奏把控指南.md
└── analysis/             # 作品分析（来自 Analyst）
    └── 诡秘之主_分析报告.md
```

---

## 技巧索引格式

**index.md**:
```markdown
# 写作技巧索引

## 结构技巧

### 开篇
- [悬念钩子](./structure/开篇/悬念钩子.md) - 设置悬念吸引读者
- [人物出场](./structure/开篇/人物出场.md) - 让主角快速出场

### 发展
- [冲突递进](./structure/发展/冲突递进.md) - 让剧情层层推进

### 高潮
- [高潮爆发](./structure/高潮/高潮爆发.md) - 设计爽点高潮

### 结尾
- [悬念钩子](./structure/结尾/章节钩子.md) - 章末设置悬念

## 描写技巧

### 动作描写
- [打斗动作](./description/动作描写/打斗动作.md) - 写好打斗场面

## 爽点技巧
- [装逼打脸](./satisfaction/装逼打脸.md) - 经典爽点设计
```

---

## 输出建议

### 返回给 Supervisor 的格式

```json
{
  "status": "success",
  "response": "已成功学习并入库3个技巧：开篇悬念钩子、反转设计、结尾钩子",
  "techniques_stored": 3,
  "technique_files": [
    "./knowledge/techniques/structure/开篇/悬念钩子.md",
    "./knowledge/techniques/structure/发展/反转设计.md",
    "./knowledge/techniques/structure/结尾/章节钩子.md"
  ],
  "sync_hint": {
    "type": "technique",
    "files": [
      "./knowledge/techniques/structure/开篇/悬念钩子.md",
      "./knowledge/techniques/structure/发展/反转设计.md",
      "./knowledge/techniques/structure/结尾/章节钩子.md"
    ]
  }
}
```

> **注意**: 子Agent只负责本地文件操作，云端同步由主Agent统一处理。返回 `sync_hint` 提示主Agent执行同步。

### 返回给用户的格式（写作指导）

```markdown
# 打斗场面写作指导

## 核心技巧

### 1. 动作流畅
打斗动作要流畅有力，避免过度描写。

**示例**:
> 林风一剑刺出，剑光如虹，直取对方咽喉。

### 2. 节奏控制
快慢结合，张弛有度。

**示例**:
> 快——剑光闪烁，刀影重重。
> 慢——林风屏息凝神，寻找破绽。

### 3. 画面感
要有画面感，让读者看得见。

**示例**:
> 一道剑光划破夜空，如流星般璀璨。

## 练习建议
1. 尝试写一段10秒的打斗
2. 分析《斗破苍穹》的打斗场面
3. 重写自己的打斗段落

## 更多技巧
- [打斗动作详解](./knowledge/techniques/description/动作描写/打斗动作.md)
```