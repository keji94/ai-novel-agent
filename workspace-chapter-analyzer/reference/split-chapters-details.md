# split_chapters 详细实现

> 主文件: TOOLS.md 工具 4

## 拆分规则

| 模式 | 正则 | 示例 |
|------|------|------|
| 中文默认 | `第[零一二三四五六七八九十百千]+章` | 第一章、第十零章 |
| 中文数字 | `第\d+章` | 第1章、第100章 |
| 英文默认 | `Chapter\s+\d+` | Chapter 1, Chapter 100 |
| 自定义 | 用户提供正则 | 用户指定 |

## 实现

```python
def split_chapters(content, mode="chinese"):
    patterns = {
        "chinese": r'第[零一二三四五六七八九十百千]+章[^\n]*',
        "chinese_num": r'第\d+章[^\n]*',
        "english": r'Chapter\s+\d+[^\n]*',
        "custom": None  # 用户提供
    }

    pattern = patterns.get(mode, mode)

    # 查找所有章节标题
    matches = list(re.finditer(pattern, content))

    chapters = []
    for i, match in enumerate(matches):
        start = match.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)

        chapter_title = match.group().strip()
        chapter_content = content[start:end].strip()

        chapters.append({
            "number": i + 1,
            "title": chapter_title,
            "content": chapter_content
        })

    return chapters
```

## 调用示例

```json
// Step 1: 读取文件
content = read({"path": "./source/novel.txt"})

// Step 2: 拆分章节
chapters = split_chapters(content, "chinese")

// Step 3: 保存各章节
for chapter in chapters:
    write({
        "path": f"./novels/仙道长生/chapters/chapter_{chapter['number']:03d}.md",
        "content": chapter['content']
    })
```
