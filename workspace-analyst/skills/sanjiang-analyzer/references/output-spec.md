# 输出规范

## 🔔 通知机制

**每个步骤完成后，必须使用 `message` 工具通知用户！**

### 通知模板

| 步骤 | 通知内容 | 示例 |
|------|---------|------|
| Step 6 | `💾 已保存《{书名}》报告到本地` | `💾 已保存《加载了怪猎模版的蓝龙》报告到本地` |
| Step 7 | `🖼️ 已生成《{书名}》分享图片（{N}张）` | `🖼️ 已生成《加载了怪猎模版的蓝龙》分享图片（2张）` |
| Step 8 | `📤 已同步《{书名}》到飞书：{链接}` | `📤 已同步《加载了怪猎模版的蓝龙》到飞书：https://...` |
| Step 9 | `📬 已发布到小绿书草稿箱（{N}张图片）链接：{url}` | `📬 已发布到小绿书草稿箱（20张图片）链接：https://mp.weixin.qq.com/...` |

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
2. 图片宽度 1080px（2x 缩放实际输出 2160px/2K 高清），小红书风格配色
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

> 📖 **详细步骤见 `references/output-spec-step8.md`**

创建飞书文档并插入分享图片。知识库：网文成神笔记，分类：新书扫榜。

**⚠️ 关键提醒**：创建文档后**必须插入分享图片**！图片需先复制到 `/tmp/` 目录。

---

## Step 9: 发布到小绿书（全自动）

> 📖 **详细步骤见 `references/output-spec-step9.md`**

所有书处理完成后，在主会话中直接调用 `md2wechat create_image_post` 发布到小绿书。

**核心规则**：
- 按题材优先级排序（玄幻/仙侠/都市/历史放前面）
- 同一本书的图片必须连续排列
- 生成 <1000 字导读说明
- 信号文件写入内容工厂 inbox/ 作为记录

---

## 📋 完整工作流程总结

| 步骤 | 操作 | 工具 | 通知 | 状态 |
|------|------|------|------|------|
| Step 1 | 触发异步任务 | `python sanjiang.py fetch-cache` | - | 必须 |
| Step 2 | 轮询任务状态 | `python sanjiang.py task-status <id>` | - | 必须 |
| Step 3 | 获取书籍列表 | `python sanjiang.py books` | - | 必须 |
| Step 3.5 | 题材筛选 | `sort + slice(0,10)` | 📋 已选取 | 必须 |
| Step 4 | 获取章节详情 | `python sanjiang.py book --book-name <名>` | 📖 正在获取... | 必须 |
| Step 5 | AI 解析报告 | 见 ai-analysis.md | 🤖 正在分析... | 必须 |
| Step 6 | 保存本地文件 | write 工具 | 💾 已保存 | ⚠️ 必须执行 |
| Step 7 | 生成分享图片 | node md2png | 🖼️ 已生成 | ⚠️ 必须执行 |
| Step 8 | 同步飞书文档 | 见 output-spec-step8.md | 📤 已同步 | ⚠️ 必须执行 |
| Step 9 | 发布小绿书 | 见 output-spec-step9.md | 📬 已发布 | 主会话自动执行 |

**执行顺序**：Step 1 → 2 → 3 → 3.5 → 4 → 5 → 6 → 7 → 8 → 9（严格按序执行）

**关键提醒**：
- Step 6-8 不可跳过，必须依次完成！
- 每个步骤完成后必须通知用户！
- 批量处理时，每本书开始时发送 "📖 开始处理《{书名}》({当前}/{总数})"
- **Step 9 在主会话中执行**（不在子进程中），所有书处理完成后再触发
