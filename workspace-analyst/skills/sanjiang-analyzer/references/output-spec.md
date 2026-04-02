# 输出规范

## 🔔 通知机制

**每个步骤完成后，必须使用 `message` 工具通知用户！**

### 通知模板

| 步骤 | 通知内容 | 示例 |
|------|---------|------|
| Step 6 | `💾 已保存《{书名}》报告到本地` | `💾 已保存《加载了怪猎模版的蓝龙》报告到本地` |
| Step 7 | `🖼️ 已生成《{书名}》分享图片（{N}张）` | `🖼️ 已生成《加载了怪猎模版的蓝龙》分享图片（2张）` |
| Step 8 | `📤 已同步《{书名}》到飞书：{链接}` | `📤 已同步《加载了怪猎模版的蓝龙》到飞书：https://...` |

### 通知代码示例

```json
// Step 6 保存后通知
{
  "action": "send",
  "channel": "feishu",
  "message": "💾 已保存《加载了怪猎模版的蓝龙》报告到本地"
}

// Step 7 生成图片后通知
{
  "action": "send",
  "channel": "feishu",
  "message": "🖼️ 已生成《加载了怪猎模版的蓝龙》分享图片（2张）地址路径:/xxx/xxx/..."
}

// Step 8 同步飞书后通知
{
  "action": "send",
  "channel": "feishu",
  "message": "📤 已同步《加载了怪猎模版的蓝龙》到飞书：https://www.feishu.cn/docx/xxx"
}
```

---

## Step 6: 本地文件保存

生成报告后，必须将 Markdown 内容保存到本地文件。

**存储路径**：
```
{项目根目录}/images/sanjiang/
```

**文件命名规则**：
```
{书名}_新书扫榜.md
```

**示例**：
- 《什么叫我与妹卡有缘？》→ `什么叫我与妹卡有缘？_新书扫榜.md`
- 《凡人修仙传》→ `凡人修仙传_新书扫榜.md`

**⚠️ 保存后必须通知**：
```json
{
  "action": "send",
  "channel": "feishu",
  "message": "💾 已保存《{书名}》报告到本地"
}
```

---

## Step 7: 生成分享图片

Markdown 报告保存后，使用 md2png 工具生成分享图片。

**工具路径**：`skills/md2png/md2png/md2png.js`

**输出目录**：`{项目根目录}/images/sanjiang/`

**执行命令**：
```bash
node skills/md2png/md2png/md2png.js \
  images/sanjiang/{书名}_新书扫榜.md \
  images/sanjiang/
```

**输出文件**：
- `{书名}_新书扫榜_1.png`（第一页）
- `{书名}_新书扫榜_2.png`（第二页，如有）
- ...

**注意事项**：
1. Windows 环境自动使用系统 Edge 浏览器，无需手动安装 Chromium
2. 图片宽度 1080px，小红书风格配色
3. 智能分页为两张图（图1: 书名+简介+世界观+金手指+黄金一章，图2: 剧情梗概+亮点）

**⚠️ 生成后必须通知**：
```json
{
  "action": "send",
  "channel": "feishu",
  "message": "🖼️ 已生成《{书名}》分享图片（{N}张）"
}
```

---

## Step 8: 同步到飞书文档

生成分享图片后，同步到飞书文档，便于团队协作和知识沉淀。

**目标知识库**：网文成神笔记

**目标分类**：新书扫榜

**操作步骤**：

### 8.1 创建飞书文档
1. 使用 `feishu_create_doc` 工具创建飞书文档
2. 文档标题：`【{书名}】三江速评`
3. 将 Markdown 内容作为文档正文
4. 获取返回的 `doc_id`

### 8.2 插入分享图片（必须执行！）
创建文档后，**必须**使用 `feishu_doc_media` 工具将生成的分享图片插入文档末尾：

```json
// 插入第一张图片
{
  "action": "insert",
  "doc_id": "{doc_id}",
  "file_path": "images/sanjiang/{书名}_新书扫榜_1.png",
  "type": "image",
  "align": "center",
  "caption": "《{书名}》三江速评 - 第1页"
}

// 如果有第二张图片，继续插入
{
  "action": "insert",
  "doc_id": "{doc_id}",
  "file_path": "images/sanjiang/{书名}_新书扫榜_2.png",
  "type": "image",
  "align": "center",
  "caption": "《{书名}》三江速评 - 第2页"
}
```

**⚠️ 重要提醒**：
- 图片文件名格式固定为 `{书名}_新书扫榜_1.png` 和 `{书名}_新书扫榜_2.png`
- 飞书媒体上传只接受 `/tmp/` 目录下的文件，需要先复制图片：
  ```bash
  cp images/sanjiang/{书名}_新书扫榜_*.png /tmp/
  ```
- 然后使用 `/tmp/` 下的路径调用 `feishu_doc_media`

### 8.3 返回文档链接
全部完成后，返回文档链接。

**操作指令**：
```
1. 使用 feishu_create_doc 工具创建飞书文档：
   - 标题：【{书名}】三江速评
   - 内容：{完整的 Markdown 报告}
   - 知识库：网文成神笔记
   - 分类：新书扫榜

2. 复制图片到 /tmp/：
   cp images/sanjiang/{书名}_新书扫榜_*.png /tmp/

3. 使用 feishu_doc_media 工具插入图片：
   - doc_id: {创建文档返回的 doc_id}
   - file_path: /tmp/{书名}_新书扫榜_1.png
   - type: image
   - align: center
   - caption: 《{书名}》三江速评 - 第1页

4. 如果有第二张图片，重复步骤3

5. 返回最终文档链接
```

**⚠️ 同步后必须通知**：
```json
{
  "action": "send",
  "channel": "feishu",
  "message": "📤 已同步《{书名}》到飞书：{doc_url}"
}
```

---

## 📋 完整工作流程总结

| 步骤 | 操作 | 工具 | 通知 | 状态 |
|------|------|------|------|------|
| Step 1 | 触发异步任务 | `python sanjiang.py fetch-cache` | - | 必须 |
| Step 2 | 轮询任务状态 | `python sanjiang.py task-status <id>` | - | 必须 |
| Step 3 | 获取书籍列表 | `python sanjiang.py books` | - | 必须 |
| Step 4 | 获取章节详情 | `python sanjiang.py book --book-name <名>` | 📖 正在获取... | 必须 |
| Step 5 | AI 解析报告 | 见 ai-analysis.md | 🤖 正在分析... | 必须 |
| Step 6 | 保存本地文件 | write 工具 | 💾 已保存 | ⚠️ 必须执行 |
| Step 7 | 生成分享图片 | node md2png | 🖼️ 已生成 | ⚠️ 必须执行 |
| Step 8 | 同步飞书文档 | feishu_create_doc | 📤 已同步 | ⚠️ 最后执行 |

**执行顺序**：Step 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8（严格按序执行）

**关键提醒**：
- Step 6-8 不可跳过，必须依次完成！图片必须写入飞书文档且图片名字必须为{书名}_1.png{书名}_2.png
- 每个步骤完成后必须通知用户！
- 批量处理时，每本书开始时发送 "📖 开始处理《{书名}》({当前}/{总数})"
