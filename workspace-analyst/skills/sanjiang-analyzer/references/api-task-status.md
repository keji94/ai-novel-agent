# CLI: 查询任务状态

## 命令

```bash
python sanjiang.py task-status <taskId>
```

## 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| taskId | string | 是 | 任务ID（fetch-cache 返回的 taskId） |

## 使用示例

```bash
python sanjiang.py task-status a1b2c3d4e5f6g7h8
```

## 输出 JSON

```json
{
  "success": true,
  "taskId": "a1b2c3d4e5f6g7h8",
  "taskType": "FETCH_AND_CACHE",
  "state": "RUNNING",
  "reportDate": "2025-12-23",
  "totalBooks": 20,
  "processedBooks": 8,
  "successCount": 7,
  "failedCount": 1,
  "currentBookName": "凡人修仙传",
  "maxChapterCount": 20,
  "errorMessage": null,
  "createdAt": "2025-12-20T10:00:00",
  "startedAt": "2025-12-20T10:00:01",
  "completedAt": null
}
```

## 状态说明

| 状态 | 说明 |
|------|------|
| PENDING | 任务等待中 |
| RUNNING | 任务执行中 |
| COMPLETED | 任务完成 |
| FAILED | 任务失败 |

## 轮询策略

```
推荐轮询间隔: 10-15秒

轮询终止条件:
- state == "COMPLETED" → 任务成功完成
- state == "FAILED" → 任务失败，检查 errorMessage
```

## 错误处理

| 错误场景 | 输出 | 处理方式 |
|---------|------|---------|
| 任务不存在 | `{"success": false, "message": "任务不存在"}` | 检查taskId是否正确 |
| 任务执行失败 | state=FAILED | 检查 errorMessage 字段 |
