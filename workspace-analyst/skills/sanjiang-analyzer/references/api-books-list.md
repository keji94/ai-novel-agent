# CLI: 查询书籍列表

## 命令

```bash
python sanjiang.py books [--book-name NAME] [--date DATE]
```

## 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| --book-name | string | 否 | 书名（支持模糊匹配） |
| --date | string | 否 | 日期（格式: YYYY-MM-DD，自动查找该日期所在周的周一） |

## 查询规则

```
1. 如果传了 --book-name → 按书名模糊查询
2. 如果没传 --book-name 但传了 --date → 查询该日期所在周的三江书籍
3. 如果都没传 → 默认查询最近一期（本周一）的三江书籍
```

## 使用示例

```bash
# 查询本期三江书单
python sanjiang.py books

# 按书名模糊查询
python sanjiang.py books --book-name 凡人

# 按日期查询
python sanjiang.py books --date 2025-12-23
```

## 输出 JSON

```json
{
  "success": true,
  "total": 20,
  "books": [
    {
      "bookName": "凡人修仙传",
      "authorName": "忘语",
      "authorLevel": "lv5",
      "category": "仙侠",
      "description": "一个普通山村少年的修仙之路...",
      "coverUrl": "https://...jpg",
      "detailUrl": "https://www.qidian.com/book/12345",
      "chapterCount": 10,
      "totalWords": 30000,
      "reportDate": "2025-12-23",
      "createdAt": "2025-12-20T10:05:00"
    }
  ]
}
```

## 注意事项

- 返回的书籍列表**不包含**章节内容（仅基本信息）
- 获取章节内容需使用 `book` 命令
- 数据存储在 `data/` 目录下的 JSON 文件中
