# Agent协作流程定义

## 可调用的Agent列表

| Agent | 职责 | 调用场景 |
|-------|------|----------|
| Planner | 策划/大纲 | 新小说创作、世界观构建、大纲规划 |
| Writer | 写作/作者 | 章节撰写、场景描写、对话编写 |
| Editor | 编辑/审核 | 内容审核、33维度审计、一致性检查 |
| Reviser | 修订者 | 根据审计结果修复问题、去AI味 |
| ChapterAnalyzer | 章节分析器 | 导入已有章节、逆向工程真相文件 |
| StyleAnalyzer | 文风分析器 | 分析文风、提取风格指纹、生成风格指南 |
| Detector | AI痕迹检测器 | 检测AI生成痕迹、提供修订建议 |
| analyst | 网文分析 | 作品分析、结构拆解、爽点研究 |
| Operator | 运营/分析 | 市场分析、读者研究、运营策略 |
| Learner | 技巧学习 | 写作技巧、最佳实践、创作指导 |

## 任务路由规则

### 规则0: 灵感探索流程（最高优先级）

```
条件: 用户表达模糊创作意向，缺少明确要素
触发识别:
  - "我想写小说"
  - "有个想法想完善"
  - "最近想写小说，但不知道写什么"
  - 需求中缺少类型/金手指/主角等核心要素

动作:
  1. 检查是否有进行中的项目（brainstorming阶段）
     - 调用 check_project_recovery() 工具

  2. 有进行中项目 → 恢复上下文
     - 读取项目状态
     - 提醒用户上次进度
     - 建议接续话题

  3. 无进行中项目 → 创建新项目
     - 调用 create_draft_project(hint) 创建临时项目
     - 生成临时书名（如：未命名创作项目_20240315）
     - 告知用户可以随时改名

  4. 调用 Planner 的 brainstorm 模式
     sessions_send("planner", {
       "mode": "brainstorm",
       "project_id": "新创建或恢复的项目ID",
       "context": "用户的初始想法"
     })

输出给用户:
  > 好的！让我帮你一起探索灵感。
  >
  > [如有进行中项目]
  > 欢迎回来！你有一个进行中的项目：
  > 📚 《{书名}》
  > 📍 阶段：{当前阶段}
  > 🕐 上次活动：{时间}
  > 💬 上次话题：{话题}
  >
  > [新项目]
  > 先创建一个临时项目来记录我们的想法。
  > 临时书名：【{临时书名}】
  > 之后随时可以改名。
```

### 规则1: 新小说创作流程

```
条件: 用户要创作新小说
动作:
  1. 调用 Planner 创建世界观和大纲
  2. 可选: 调用 Editor 审核大纲
  3. 自动触发 Editor 审核大纲
     sessions_spawn({
       "agentId": "editor",
       "task": "审核大纲\n项目: {项目名}\n大纲目录: ./novels/{项目名}/outline/\n审核重点: 世界观逻辑、力量体系自洽性、角色动机、剧情节奏、伏笔可行性、金手指平衡\n审核模式: standard",
       "label": "审核大纲-{项目名}"
     })
  4. Editor 审核完成 → 将审核报告反馈给 Planner 修订
     sessions_spawn({
       "agentId": "planner",
       "task": "修订大纲\n项目: {项目名}\n审核报告: {Editor返回的审核结果}\n要求: 修复所有Critical问题，逐条回应Warning问题，保留已确认的亮点",
       "label": "修订大纲-{项目名}"
     })
  5. Planner 修订完成 → 可选：Editor 复审（如有Critical问题修复）
  6. 返回最终大纲给用户
```

### 规则2: 内容撰写流程

```
条件: 用户要撰写具体内容
动作:
  1. 检查是否有足够上下文(大纲/设定)
  2. 若无，先调用 Planner 补充设定
  3. 调用 Writer 进行撰写
  4. 自动触发 Editor 审核（不询问用户）
  5. 返回 Writer 结果 + Editor 审核报告给用户
```

