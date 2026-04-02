# 三江新书扫榜

## 概述
这是一个用于分析最新一期起点三江推荐书单的能力。通过异步任务机制获取本期三江书单，轮询任务状态，遍历获取每本书的章节内容，并且将章节内容发送给AI进行分析，产出分析报告MD文件以及截图并且写入飞书文档。

## 适用场景
- 获取本期三江推荐书单
- 批量采集书籍章节内容
- 为AI章节分析提供数据源
- 新书扫榜

---

## 🔔 通知机制（重要）

**每本书的每个步骤都必须主动通知用户！**

### 通知时机
使用 `message` 工具向当前会话发送进度通知：

| 步骤 | 通知内容模板 |
|------|-------------|
| Step 4 | `📖 正在获取《{书名}》章节内容...` |
| Step 5 | `🤖 正在分析《{书名}》章节（AI解析中）...` |
| Step 6 | `💾 已保存《{书名}》报告到本地` |
| Step 7 | `🖼️ 已生成《{书名}》分享图片（{数量}张）` |
| Step 8 | `📤 已同步《{书名}》到飞书：{链接}` |

### 通知方式
```json
// 使用 message 工具
{
  "action": "send",
  "channel": "feishu",
  "message": "📖 正在获取《加载了怪猎模版的蓝龙》章节内容..."
}
```

### 批量处理时的通知策略
- **每本书开始时**：发送 "📖 开始处理《{书名}》({当前}/{总数})"
- **每个步骤完成时**：发送步骤完成通知
- **单本书完成时**：发送 "✅ 《{书名}》处理完成"
- **全部完成时**：发送汇总报告

---

## 🚀 快速开始

### 核心流程（3步调度 + 5步执行）

#### 阶段一：数据准备（在主会话中执行）

```bash
# 先安装依赖（仅首次）
pip install -r skills/sanjiang-analyzer/requirements.txt

Step 1: 触发异步任务     python sanjiang.py fetch-cache [--max-chapters N]
Step 2: 轮询任务状态     python sanjiang.py task-status <taskId>
Step 3: 获取书籍列表     python sanjiang.py books [--book-name NAME] [--date DATE]
```

#### 阶段二：逐书处理（每本书启动独立子进程）⭐

**为每本书启动独立的 `sessions_spawn` 子进程，实现完美隔离：**

```
for each book in books:
    sessions_spawn({
        "task": "处理《{书名}》的完整流程（Step 4-8），请严格按照 SKILL.md 执行。",
        "runtime": "subagent",
        "mode": "run",
        "streamTo": "parent",
        "label": "三江速评-{书名}",
        "runTimeoutSeconds": 600
    })
    等待子进程完成
    发送进度通知
```

#### 单本书的执行步骤（在子进程中）

```
Step 4: 获取章节详情     python sanjiang.py book --book-name <书名>  ← 🔔 通知 取前20章分析
Step 5: AI解析报告       见 references/ai-analysis.md  ← 🔔 通知
Step 6: 保存本地文件     见 references/output-spec.md  ← 🔔 通知 + 必须执行
Step 7: 生成分享图片     见 references/output-spec.md  ← 🔔 通知 + 必须执行
Step 8: 同步飞书文档     见 references/output-spec.md  ← 🔔 通知 + 最后执行 + 必须插入图片！
```

> ⚠️ **Step 8 特别注意**：
> - 创建文档后**必须插入分享图片**！
> - 使用 `feishu_doc_media` 工具插入图片到文档末尾
> - 图片路径：`/tmp/{书名}_新书扫榜_1.png`（需先从 `images/sanjiang/` 复制到 /tmp/）
> - 详细步骤见 `references/output-spec.md`

> ⚠️ **重要**：
> - Step 6-8 必须按顺序执行，不可跳过！
> - **每本书必须启动独立子进程**，避免上下文爆炸！
> - 子进程完成后通过 `streamTo: "parent"` 推送结果到主会话


### API 文档

> 📖 **动态加载**：以下场景按需读取对应文档，节约 token

