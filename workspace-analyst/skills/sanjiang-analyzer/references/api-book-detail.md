# CLI: 获取书籍章节详情

## 命令

```bash
python sanjiang.py book --book-name <书名> [--author-name <作者>]
```

## 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| --book-name | string | 是 | 书名（支持模糊匹配） |
| --author-name | string | 否 | 作者名（用于精确匹配） |

## 使用示例

```bash
# 仅按书名查询
python sanjiang.py book --book-name 凡人修仙传

# 按书名+作者精确查询
python sanjiang.py book --book-name 凡人修仙传 --author-name 忘语
```

## 输出 JSON

```json
{
  "success": true,
  "bookName": "凡人修仙传",
  "authorName": "忘语",
  "authorLevel": "lv5",
  "category": "仙侠",
  "chapterCount": 10,
  "totalWords": 30000,
  "coverUrl": "https://...jpg",
  "description": "一个普通山村少年的修仙之路...",
  "reportDate": "2025-12-23",
  "createdAt": "2025-12-20T10:05:00",
  "chapters": [
    {
      "index": 1,
      "title": "第一章 山村少年",
      "content": "韩立出生在一个偏僻的小山村..."
    },
    {
      "index": 2,
      "title": "第二章 离家",
      "content": "清晨的阳光洒在山村..."
    }
  ]
}
```

## 注意事项

- **作者精确匹配**: 如有同名书籍，建议传入 --author-name 进行精确匹配
- **章节数量**: 返回的章节数量由 fetch-cache 时的 --max-chapters 参数决定
- 返回的 `chapters` 包含完整的章节内容，数据量较大
