# CLI: 触发异步获取三江书单

## 命令

```bash
python sanjiang.py fetch-cache [--max-chapters N]
```

## 参数

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| --max-chapters | int | 否 | 20 | 最大章节数，0获取所有免费章节 |

## 输出示例

```bash
# 使用默认值（前20章）
python sanjiang.py fetch-cache

# 获取前50章（深度分析用）
python sanjiang.py fetch-cache --max-chapters 50
```

## 输出 JSON

```json
{
  "success": true,
  "message": "任务已创建，请通过taskId查询执行状态",
  "taskId": "a1b2c3d4e5f6g7h8",
  "reportDate": "2025-12-23",
  "maxChapterCount": 20
}
```

## 处理逻辑

```
1. 自动计算本周一日期作为期刊日期
2. 创建异步任务（独立后台进程），返回任务ID
3. 后台异步执行：
   a. 从起点图爬取三江书单
   b. 遍历每本书，从QQ阅读获取章节内容
   c. 缓存到 data/ 目录
4. 通过 task-status 命令轮询任务状态
```

## 注意事项

- **默认获取 20 章**，确保"前20章剧情梗概"分析有足够数据
- 20 章已足够完成世界观、金手指、剧情节奏的全部分析
- 获取更多章节会增加采集时间，按需调整
- 任务在独立进程中执行，主进程退出不影响后台采集
- 任务日志: `data/tasks/{taskId}.log`
