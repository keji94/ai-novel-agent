# Step 9: 发布到小绿书（全自动）

所有书籍处理完成后（Step 8 全部结束），在主会话中直接调用 `md2wechat` 发布到小绿书，同时写信号文件作为记录。

---

## 9.1 收集并排序图片

收集 `images/sanjiang/` 目录下所有生成的分享图片，并按以下规则排序：

**排序规则（严格执行）**：
1. **题材优先级**：按 `category` 字段排序，热门题材放前面
   - 第一梯队：玄幻、仙侠、都市、历史
   - 第二梯队：科幻、游戏、悬疑、体育
   - 第三梯队：其他题材
2. **同书图片必须连续**：同一本书的 `_1.png`、`_2.png` 必须紧挨着放，不能被其他书的图片打断
3. **裁剪规则**：如果图片超过 20 张，从末尾的书开始整本移除（而不是拆散同一本书的图片）

```bash
# 列出所有图片文件
ls images/sanjiang/*_新书扫榜_*.png
```

**排序伪代码**：
```javascript
// 每本书的图片分组
const books = groupByBook(images);  // { "书名A": ["_1.png", "_2.png"], "书名B": ["_1.png"] }

// 按题材优先级排序书籍
const genrePriority = { "玄幻": 0, "仙侠": 1, "都市": 2, "历史": 3, "科幻": 4, "游戏": 5, "悬疑": 6, "体育": 7 };
books.sort((a, b) => (genrePriority[a.category] ?? 99) - (genrePriority[b.category] ?? 99));

// 从后往前整本移除，直到总图片数 <= 20
while (totalImages > 20) {
    books.pop();  // 移除优先级最低的整本书
}
```

**⚠️ 硬性规则**：同一本书的图片绝对不能被拆开！

---

## 9.2 生成导读说明（<1000字）

在发布前，生成一段少于 1000 字的导读说明，作为小绿书的文字描述（`--content` 参数）。

**导读内容结构**：
```
🔥 本期三江速评 | {YYYY年MM月DD日}

📊 本期共 {N} 本新书，覆盖 {题材列表}

{按题材分组，每组1-2句亮点概括}

💡 编辑推荐：《{书名}》— {一句话推荐理由}

#三江推荐 #网文推荐 #新书速递
```

**导读生成要求**：
- 从每本书的分析报告中提取亮点（Step 5 生成的推荐亮点）
- 按题材分组概括，突出热门题材
- 总字数严格控制在 1000 字以内
- 语气活泼，适合社交媒体传播

---

## 9.3 发布到小绿书

```bash
# 确保 PATH 包含 ~/bin
export PATH="$HOME/bin:$PATH"

# 通过 stdin 传入导读，图片按排序后的顺序逗号分隔
echo "$guide_text" | md2wechat create_image_post \
  -t "三江速评 {YYYY-MM-DD}" \
  --images "{img1_absolute_path},{img2_absolute_path},..." \
  --json
```

**如果 md2wechat 未找到**：
```bash
echo "$guide_text" | ~/bin/md2wechat create_image_post -t "标题" --images ... --json
```

**成功输出示例**：
```json
{
  "success": true,
  "code": "image_post_created",
  "data": {
    "media_id": "草稿media_id",
    "draft_url": "https://mp.weixin.qq.com/...",
    "image_count": 20,
    "uploaded_ids": ["img-media-id-1", ...]
  }
}
```

---

## 9.4 写入信号文件（记录）

发布成功后，将结果写入信号文件作为记录，内容工厂也可用于后续重新发布：

**信号文件路径**：
```
/Users/nieyi6/IdeaProjects/openclaw-content-factory/inbox/sanjiang-publish_{YYYYMMDD}.json
```

**信号文件格式**：
```json
{
  "type": "sanjiang-publish",
  "date": "YYYYMMDD",
  "title": "三江速评 YYYY-MM-DD",
  "images": [
    "/Users/nieyi6/IdeaProjects/ai-novel-agent/images/sanjiang/{书名}_新书扫榜_1.png",
    "/Users/nieyi6/IdeaProjects/ai-novel-agent/images/sanjiang/{书名}_新书扫榜_2.png"
  ],
  "books": [
    { "name": "书名", "category": "玄幻", "image_count": 2 },
    { "name": "书名", "category": "都市", "image_count": 2 }
  ],
  "guide_text": "导读说明全文...",
  "book_count": 10,
  "publish_result": {
    "media_id": "草稿media_id",
    "draft_url": "https://mp.weixin.qq.com/...",
    "image_count": 20
  },
  "created_at": "2026-04-03T10:30:00Z"
}
```

---

## 9.5 通知用户

```json
// 成功
{
  "action": "send",
  "channel": "feishu",
  "message": "📬 已发布到小绿书草稿箱（{N}张图片，{M}本书）链接：{draft_url}"
}

// 失败
{
  "action": "send",
  "channel": "feishu",
  "message": "❌ 小绿书发布失败：{error}，信号文件已保存，可到内容工厂手动重试"
}
```

---

## 9.6 注意事项

1. **执行位置**：Step 9 在主会话中执行，不在子进程中
2. **前置条件**：需确保 `md2wechat` 已安装（`~/bin/md2wechat`）且微信凭据已配置
3. **图片顺序**：热门题材在前 + 同书图片连续，违反任一规则需重新排序
4. **导读生成**：从 Step 5 的分析报告中提取亮点，不可凭空编造
5. **发布失败不影响主流程**：如果 md2wechat 调用失败，信号文件仍然写入，用户可到内容工厂手动重试
6. **幂等性**：同一日期的信号文件会覆盖，不会重复创建
