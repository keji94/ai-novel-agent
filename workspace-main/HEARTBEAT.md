# HEARTBEAT.md · 项目状态恢复机制

> 当用户重启对话或一段时间后回来，通过此机制恢复项目上下文。

## 心跳检查流程

### 触发条件
- 用户说"我回来了"
- 用户提到"我的小说"、"上次那个项目"
- 用户直接开始创作相关对话

### 检查步骤

```
1. 读取活跃项目
   ↓
   exec("ls ./novels/*/project.json")
   ↓
2. 检查项目状态
   ↓
   read("./novels/{项目名}/project.json")
   ↓
3. 识别阶段
   - brainstorming: 灵感探索中
   - basic_design: 基础设定中
   - detailed_design: 详细设定中
   - outlining: 大纲编写中
   - writing: 正在写作
   - paused: 已暂停
   - completed: 已完成
   ↓
4. 读取上下文
   - 读取最后活跃章节
   - 读取角色状态
   - 读取未回收伏笔
   ↓
5. 生成恢复提示
```

## 恢复消息模板

### 灵感探索阶段
```
欢迎回来！你有一个进行中的项目：

📚 《{书名}》
📍 阶段：灵感探索
🕐 上次活动：{时间}
💬 上次话题：{话题}

我们上次在讨论：
- 类型：{已确定的类型}
- 金手指：{已确定的金手指}
- 主角：{已确定的主角设定}

你还想继续完善哪些方面？或者我可以帮你：
1. 继续探索其他设定
2. 开始构建世界观
3. 修改已有的设定
```

### 写作阶段
```
欢迎回来！你正在创作：

📚 《{书名}》
📍 阶段：正在写作
📊 进度：第{N}章 / 共{M}章（预计）
📝 字数：{总字数}

上次写到：第{N}章 - {章节名}
主要内容：{章节摘要}

当前状态：
- 主角：{姓名}，{境界}
- 地点：{地点}
- 待处理伏笔：{数量}个

我可以帮你：
1. 继续写下一章
2. 回顾前面的内容
3. 检查设定一致性
4. 修改已写内容
```

### 暂停阶段
```
欢迎回来！你有一个暂停的项目：

📚 《{书名}》
📍 状态：已暂停
🕐 暂停时间：{时间}
📊 进度：第{N}章

暂停原因：{如果记录了}

我可以帮你：
1. 继续写作
2. 修改大纲
3. 调整设定
4. 重新规划
```

## 项目状态文件说明

### project.json 关键字段

```json
{
  "id": "proj_20260326_xxx",
  "name": "仙道长生",
  "lifecycle": {
    "stage": "writing",
    "stage_started_at": "2024-01-20T00:00:00Z"
  },
  "session": {
    "last_active_at": "2024-01-20T14:30:00Z",
    "last_topic": "撰写第1章"
  },
  "statistics": {
    "total_words": 2500,
    "chapters_completed": 1
  }
}
```

### 角色状态文件

`./novels/{项目名}/context/tracking/character_states.json`

```json
{
  "林风": {
    "current_state": {
      "cultivation": "筑基初期",
      "location": "青云宗内门"
    },
    "last_appearance": 157
  }
}
```

### 章节摘要文件

`./novels/{项目名}/context/summaries/chapter_summaries.md`

```markdown
## 第157章 摘要

**核心事件**: 林风突破筑基中期
**出场人物**: 林风、苏婉
**地点**: 秘境
**伏笔**: 埋设神秘老者身份
```

## 心跳消息检查规则

当收到心跳轮询时：

```python
def check_heartbeat():
    # 1. 检查是否有活跃项目
    projects = find_active_projects()
    
    if not projects:
        return "HEARTBEAT_OK"
    
    # 2. 检查是否有需要提醒的事项
    for project in projects:
        # 检查长期未更新
        if days_since(project.last_active_at) > 7:
            return f"你的项目《{project.name}》已经一周没更新了，需要继续吗？"
        
        # 检查伏笔是否太久没回收
        foreshadowing = read_foreshadowing(project)
        for f in foreshadowing:
            if f.status == "pending" and current_chapter - f.planted_chapter > 50:
                return f"《{project.name}》中有一个伏笔（{f.description}）已经埋设超过50章，记得回收哦！"
    
    # 3. 没有特别事项
    return "HEARTBEAT_OK"
```

## 注意事项

- 不要每次心跳都打扰用户
- 只在真正需要提醒时发送消息
- 检查要快速，避免阻塞
- 消息要简洁有用