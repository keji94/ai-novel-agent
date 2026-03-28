# 错误处理文档

本文档定义 AI网文写作智能体 系统中可能出现的错误及处理策略。

## 一、Agent 调用错误

### 1.1 子智能体启动失败

**错误原因**:
- Agent ID 不在 allowAgents 列表中
- 配置文件错误
- 模型不可用

**错误表现**:
```json
{
  "status": "error",
  "error": "Agent 'xxx' not found in allowAgents"
}
```

**处理策略**:
1. 检查 `openclaw.json` 中的 `allowAgents` 配置
2. 确认 Agent ID 拼写正确
3. 查看 OpenClaw 日志获取详细错误
4. 向用户说明情况，提供替代方案

**降级方案**:
```python
# 如果 Writer 不可用，可以：
# 1. 由 Supervisor 自己完成简单写作
# 2. 建议用户稍后重试
# 3. 切换到其他可用的 Agent

try:
    result = sessions_spawn({"agentId": "writer", ...})
except AgentNotFoundError:
    # 降级方案1：自己写
    return "抱歉，写作助手暂时不可用。我可以先为你生成一个简短的草稿..."
    
    # 或降级方案2：建议重试
    return "写作助手暂时不可用，请稍后重试。"
```

### 1.2 子智能体超时

**错误原因**:
- 任务复杂，处理时间过长
- 模型响应慢
- 网络问题

**错误表现**:
```json
{
  "status": "error",
  "error": "timeout",
  "runtime": "5m0s"
}
```

**处理策略**:
1. 增加超时时间（如果合理）
2. 将大任务拆分为小任务
3. 使用更快的模型

**解决方案**:
```python
# 方案1：增加超时
sessions_spawn({
  "agentId": "writer",
  "task": "...",
  "runTimeoutSeconds": 600  # 10分钟
})

# 方案2：拆分任务
# 原任务：写一整章（3000字）
# 拆分为：先写开头（1000字）→ 再写中间（1000字）→ 最后写结尾（1000字）

# 方案3：使用更快的模型
sessions_spawn({
  "agentId": "writer",
  "model": {"model": "claude-3-5-haiku"}  # 更快的模型
})
```

### 1.3 子智能体返回错误

**错误原因**:
- 任务理解错误
- 内部处理失败
- 依赖资源不可用

**错误表现**:
```json
{
  "status": "error",
  "error": "Internal error",
  "notes": "详细错误信息"
}
```

**处理策略**:
1. 查看错误详情
2. 简化任务重试
3. 向用户说明情况

---

## 二、文件操作错误

### 2.1 文件不存在

**错误原因**:
- 项目未创建
- 路径错误
- 文件被删除

**错误表现**:
```json
{
  "status": "error",
  "error": "File not found: ./novels/xxx/settings/world.md"
}
```

**处理策略**:
1. 检查项目是否存在
2. 引导用户创建所需文件
3. 使用默认值（如果合理）

**解决方案**:
```python
# 检查项目是否存在
if not file_exists("./novels/xxx/project.json"):
    return "项目《xxx》不存在，是否需要创建新项目？"

# 检查设定文件
if not file_exists("./novels/xxx/settings/world.md"):
    return "世界观设定文件不存在，是否需要先创建设定？"

# 使用默认值
settings = read("./novels/xxx/settings/world.md") or DEFAULT_WORLD_SETTINGS
```

### 2.2 文件写入失败

**错误原因**:
- 权限不足
- 磁盘空间不足
- 路径不存在

**错误表现**:
```json
{
  "status": "error",
  "error": "Permission denied"
}
```

**处理策略**:
1. 检查目录权限
2. 检查磁盘空间
3. 创建必要的目录

**解决方案**:
```python
# 检查并创建目录
import os
os.makedirs("./novels/xxx/settings", exist_ok=True)

# 检查权限
import stat
if not os.access("./novels/xxx/settings", os.W_OK):
    return "没有写入权限，请检查目录权限"
```

### 2.3 JSON 解析错误

**错误原因**:
- 文件格式错误
- 编码问题

**错误表现**:
```json
{
  "status": "error",
  "error": "JSON decode error"
}
```

**处理策略**:
1. 尝试修复 JSON
2. 使用备份文件
3. 提示用户手动检查

---

## 三、上下文不足错误

### 3.1 缺少必要设定

**错误原因**:
- 用户直接要求写作，但没有大纲
- 项目刚创建，设定不完整

**错误表现**:
用户说"写第一章"，但没有大纲和角色设定。

