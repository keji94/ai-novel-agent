# 数据结构定义

## SanJiangBookSimpleInfo (书籍基本信息)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 数据库ID |
| bookName | String | 书名 |
| authorName | String | 作者名 |
| authorLevel | String | 作者等级 |
| category | String | 分类 |
| description | String | 简介 |
| coverUrl | String | 封面URL |
| detailUrl | String | 详情页URL |
| chapterCount | Integer | 章节数 |
| totalWords | Long | 总字数 |
| reportDate | LocalDate | 期刊日期 |
| createdAt | LocalDateTime | 创建时间 |

---

## Chapter (章节信息)

| 字段 | 类型 | 说明 |
|------|------|------|
| index | Integer | 章节序号 |
| title | String | 章节标题 |
| content | String | 章节内容 |

---

## TaskResponse (任务响应)

| 字段 | 类型 | 说明 |
|------|------|------|
| success | Boolean | 是否成功 |
| message | String | 提示信息 |
| taskId | String | 任务ID |
| reportDate | String | 期刊日期 |
| maxChapterCount | Integer | 最大章节数 |

---

## TaskStatusResponse (任务状态响应)

| 字段 | 类型 | 说明 |
|------|------|------|
| success | Boolean | 是否成功 |
| taskId | String | 任务ID |
| taskType | String | 任务类型 |
| state | String | 任务状态 (PENDING/RUNNING/COMPLETED/FAILED) |
| reportDate | String | 期刊日期 |
| totalBooks | Integer | 总书籍数 |
| processedBooks | Integer | 已处理书籍数 |
| successCount | Integer | 成功数 |
| failedCount | Integer | 失败数 |
| currentBookName | String | 当前处理书籍 |
| maxChapterCount | Integer | 最大章节数 |
| errorMessage | String | 错误信息 |
| createdAt | String | 创建时间 |
| startedAt | String | 开始时间 |
| completedAt | String | 完成时间 |
