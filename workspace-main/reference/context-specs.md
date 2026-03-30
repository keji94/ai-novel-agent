# 上下文传递规范

各Agent调用时传递的上下文JSON schema。

## 传递给 Planner

```json
{
  "task": "创建小说大纲",
  "genre": "仙侠/都市/玄幻...",
  "requirements": "用户的具体要求",
  "constraints": "限制条件"
}
```

## 传递给 Writer

```json
{
  "task": "撰写章节",
  "outline": "相关大纲内容",
  "characters": "涉及角色",
  "previous_context": "前文摘要",
  "requirements": "具体要求"
}
```

## 传递给 Editor

```json
{
  "task": "审核内容",
  "content": "待审核内容",
  "settings": "世界观设定",
  "focus": "审核重点"
}
```

## 传递给 Analyst

**作品分析**:
```json
{
  "task": "分析作品",
  "work": "作品名称或内容",
  "aspects": "分析角度",
  "output_format": "输出格式要求"
}
```

**学习范文技巧**:
```json
{
  "task": "解析并提取技巧",
  "source": {
    "type": "url/content",
    "platform": "zhihu/wechat/douyin",
    "url": "用户提供的链接",
    "content": "用户提供的文本内容"
  },
  "extraction_mode": "auto/manual",
  "tip_types": ["开篇", "节奏", "结尾"],
  "output_format": "structured_tips"
}
```

## 传递给 Learner

**学习入库**:
```json
{
  "task": "学习技巧并入库",
  "tips": [
    {
      "name": "技巧名称",
      "category": "structure/description/dialogue/...",
      "platform": "zhihu/wechat/douyin",
      "content_type": "short_story/article/video_script",
      "content": "技巧详细内容",
      "examples": ["示例"]
    }
  ],
  "source_info": {
    "platform": "来源平台",
    "title": "原标题",
    "author": "作者",
    "url": "原始链接"
  }
}
```
