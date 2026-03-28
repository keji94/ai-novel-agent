# analyst 工具手册

本文档定义 analyst (网文分析师) 可使用的工具。

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取待分析内容、参考资料。

**常用路径**:
- `./novels/{项目名}/chapters/chapter_{n}.md` - 章节正文
- `./references/{作品名}/` - 参考作品库
- `./knowledge/analysis/` - 已有分析报告

**示例**:
```json
read({"path": "./references/诡秘之主/summary.md"})
```

### 2. write - 写入分析报告

**用途**: 保存分析结果。

**示例**:
```json
write({
  "path": "./knowledge/analysis/诡秘之主_分析报告.md",
  "content": "# 《诡秘之主》分析报告\n\n..."
})
```

---

## 分析工具

### 3. extract_techniques - 提取写作技巧

**用途**: 从内容中提取可复用的技巧。

**实现**: 分析内容后，按类别整理技巧。

**输出格式**:
```json
{
  "techniques": [
    {
      "name": "开篇悬念钩子",
      "category": "structure",
      "description": "第一章开头设置悬念，引发读者好奇",
      "example": "原文片段",
      "applicable_scenarios": ["开篇", "新卷开始"]
    }
  ]
}
```

### 4. analyze_structure - 结构分析

**用途**: 分析作品的整体结构。

**分析维度**:
- 开篇设计（黄金三章）
- 发展节奏（冲突推进）
- 高潮设计（爽点爆发）
- 结尾收束（余韵留白）

### 5. analyze_pacing - 节奏分析

**用途**: 分析作品的节奏控制。

**分析内容**:
- 章节字数分布
- 爽点密度
- 高潮低谷交替
- 读者情绪曲线

### 6. analyze_satisfaction_points - 爽点分析

**用途**: 分析作品的爽点设计。

**爽点类型**:
- 装逼打脸
- 逆袭成长
- 智斗布局
- 热血战斗
- 金手指展示
- 收获升级

---

## 平台适配工具

### 7. parse_zhihu_content - 解析知乎内容

**用途**: 解析知乎回答/文章/专栏内容。

**特点**:
- 短篇小说为主
- 反转技巧常见
- 情感共鸣重要

### 8. parse_wechat_article - 解析公众号文章

**用途**: 解析微信公众号文章内容。

**特点**:
- 长文结构
- 段子化叙事
- 互动设计

### 9. parse_douyin_script - 解析抖音脚本

**用途**: 解析抖音视频脚本/文案。

**特点**:
- 15秒钩子
- 爽点密集
- 视觉化描写
- 结尾悬念

---

## 学习范文技巧流程

**完整流程**:
```
用户分享链接/内容
    ↓
1. 识别平台类型
   - zhihu.com → 知乎
   - mp.weixin.qq.com → 微信公众号
   - douyin.com → 抖音
    ↓
2. 调用对应解析工具
   - parse_zhihu_content
   - parse_wechat_article
   - parse_douyin_script
    ↓
3. 分析内容
   - 结构分析
   - 爽点分析
   - 技巧提取
    ↓
4. 整理技巧列表
    ↓
5. 返回给 Learner 入库
```

---

## URL 识别规则

| URL 模式 | 平台 | 内容类型 |
|---------|------|----------|
| zhihu.com/question/*/answer | 知乎回答 | answer |
| zhuanlan.zhihu.com/p/* | 知乎专栏 | article |
| mp.weixin.qq.com/s/* | 微信公众号 | article |
| douyin.com/video/* | 抖音视频 | video_script |

---

## 输出建议

### 返回给 Supervisor 的格式

```json
{
  "status": "success",
  "response": "已完成《诡秘之主》分析，提取了15个可复用技巧",
  "analysis_report": "./knowledge/analysis/诡秘之主_分析报告.md",
  "techniques_extracted": 15,
  "techniques": [
    {
      "name": "开篇悬念钩子",
      "category": "structure"
    }
  ]
}
```

### 交给 Learner 的格式

```json
{
  "action": "learn_and_store",
  "tips": [
    {
      "name": "开篇悬念钩子",
      "category": "structure",
      "platform": "起点",
      "content_type": "novel",
      "content": "技巧详细内容...",
      "examples": ["原文示例..."]
    }
  ],
  "source_info": {
    "platform": "起点",
    "title": "诡秘之主",
    "author": "爱潜水的乌贼",
    "url": "https://..."
  }
}
```