### 规则3: 分析学习流程

```
条件: 用户要分析作品或学习技巧
动作:
  1. 分析需求 → 调用 analyst
  2. 学习技巧 → 调用 Learner
  3. 两者关联时顺序调用
  4. 返回结果给用户
```

### 规则3.1: 学习范文技巧流程（新增）

```
条件: 用户分享链接/内容要学习写作技巧
触发识别:
  - 检测到 URL（知乎/微信/抖音）
  - 用户说"学习这个"、"分析这个技巧"
  - 用户提供范文内容

动作:
  1. 识别平台类型
     - zhihu.com → 知乎
     - mp.weixin.qq.com → 微信公众号
     - douyin.com → 抖音

  2. 调用 analyst 解析内容
     task: {
       "action": "parse_and_extract",
       "platform": "识别的平台",
       "url_or_content": "用户提供的内容",
       "mode": "auto"  // 自动识别技巧类型
     }

     // 注意：analyst 返回提取的技巧后，再调用 learner 入库

  3. 等待 analyst 返回提取的技巧

  4. 调用 Learner 学习入库
     task: {
       "action": "learn_and_store",
       "tips": [analyst提取的技巧],
       "source_info": {
         "platform": "平台",
         "title": "原标题",
         "url": "原始链接"
       }
     }

  5. 返回学习结果给用户
     - 学到了哪些技巧
     - 技巧已入库，后续写作可自动应用
```

**平台识别规则**:

| URL模式 | 平台 | 内容类型 |
|---------|------|----------|
| zhihu.com/question/*/answer | 知乎回答 | answer |
| zhuanlan.zhihu.com/p/* | 知乎专栏 | article |
| mp.weixin.qq.com/s/* | 微信公众号 | article |
| douyin.com/video/* | 抖音视频 | video_script |

### 规则4: 章节导入流程（新增）

```
条件: 用户要导入已有小说章节续写
触发识别:
  - "导入这个小说"
  - "续写这个小说"
  - "把这个文件导入"
  - 检测到用户提供了小说文件路径

动作:
  1. 确认导入模式
     - 单文件: "导入 ./novel.txt"
     - 目录模式: "导入 ./chapters/"
     - 断点续导: "继续导入，从第50章"

  2. 调用 ChapterAnalyzer 执行导入
     sessions_spawn({
       "agentId": "chapter-analyzer",
       "task": "导入章节\n源路径: {path}\n模式: {mode}",
       "label": "导入章节"
     })

  3. ChapterAnalyzer 自动执行:
     - 拆分章节（如需要）
     - 逐章分析提取信息
     - 生成7个真相文件
     - 生成导入报告

  4. 返回导入结果给用户
     - 导入了多少章节
     - 识别了多少角色
     - 追踪了多少资源
     - 有多少伏笔待回收
```

### 规则5: 文风仿写流程（新增）

```
条件: 用户要分析/模仿某个作者的文风
触发识别:
  - "分析这个作者的文风"
  - "模仿XXX的风格"
  - "学习这种写法"

动作:
  1. 确认分析目标
     - 参考文本路径
     - 作者名称（可选）

  2. 调用 StyleAnalyzer 分析文风
     sessions_spawn({
       "agentId": "style-analyzer",
       "task": "分析文风\n源文件: {path}\n作者: {author}",
       "label": "分析文风"
     })

  3. StyleAnalyzer 自动执行:
     - 统计分析（句长、词汇、段落等）
     - 生成 style_profile.json（统计指纹）
     - 生成 style_guide.md（风格指南）

  4. 询问用户是否应用到某本书
     "风格分析完成，是否应用到《{书名}》？"

  5. 如果用户确认，复制风格文件到书籍目录
```

### 规则6: AI痕迹检测流程（新增）

```
条件: 用户要检测章节的AI生成痕迹
触发识别:
  - "检测这章的AI痕迹"
  - "这章像AI写的吗"
  - "分析AI痕迹"

动作:
  1. 调用 Detector 执行检测
     sessions_spawn({
       "agentId": "detector",
       "task": "检测AI痕迹\n章节: 第{N}章\n项目: {项目名}",
       "label": "AI痕迹检测"
     })

  2. Detector 自动执行:
     - 11条确定性规则检测
     - 统计特征分析
     - 可选：语义分析
     - 生成检测报告

  3. 返回检测结果
     - AI痕迹得分 (0-100)
     - 问题定位
     - 修改建议
```

### 规则7: 导出流程（新增）

```
条件: 用户要导出小说
触发识别:
  - "导出小说"
  - "导出为EPUB"
  - "导出TXT"

动作:
  1. 确认导出参数
     - 格式: txt/md/epub
     - 是否只导出已审核章节
     - 章节范围

  2. 调用导出脚本
     exec({
       "command": "./scripts/export.sh {format} {project} {options}"
     })

  3. 返回导出结果
     - 输出文件路径
     - 章节数量
     - 文件大小
```

### 规则8: 运营咨询流程

```
条件: 用户咨询运营相关问题
动作:
  1. 调用 Operator 分析
  2. 返回结果给用户
```

### 规则9: 章节修改流程

```
条件: 用户要修改已有章节内容
触发识别:
  - "修改第N章"
  - "重写第N章的XXX部分"
  - "把第N章的XXX改掉"
  - "第N章的XXX有问题，帮我修一下"

动作:
  1. 确认修改范围
     - 整章重写: 章节内容需要大幅修改
     - 部分修改: 指定段落/场景需要调整
     - 审计问题修复: 已有审计报告，需要修复

  2. 路由选择
     ├── 整章重写 → Writer (两阶段写作)
     │     sessions_spawn({
     │       "agentId": "writer",
     │       "task": "Phase 1: 重写第{N}章\n原因: {用户要求}\n大纲: {章节大纲}",
     │       "label": "重写-第{N}章"
     │     })
     │
     ├── 部分修改 → Writer (定向修改)
     │     sessions_spawn({
     │       "agentId": "writer",
     │       "task": "定向修改第{N}章\n修改范围: {段落/场景}\n要求: {具体修改要求}",
     │       "label": "修改-第{N}章"
     │     })
     │
     └── 审计问题修复 → Reviser (根据审计报告)
           sessions_spawn({
             "agentId": "reviser",
             "task": "修复第{N}章\n审计报告: {报告内容}\n模式: {spot-fix/rewrite等}",
             "label": "修复-第{N}章"
           })

  3. 写作/修订完成后 → 自动触发 Editor 审核（不询问用户）
     sessions_spawn({
       "agentId": "editor",
       "task": "审核修改后章节\n章节: 第{N}章\n模式: standard",
       "label": "审核修改-第{N}章"
     })

  4. Editor 审核后自动处理（不询问用户）
     ├── 通过 → 更新章节文件 + 重新结算真相文件
     └── 不通过 → 自动调用 Reviser 修订 → 重复步骤 3

  5. 真相文件重新结算（必须）
     sessions_spawn({
       "agentId": "writer",
       "task": "Phase 2: 状态结算\n章节正文: {修改后内容}\n注意: 这是修改重算，需对比原版差异，只更新变化的部分",
       "label": "状态重算-第{N}章",
       "model": { "temperature": 0.3, "max_tokens": 4096 }
     })

  6. 返回修改结果
     - 修改内容摘要
     - 审核结果
     - 状态更新摘要
```

## 多Agent协作模式

### 调用方式选择指南

本项目支持两种Agent调用方式，根据场景选择：

| 方式 | 工具 | 适用场景 | 特点 |
|------|------|----------|------|
| **Subagent模式** | `sessions_spawn` | 后台任务、并行处理、长时间运行 | 独立会话、异步通告、无会话工具 |
| **直接通信模式** | `sessions_send` | 串行协作、实时交互、需要上下文 | 共享会话、同步返回、完整工具 |

**推荐使用 `sessions_spawn` (Subagent模式)**：
- ✅ 更符合OpenClaw最佳实践
- ✅ 支持并行执行，提高效率
- ✅ 避免会话混乱
- ✅ 自动归档管理

**使用 `sessions_send` 的场景**：
- 需要实时交互对话
- 需要传递完整会话上下文
- 子Agent需要调用其他Agent

### 串行协作（Subagent模式）

当任务有明确依赖关系时：

```
用户 → ai-novel-agent
       ↓ sessions_spawn("planner")
       ↓ 等待通告
       ↓ sessions_spawn("writer", 传入planner结果)
       ↓ 等待通告
       ↓ sessions_spawn("editor", 传入writer结果)
       ↓ 等待通告
       → 返回用户
```

调用示例：
```python
# 1. 启动Planner子智能体
planner_result = sessions_spawn({
  "agentId": "planner",
  "task": "创建修仙小说大纲",
  "label": "创建大纲",
  "model": {
    "temperature": 0.8,
    "max_tokens": 16384
  }
})

# 2. 等待planner完成（通过通告返回结果）
# planner会自动发送通告，包含结果摘要

# 3. 启动Writer子智能体
writer_result = sessions_spawn({
  "agentId": "writer",
  "task": "根据大纲撰写第一章",
  "label": "撰写第1章",
  "model": {
    "temperature": 0.9,
    "max_tokens": 16384
  }
})
```

### 并行协作（Subagent模式）

当任务可以独立进行时：

```
用户 → ai-novel-agent
       ├─ sessions_spawn("analyst", 分析作品A) ─┐
       ├─ sessions_spawn("learner", 学习技巧B) ─┤
       └─ sessions_spawn("operator", 市场分析C) ─┘
                                                ↓
                                         汇总所有通告结果
                                                ↓
                                           → 返回用户
```

调用示例：
```python
# 同时启动多个子智能体
tasks = [
  sessions_spawn({
    "agentId": "analyst",
    "task": "分析《诡秘之主》",
    "label": "分析诡秘"
  }),
  sessions_spawn({
    "agentId": "learner",
    "task": "学习知乎写作技巧",
    "label": "学习技巧"
  }),
  sessions_spawn({
    "agentId": "operator",
    "task": "分析修仙小说市场趋势",
    "label": "市场分析"
  })
]

# 所有子智能体并行执行
# 通过runId可以查询状态
# 完成后会自动发送通告
```

### 直接通信模式（sessions_send）

适用于需要实时交互的场景：

```python
# 与Writer进行多轮对话
writer_session = sessions_send("writer", {
  "task": "撰写第一章",
  "outline":大纲内容
})

# 继续在Writer的会话中交流
writer_session = sessions_send("writer", {
  "feedback": "开头部分需要修改，要更吸引人"
})
```

## 上下文传递规范

### 传递给 Planner

```json
{
  "task": "创建小说大纲",
  "genre": "仙侠/都市/玄幻...",
  "requirements": "用户的具体要求",
  "constraints": "限制条件"
}
```

### 传递给 Writer

```json
{
  "task": "撰写章节",
  "outline": "相关大纲内容",
  "characters": "涉及角色",
  "previous_context": "前文摘要",
  "requirements": "具体要求"
}
```

### 传递给 Editor

```json
{
  "task": "审核内容",
  "content": "待审核内容",
  "settings": "世界观设定",
  "focus": "审核重点"
}
```

### 传递给 analyst

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

### 传递给 Learner

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

## 异常处理

### 上下文不足

```
1. 告知用户缺少什么信息
2. 引导用户提供或允许调用其他Agent补充
3. 无法补充时使用合理默认值并告知用户
```

### Agent调用失败

```
1. 记录错误信息
2. 尝试替代方案或简化任务
3. 向用户说明情况并提供部分结果
```

### 任务超出能力范围

```
1. 诚实说明限制
2. 提供可能的替代方案
3. 建议用户调整需求
```