**处理策略**:
1. 检查是否有足够的设定
2. 引导用户先创建设定
3. 使用默认设定（如果合理）

**解决方案**:
```python
def check_context_before_writing(project_name):
    # 检查必要文件
    required = [
        "./novels/{}/outline/main.md".format(project_name),
        "./novels/{}/characters/main.md".format(project_name)
    ]
    
    missing = [f for f in required if not file_exists(f)]
    
    if missing:
        return """
在开始写作之前，需要先完成以下设定：
{}
是否需要我帮你创建？
        """.format("\n".join(missing))
    
    return None  # 上下文充足
```

### 3.2 角色状态丢失

**错误原因**:
- 忘记更新角色状态
- 角色状态文件损坏

**错误表现**:
写作第100章，但角色状态还停留在第50章。

**处理策略**:
1. 提示用户更新状态
2. 从最近的章节推断状态
3. 重新生成状态摘要

**解决方案**:
```python
def recover_character_state(project_name, character_name):
    # 从最近的章节摘要推断
    summaries = read("./novels/{}/context/summaries/chapter_summaries.md".format(project_name))
    
    # 搜索该角色的最近出现
    last_mention = find_last_mention(summaries, character_name)
    
    if last_mention:
        return """
角色【{}】的状态可能已过期。
最近在第{}章出现：{}

是否需要更新角色状态？
        """.format(character_name, last_mention.chapter, last_mention.summary)
```

### 3.3 伏笔追踪失败

**错误原因**:
- 新增伏笔忘记注册
- 伏笔文件损坏

**处理策略**:
1. 从章节摘要扫描伏笔
2. 重新生成伏笔列表
3. 提示用户确认

---

## 四、IMA 同步错误

### 4.1 凭证无效

**错误原因**:
- API Key 过期
- Client ID 错误
- 未配置凭证

**错误表现**:
```json
{
  "status": "error",
  "error": "Unauthorized"
}
```

**处理策略**:
1. 提示用户检查凭证
2. 提供配置方法
3. 继续使用本地存储

**解决方案**:
```python
if ima_error == "Unauthorized":
    return """
IMA 同步失败：凭证无效或已过期

请检查配置：
1. 环境变量：IMA_OPENAPI_CLIENTID, IMA_OPENAPI_APIKEY
2. 配置文件：~/.config/ima/client_id, ~/.config/ima/api_key

获取凭证：https://ima.qq.com/agent-interface

注意：即使同步失败，内容仍会保存在本地。
    """
```

### 4.2 网络错误

**错误原因**:
- 网络不可用
- IMA 服务不可达

**处理策略**:
1. 重试（最多3次）
2. 记录待同步任务
3. 继续使用本地存储

---

## 五、用户输入错误

### 5.1 模糊需求

**错误原因**:
- 用户输入不明确
- 缺少必要信息

**错误表现**:
用户说"帮我写个小说"，没有提供类型、风格等信息。

**处理策略**:
1. 启动灵感探索流程
2. 引导式提问
3. 逐步收集信息

### 5.2 冲突需求

**错误原因**:
- 用户要求前后矛盾
- 设定冲突

**处理策略**:
1. 指出冲突点
2. 询问用户选择
3. 提供折中方案

---

## 六、错误报告格式

当发生错误时，向用户报告：

```markdown
⚠️ 遇到问题

**错误类型**: {类型}
**错误描述**: {描述}

**可能的原因**:
1. {原因1}
2. {原因2}

**建议的解决方案**:
1. {方案1}
2. {方案2}

如果问题持续存在，请提供以下信息以便诊断：
- 项目名称
- 你正在进行的操作
- 错误发生的时间
```

## 七、日志记录

所有错误应记录到日志：

```
日志路径：./openclaw/logs/openclaw.log

日志格式：
[时间] [级别] [Agent] 错误信息

示例：
[2026-03-26 10:00:00] [ERROR] [writer] 文件不存在：./novels/xxx/chapters/chapter_001.md
[2026-03-26 10:01:00] [WARN] [supervisor] 上下文不足，缺少角色设定
```

---

## 八、预防措施

### 8.1 前置检查

在执行关键操作前：
- 检查文件是否存在
- 检查配置是否正确
- 检查上下文是否充足

### 8.2 定期备份

- 项目文件定期备份
- 重要操作前自动备份
- 提供恢复机制

### 8.3 用户引导

- 对新手提供引导
- 对危险操作给出警告
- 提供撤销机制（如果可能）