# AI网文写作智能体 - 使用指南

## 目录

1. [快速开始](#快速开始)
2. [创作流程](#创作流程)
3. [Agent详解](#agent详解)
4. [常见用例](#常见用例)
5. [高级配置](#高级配置)

## 快速开始

### 系统要求

- Python 3.8+
- OpenClaw CLI

### 安装

```bash
# 克隆项目
git clone <repo-url>
cd ai-novel-agent

# 安装OpenClaw
pip install openclaw

# 配置环境变量(可选)
export FEISHU_APP_ID=your_app_id
export FEISHU_APP_SECRET=your_app_secret
```

### 启动

```bash
# CLI模式
openclaw start

# 指定配置文件
openclaw start -c openclaw.json
```

## 创作流程

### 1. 创建新小说

```
用户: 帮我写一本修仙小说

Supervisor: 收到您的创作需求！让我为您安排创作流程...
[调用Planner创建世界观和大纲]

Planner: 为您创建了以下框架：
- 世界观：[修仙世界设定]
- 主角：[角色设定]
- 大纲：[剧情规划]

请问需要开始撰写正文吗？
```

### 2. 撰写章节

```
用户: 写第一章

Supervisor: 正在调用作者撰写第一章...

Writer: [第一章正文内容]

是否需要编辑审核？
```

### 3. 审核修改

```
用户: 帮我审核一下

Editor: 审核报告：
- 等级: B
- 问题: [问题列表]
- 润色版本: [修改后的内容]
```

## Agent详解

### Supervisor - 总协调器

**触发场景**: 所有用户输入首先由Supervisor处理

**核心能力**:
- 任务识别与分类
- Agent路由分发
- 结果汇总

**示例交互**:
```
用户: 分析《诡秘之主》为什么火
Supervisor: 这是一个作品分析需求，我将请分析师来深入研究...
```

### Planner - 策划/大纲师

**触发场景**: 创建新小说、补充设定、修改大纲

**输出格式**:
- 世界观文档
- 角色卡片
- 剧情大纲

**示例输出**:
```markdown
# 世界观设定

## 修仙世界
这是一个灵气充沛的修仙世界...

## 力量体系
练气 → 筑基 → 金丹 → 元婴 → 化神
```

### Writer - 写作/作者

**触发场景**: 撰写章节、场景描写

**输出格式**:
- 章节正文(2000-3000字)
- 场景片段

**写作原则**:
- 黄金三章法则
- 爽点密度控制
- 节奏张弛有度

### Editor - 编辑/审核

**触发场景**: 审核内容、润色文字

**输出格式**:
```markdown
# 审核报告

## 总体评价
- 等级: A/B/C/D

## 问题列表
1. [问题描述]

## 润色版本
[修改后的内容]
```

### Analyst - 网文分析

**触发场景**: 分析作品、研究套路

**分析维度**:
- 结构分析
- 设定分析
- 爽点研究
- 风格研究

### Operator - 运营/分析

**触发场景**: 市场咨询、更新策略

**分析内容**:
- 市场趋势
- 读者偏好
- 更新策略
- 推广建议

### Learner - 写作技巧学习

**触发场景**: 学习技巧、问题解答

**输出格式**:
- 技巧文档
- 写作指南
- 练习建议

## 常见用例

### 用例1: 从零创作一部小说

```
1. "帮我写一本都市异能小说"
2. [等待Planner输出框架]
3. "开始写第一章"
4. [等待Writer输出]
5. "审核一下"
6. [等待Editor输出]
7. "继续写第二章"
...
```

### 用例2: 分析学习

```
1. "分析《诡秘之主》的爽点设计"
2. [等待Analyst输出]
3. "总结一下可以学习的技巧"
4. [等待Learner输出]
5. "应用到我的小说大纲中"
```

### 用例3: 运营咨询

```
1. "现在什么题材热门"
2. [等待Operator输出]
3. "给我一些更新策略建议"
```

## 高级配置

### 自定义模型配置

```json
{
  "model": {
    "planner": {
      "model": "claude-sonnet-4-6",
      "temperature": 0.8
    },
    "writer": {
      "model": "claude-sonnet-4-6",
      "temperature": 0.9,
      "max_tokens": 16384
    }
  }
}
```

### 添加自定义Agent

1. 创建工作空间:
```bash
mkdir -p workspace-ai-novel-agent/my-agent
```

2. 编写定义文件:
- SOUL.md - 人格定义
- AGENTS.md - 工作流程
- TOOLS.md - 工具手册
- MEMORY.md - 记忆存储

3. 注册到配置:
```json
{
  "agents": {
    "my-agent": {
      "name": "我的Agent",
      "workspace": "workspace-ai-novel-agent/my-agent",
      "enabled": true
    }
  }
}
```

## 故障排除

### 常见问题

**Q: Agent调用失败**
- 检查网络连接
- 检查API密钥配置
- 查看日志文件 `logs/openclaw.log`

**Q: 输出格式不对**
- 检查Agent的SOUL.md定义
- 确认使用正确的模型

**Q: 记忆丢失**
- 检查MEMORY.md文件
- 确认文件权限