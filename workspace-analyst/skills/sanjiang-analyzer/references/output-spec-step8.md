# Step 8: 同步到飞书文档

生成分享图片后，同步到飞书文档，便于团队协作和知识沉淀。

**目标知识库**：网文成神笔记

**目标分类**：新书扫榜

---

## 8.1 创建飞书文档

1. 使用 `feishu_create_doc` 工具创建飞书文档
2. 文档标题：`【{书名}】三江速评`
3. 将 Markdown 内容作为文档正文
4. 获取返回的 `doc_id`

## 8.2 插入分享图片（必须执行！）

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

## 8.3 操作指令模板

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
