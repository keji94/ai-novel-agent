# 主会话调度伪代码

完整的主会话调度流程，包含题材筛选、逐书处理、小绿书发布。

---

## Step 1-3: 获取书籍列表 + 题材筛选

```javascript
// Step 1-3: 获取书籍列表
const allBooks = await getBookList();

// Step 3.5: 按题材优先级筛选，取前 10 本
const genrePriority = { "玄幻": 0, "仙侠": 1, "都市": 2, "历史": 3, "科幻": 4, "游戏": 5, "悬疑": 6, "体育": 7 };
allBooks.sort((a, b) => (genrePriority[a.category] ?? 99) - (genrePriority[b.category] ?? 99));
const books = allBooks.slice(0, 10);  // 一期约17本，只取前10本热门题材

// 通知用户筛选结果
await message({
    action: "send",
    message: `📋 本期三江共 ${allBooks.length} 本，已按题材优先级选取 ${books.length} 本：${books.map(b => `《${b.bookName}》(${b.category})`).join("、")}`
});

const filteredOut = allBooks.slice(10);
if (filteredOut.length > 0) {
    await message({
        action: "send",
        message: `⏭️ 已跳过：${filteredOut.map(b => `《${b.bookName}》(${b.category})`).join("、")}`
    });
}
```

---

## 逐书处理（Step 4-8 子进程）

```javascript
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

## Step 9: 发布到小绿书（全自动）

```javascript
// 9.1 收集图片并按书分组
const allImages = glob("images/sanjiang/*_新书扫榜_*.png");
const bookGroups = groupByBook(allImages);

// 9.2 按题材优先级排序：玄幻/仙侠/都市/历史放前面
const genrePriority = { "玄幻": 0, "仙侠": 1, "都市": 2, "历史": 3, "科幻": 4, "游戏": 5, "悬疑": 6, "体育": 7 };
bookGroups.sort((a, b) => (genrePriority[a.category] ?? 99) - (genrePriority[b.category] ?? 99));

// 9.3 超过20张时从末尾整本移除（不拆散同一本书的图片）
let totalImages = bookGroups.reduce((sum, g) => sum + g.images.length, 0);
while (totalImages > 20) {
    const removed = bookGroups.pop();
    totalImages -= removed.images.length;
}
const sortedImages = bookGroups.flatMap(g => g.images);
const imagePaths = sortedImages.map(img => path.resolve(img)).join(",");
const date = formatDate(new Date(), "YYYY-MM-DD");
const dateCompact = formatDate(new Date(), "YYYYMMDD");

// 9.4 生成导读说明（<1000字，从分析报告中提取亮点）
const guideText = generateGuide({
    date, bookGroups,
    totalBooks: books.length,
    genres: [...new Set(bookGroups.map(g => g.category))],
    highlights: bookGroups.map(g => ({ name: g.bookName, category: g.category, highlight: g.highlight }))
});
// guideText 示例：
// 🔥 本期三江速评 | 2026-04-03
// 📊 共 10 本新书，覆盖 玄幻/仙侠/都市
// 【玄幻】《书名》— 亮点概括...
// 【都市】《书名》— 亮点概括...
// 💡 编辑推荐：《书名》— 一句话理由
// #三江推荐 #网文推荐

// 9.5 发布（通过 stdin 传入导读）
const result = exec(`echo '${escapeShell(guideText)}' | ~/bin/md2wechat create_image_post -t "三江速评 ${date}" --images "${imagePaths}" --json`);

// 9.6 写入信号文件
const signal = {
    type: "sanjiang-publish", date: dateCompact,
    title: `三江速评 ${date}`,
    books: bookGroups.map(g => ({ name: g.bookName, category: g.category, image_count: g.images.length })),
    images: sortedImages.map(img => path.resolve(img)),
    guide_text: guideText,
    book_count: bookGroups.length,
    publish_result: result.success ? { media_id: result.data.media_id, draft_url: result.data.draft_url } : null,
    created_at: new Date().toISOString()
};
writeFile(`/Users/nieyi6/IdeaProjects/openclaw-content-factory/inbox/sanjiang-publish_${dateCompact}.json`, JSON.stringify(signal, null, 2));

await message({
    action: "send",
    message: result.success
        ? `📬 已发布到小绿书草稿箱（${sortedImages.length}张图片，${bookGroups.length}本书）链接：${result.data.draft_url}`
        : `❌ 小绿书发布失败：${result.error}，信号文件已保存，可到内容工厂手动重试`
});
```
