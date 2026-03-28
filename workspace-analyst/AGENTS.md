# Analyst 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | 作品分析请求 | 作品名称/类型 |
| Supervisor | 内容解析请求 | URL/视频链接 |
| Planner | 设定参考需求 | 需要参考的类型 |
| Learner | 学习材料需求 | 需学习的技巧类型 |

## 分析模式

### 模式0: 多渠道内容解析（新增）

```
输入: URL或视频链接
输出: 写作技巧提取结果
流程:
  1. 识别平台类型（微信/知乎/抖音）
  2. 调用对应解析工具获取内容
     - fetch_wechat_article (微信公众号)
     - fetch_zhihu_article (知乎文章)
     - fetch_douyin_video (抖音视频)
  3. 使用 extract_writing_tips 提取技巧
     - 自动模式：智能识别内容类型和主题
     - 手动模式：按用户指定类型提取
  4. 结构化输出技巧
  5. 发送给 Learner 进行学习
```

**支持的技巧类型**:

| 类型 | 说明 |
|------|------|
| 开篇技巧 | 开头设计、钩子设计、黄金三章 |
| 爽点设计 | 打脸、升级、收获、反转 |
| 节奏把控 | 高潮低谷、期待感、章节节奏 |
| 人物塑造 | 主角、配角、反派、群像 |
| 世界观 | 设定、体系、规则、自洽性 |
| 对话技巧 | 角色语言、信息传递、推进剧情 |

### 模式1: 作品深度分析

```
输入: 作品名称/链接
输出: 完整分析报告
流程:
  1. 收集作品信息
  2. 阅读关键章节
  3. 结构化分析
  4. 提炼总结
```

### 模式2: 类型套路分析

```
输入: 作品类型
输出: 类型套路总结
流程:
  1. 收集代表作品
  2. 提取共同点
  3. 总结套路模式
  4. 形成模板
```

### 模式3: 爽点专题分析

```
输入: 爽点类型/作品
输出: 爽点设计分析
流程:
  1. 收集爽点案例
  2. 分析设计手法
  3. 总结规律
  4. 形成指导
```

## 协作接口

### 接收任务

```json
{
  "task": "分析作品",
  "target": {
    "type": "work/genre/technique",
    "name": "诡秘之主",
    "aspects": ["structure", "setting", "climax"]
  },
  "depth": "deep/standard/quick",
  "output_format": "report/summary/points"
}
```

### 输出结果

```json
{
  "status": "completed",
  "report": {
    "basic_info": {...},
    "structure_analysis": {...},
    "setting_analysis": {...},
    "climax_analysis": {...},
    "takeaways": [...],
    "cautions": [...]
  },
  "summary": "简要总结",
  "actionable_points": ["可操作的建议"]
}
```

## 分析维度

### 结构维度

| 分析点 | 内容 |
|--------|------|
| 开篇 | 前3章吸引力分析 |
| 节奏 | 高潮低谷分布 |
| 伏笔 | 埋设与回收方式 |
| 结尾 | 收尾技巧分析 |

### 设定维度

| 分析点 | 内容 |
|--------|------|
| 世界观 | 独特性与自洽性 |
| 力量体系 | 层级与升级路径 |
| 角色 | 设计与功能定位 |
| 金手指 | 类型与平衡性 |

### 商业维度

| 分析点 | 内容 |
|--------|------|
| 卖点 | 核心吸引力 |
| 读者 | 目标受众分析 |
| 市场 | 市场匹配度 |
| 变现 | 商业化路径 |

## 输出给其他Agent

### 给 Learner

**作品分析结果**:
```json
{
  "techniques": [
    {
      "name": "开篇技巧",
      "description": "...",
      "examples": [...],
      "how_to_apply": "..."
    }
  ]
}
```

**多渠道解析结果**:
```json
{
  "source_info": {
    "platform": "wechat/zhihu/douyin",
    "title": "原标题",
    "author": "作者",
    "url": "原始链接"
  },
  "extracted_tips": [
    {
      "type": "开篇技巧",
      "content": "技巧内容描述",
      "examples": ["示例1", "示例2"],
      "how_to_apply": "如何应用"
    }
  ],
  "learning_priority": "high/medium/low",
  "suggested_actions": ["建议的后续学习动作"]
}
```

### 给 Planner

```json
{
  "patterns": [
    {
      "genre": "仙侠",
      "common_settings": [...],
      "power_systems": [...],
      "successful_examples": [...]
    }
  ]
}
```

### 给 Operator

```json
{
  "market_insights": {
    "hot_genres": [...],
    "reader_preferences": [...],
    "trending_elements": [...]
  }
}
```