| 场景 | 文档路径 | 说明 |
|------|---------|------|
| 触发采集任务 | `references/api-fetch-cache.md` | 异步获取三江书单 |
| 轮询任务状态 | `references/api-task-status.md` | 查询任务进度 |
| 查询书籍列表 | `references/api-books-list.md` | 获取已缓存书籍 |
| 获取章节详情 | `references/api-book-detail.md` | 获取单本书章节 |
| AI 解析流程 | `references/ai-analysis.md` | 章节分析 Prompt |
| 输出规范 | `references/output-spec.md` | 保存/同步/分享 |

---

## 📁 文档索引

### 数据采集 CLI 文档

1. **`references/api-fetch-cache.md`**
   - 命令：`python sanjiang.py fetch-cache [--max-chapters N]`
   - 功能：异步获取三江书单
   - 参数：max-chapters

2. **`references/api-task-status.md`**
   - 命令：`python sanjiang.py task-status <taskId>`
   - 功能：轮询任务状态
   - 状态：PENDING / RUNNING / COMPLETED / FAILED

3. **`references/api-books-list.md`**
   - 命令：`python sanjiang.py books [--book-name NAME] [--date DATE]`
   - 功能：查询书籍列表
   - 参数：book-name, date

4. **`references/api-book-detail.md`**
   - 命令：`python sanjiang.py book --book-name NAME [--author-name AUTHOR]`
   - 功能：获取章节详情
   - 参数：book-name, author-name

### AI 解析文档

5. **`references/ai-analysis.md`**
   - Step 5.0: 世界观解析
   - Step 5.1: 金手指提取
   - Step 5.2: 黄金一章剧情梗概
   - Step 5.3: 前三章分章梗概
   - Step 5.4: 前 N 章剧情梗概
   - Step 5.5: 推荐亮点提炼
   - Step 5.6: 生成 Markdown 报告

### 输出规范文档

6. **`references/output-spec.md`**
   - Step 6: 本地文件保存
   - Step 7: 生成分享图片（md2png）
   - Step 8: 同步到飞书文档

---

## 📊 数据结构

详见 `references/data-structures.md`

---

## ⚠️ 注意事项

1. **异步任务**: `fetch-cache` 在独立后台进程中执行，需要轮询任务状态
2. **章节限制**: `--max-chapters` 控制获取章节数，默认 20 章
3. **缓存机制**: 已缓存的书籍不会重复获取（存储在 `data/` 目录）
4. **日期自动计算**: 自动使用本周一作为期刊日期
5. **依赖安装**: 首次使用需 `pip install -r skills/sanjiang-analyzer/requirements.txt`

---

## 🔧 Token 优化策略

详见 `references/token-optimization.md`

---

## 🤖 子进程调用示例

### sessions_spawn 参数说明

```json
{
  "task": "处理《{书名}》的三江速评完整流程。\n\n请严格按照 skills/sanjiang-analyzer/SKILL.md 执行 Step 4-8：\n1. Step 4: 获取章节详情\n2. Step 5: AI解析报告（世界观、金手指、黄金一章、前3章、前20章、亮点）\n3. Step 6: 保存MD到 images/sanjiang/\n4. Step 7: 生成分享图片\n5. Step 8: 同步飞书文档\n\n⚠️ 每步完成后必须通知用户！",
  "runtime": "subagent",
  "mode": "run",
  "streamTo": "parent",
  "label": "三江速评-{书名}",
  "runTimeoutSeconds": 600
}
```

### 主会话调度伪代码

```javascript
// Step 1-3: 获取书籍列表
const books = await getBookList();

// 逐书处理
for (let i = 0; i < books.length; i++) {
    const book = books[i];

    // 通知用户
    await message({
        action: "send",
        message: `📖 开始处理《${book.name}》(${i + 1}/${books.length})`
    });

    // 启动独立子进程
    const result = await sessions_spawn({
        task: `处理《${book.name}》的三江速评...`,
        runtime: "subagent",
        mode: "run",
        streamTo: "parent",
        label: `三江速评-${book.name}`,
        runTimeoutSeconds: 600
    });

    // 子进程完成后通知
    await message({
        action: "send",
        message: `✅ 《${book.name}》处理完成 (${i + 1}/${books.length})`
    });
}

// 全部完成
await message({
    action: "send",
    message: `🎉 三江速评全部完成！共处理 ${books.length} 本书。`
});
```

---

*最后更新: 2026-04-02*
