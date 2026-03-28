# Learner 协作流程定义

## 任务来源

| 来源 | 任务类型 | 输入内容 |
|------|----------|----------|
| Supervisor | 学习请求 | 技巧主题 |
| Analyst | 分析结果 | 作品分析 |
| Analyst | 多渠道解析结果 | 文章/视频提取的技巧 |
| Writer | 技巧咨询 | 具体问题 |
| Planner | 最佳实践 | 类型相关 |

## 工作模式

### 模式1: 技巧教学

```
输入: 技巧主题
输出: 技巧文档
流程:
  1. 检索知识库
  2. 整理核心要点
  3. 准备案例
  4. 生成文档
```

### 模式2: 问题解答

```
输入: 具体问题
输出: 解答和建议
流程:
  1. 分析问题
  2. 检索相关知识
  3. 给出解答
  4. 提供练习建议
```

### 模式3: 分析提炼

```
输入: Analyst的分析结果
输出: 技巧总结
流程:
  1. 阅读分析报告
  2. 提取可学习点
  3. 归纳技巧
  4. 形成文档
```

### 模式4: 多渠道学习（新增）

```
输入: 多渠道解析结果（文章/视频）
输出: 技巧库更新 + 学习报告
流程:
  1. 接收 Analyst 解析的技巧
  2. 评估技巧价值和学习优先级
  3. 使用 update_skill_library 更新技巧库
  4. 建立与现有知识的关联
  5. 生成学习报告和应用建议
```

**支持的多渠道来源**:
- 微信公众号文章
- 知乎文章/回答
- 抖音视频内容

## 协作接口

### 接收任务

```json
{
  "task": "学习技巧",
  "topic": "开篇写作",
  "level": "beginner/intermediate/advanced",
  "format": "document/guide/quick_tips"
}
```

### 接收 Analyst 输入

**作品分析结果**:
```json
{
  "source": "analyst",
  "work": "作品名",
  "analysis": {
    "techniques": [...],
    "patterns": [...],
    "highlights": [...]
  },
  "extract_request": "提取可学习的技巧"
}
```

**多渠道解析结果**:
```json
{
  "source": "analyst_multi_channel",
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
  "action": "learn_and_update"
}
```

### 输出结果

```json
{
  "status": "completed",
  "document": {
    "title": "技巧标题",
    "overview": "概述",
    "key_points": [...],
    "examples": [...],
    "common_mistakes": [...],
    "practice_suggestions": [...]
  },
  "related_topics": ["相关主题"]
}
```

## 技能库结构

### 基础技能

| 技能 | 说明 | 重要度 |
|------|------|--------|
| 开篇技巧 | 黄金三章、钩子设计 | ★★★★★ |
| 节奏把控 | 高潮低谷、期待感 | ★★★★★ |
| 爽点设计 | 打脸、升级、收获 | ★★★★★ |
| 人物塑造 | 主角、配角、反派 | ★★★★☆ |
| 描写能力 | 场景、动作、心理 | ★★★★☆ |
| 对话技巧 | 角色语言、信息传递 | ★★★☆☆ |

### 进阶技能

| 技能 | 说明 | 重要度 |
|------|------|--------|
| 伏笔设计 | 埋设、揭示、回收 | ★★★★☆ |
| 反转技巧 | 意外、惊喜、震撼 | ★★★★☆ |
| 世界观构建 | 设定、体系、规则 | ★★★★☆ |
| 群像描写 | 多角色、多线并进 | ★★★☆☆ |
| 感情线 | CP、冲突、发展 | ★★★☆☆ |

## 输出给其他Agent

### 给 Writer

```json
{
  "techniques": {
    "topic": "战斗场景",
    "key_points": ["动作设计", "节奏控制", "画面感"],
    "examples": [...],
    "tips": ["技巧一", "技巧二"]
  }
}
```

### 给 Planner

```json
{
  "best_practices": {
    "genre": "仙侠",
    "setting_tips": [...],
    "character_tips": [...],
    "outline_tips": [...]
  }
}
```