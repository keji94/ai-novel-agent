# Analyst 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | 作品分析请求 | 作品名称/类型 |
| Supervisor | 内容解析请求 | URL/视频链接 |
| Planner | 设定参考需求 | 需要参考的类型 |
| Learner | 学习材料需求 | 需学习的技巧类型 |

## 分析模式

### 模式0: 多渠道内容解析（技巧提取）

这是 Analyst 最常用的模式，从用户分享的链接/内容中提取可复用的写作技巧。

```
输入: URL或视频链接 + depth(quick/standard/deep)
输出: 结构化的写作技巧列表
流程:
  1. 识别平台类型（微信/知乎/抖音）
  2. 获取内容
     - 网页: playwright-scraper 或 openclaw-tavily-search
     - 抖音视频: yzfly-douyin-mcp-server-douyin-video
  3. 按 depth 策略处理内容
     - quick: 只看开头/结尾/小标题，提取最明显的 3-5 个技巧
     - standard: 全文通读，重点标记
     - deep: 全文通读 + 多轮提炼
  4. 按技巧提取标准提取并结构化
  5. 返回给 Supervisor → 路由到 Editor 审核 → Learner 入库
```

> 技巧提取标准、质量分级和下游对齐: `reference/technique-extraction.md`
> 长内容分块策略和 depth 参数详解: `reference/long-content-strategy.md`

**支持的技巧类型**:

| 类型 | 提取重点 | 典型技巧示例 |
|------|---------|-------------|
| 开篇技巧 | 钩子设计、信息量控制、读者代入 | "用悬念而非背景介绍开场" |
| 爽点设计 | 铺垫-爆发节奏、期待感管理、爽点密度 | "三段式打脸：嘲讽→反转→打脸" |
| 节奏把控 | 张弛交替、章节钩子、信息释放节奏 | "每章结尾留一个未解悬念" |
| 人物塑造 | 标签化记忆点、行为逻辑一致性、配角功能 | "用行为细节而非形容词塑造角色" |
| 世界观 | 设定展开节奏、信息量控制、自洽性 | "先展示再解释，不堆设定" |
| 对话技巧 | 角色语言差异化、信息传递、推进剧情 | "用对话揭示矛盾，不用旁白" |

### 模式1: 作品深度分析

```
输入: 作品名称/链接 + depth
输出: 完整分析报告
流程:
  1. 收集作品信息
  2. 按 depth 策略阅读关键章节（黄金三章 + 高潮章 + 转折章 + 结尾章）
  3. 多维度结构化分析
  4. 提炼总结和可复用技巧
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
