# 规则3.1: 学习范文技巧流程

```
条件: 用户分享链接/内容要学习写作技巧
触发: 检测到URL / "学习这个" / 用户提供范文
```

## 六步闭环

```
Step 0: 创建状态文件
  写入 temp/learning_pipeline_{timestamp}.json:
  {
    "id": "lp_{timestamp}",
    "source": "URL或描述",
    "platform": "zhihu|weixin|douyin|other",
    "status": "extracting",  // extracting → reviewing → storing → verifying → done
    "created_at": "ISO8601",
    "steps": {
      "extract": { "status": "in_progress", "result_file": null },
      "review":  { "status": "pending", "result_file": null },
      "store":   { "status": "pending", "stored_count": 0 },
      "verify":  { "status": "pending" }
    }
  }

Step 1: 识别平台 (zhihu→知乎, mp.weixin→微信, douyin→抖音)

Step 2: sessions_spawn("analyst", parse_and_extract) → extracted_tips
  ✅ 成功 → 更新状态 status="reviewing", steps.extract.status="done"
  ❌ 失败 → 更新状态 steps.extract.status="failed"，通知用户

Step 3: sessions_spawn("editor", knowledge_review_1st_pass) → APPROVE/MERGE/REJECT
  ✅ 成功 → 更新状态 status="storing"
  ❌ 失败 → 更新状态 steps.review.status="failed"，通知用户

Step 4: sessions_spawn("learner", merge_and_store, 仅APPROVE+MERGE) → stored_items
  ✅ 成功 → 更新状态 status="verifying"
  ❌ 失败 → 更新状态 steps.store.status="failed"，通知用户

Step 5: sessions_spawn("editor", knowledge_review_2nd_pass) → 一致性检查
  ✅ 成功 → 更新状态 status="done"
  ❌ 失败 → 更新状态 steps.verify.status="failed"，通知用户

Step 6: 返回学习结果（提取X条，通过Y条，拒绝W条，更新分类）
  清理: 删除 temp/learning_pipeline_{id}.json（保留 result_file）
```

## 断裂恢复机制

- 每次会话启动时，检查 `temp/learning_pipeline_*.json` 中 status != "done" 的文件
- 找到卡住的流程 → 读取最后完成的步骤 → 从下一步继续
- 恢复时通知用户："检测到上次未完成的学习流程（{source}），将从{步骤名}继续"

## 平台识别

| URL 模式 | 平台 |
|---------|------|
| zhihu.com/question/*/answer | 知乎回答 |
| zhuanlan.zhihu.com/p/* | 知乎专栏 |
| mp.weixin.qq.com/s/* | 微信公众号 |
| douyin.com/video/* | 抖音 |

## 反馈路由

Editor审核章节时附带 knowledge_feedback → 路由到 Learner process_feedback。Writer 报告 report_technique_feedback → 同上。
