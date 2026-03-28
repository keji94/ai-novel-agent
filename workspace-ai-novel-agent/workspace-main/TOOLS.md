# Supervisor 工具手册

本文档定义 Supervisor (ai-novel-agent) 可使用的工具。

## 核心工具

### 1. sessions_spawn - 启动子智能体

**用途**: 启动专业的子 Agent 处理特定任务。

**语法**:
```json
{
  "tool": "sessions_spawn",
  "params": {
    "agentId": "planner|writer|editor|reviser|chapter-analyzer|style-analyzer|detector|analyst|operator|learner",
    "task": "任务描述",
    "label": "任务标签（可选）",
    "model": {
      "temperature": 0.7,
      "max_tokens": 8192
    }
  }
}
```

**示例**:
```json
// 启动 Planner 创建大纲
sessions_spawn({
  "agentId": "planner",
  "task": "创建修仙小说世界观和大纲",
  "label": "创建大纲"
})

// 启动 Writer 撰写章节
sessions_spawn({
  "agentId": "writer",
  "task": "根据大纲撰写第一章",
  "label": "撰写第1章"
})
```

### 2. sessions_send - 直接通信

**用途**: 与已存在的 Agent 会话进行多轮对话。

**语法**:
```json
{
  "tool": "sessions_send",
  "params": {
    "agentId": "writer",
    "message": "消息内容"
  }
}
```

**适用场景**:
- 需要多轮交互
- 需要传递完整会话上下文
- 子 Agent 需要调用其他 Agent

### 3. subagents - 子智能体管理

**用途**: 查看、管理当前会话的子智能体。

**操作**:
- `list`: 列出所有子智能体
- `kill <runId>`: 终止指定子智能体
- `steer <runId> "message"`: 向子智能体发送指令

## 文件操作工具

### 4. read - 读取文件

**用途**: 读取项目文件、配置、设定等。

**语法**:
```json
{
  "tool": "read",
  "params": {
    "path": "文件路径"
  }
}
```

**示例**:
```json
// 读取项目配置
read({"path": "./novels/xianxia/project.json"})

// 读取世界观设定
read({"path": "./novels/xianxia/settings/world.md"})
```

### 5. write - 写入文件

**用途**: 创建或更新项目文件。

**语法**:
```json
{
  "tool": "write",
  "params": {
    "path": "文件路径",
    "content": "文件内容"
  }
}
```

**注意事项**:
- 会覆盖已有文件
- 自动创建父目录

### 6. edit - 编辑文件

**用途**: 精确修改文件内容。

**语法**:
```json
{
  "tool": "edit",
  "params": {
    "path": "文件路径",
    "oldText": "要替换的文本",
    "newText": "替换后的文本"
  }
}
```

## 项目管理工具

### 7. check_project_recovery - 检查项目恢复

**用途**: 检查是否有进行中的项目，用于灵感探索流程。

**实现**: 使用 read + project.json

**伪代码**:
```python
def check_project_recovery():
    # 1. 读取所有项目
    projects = read("./novels/*/project.json")
    
    # 2. 查找 brainstorming 阶段的项目
    active_projects = [p for p in projects if p.lifecycle.stage == "brainstorming"]
    
    # 3. 返回最近活跃的项目
    if active_projects:
        return sorted(active_projects, key=lambda p: p.session.last_active_at)[-1]
    return None
```

**实际调用**:
```json
// Step 1: 列出所有项目
exec({"command": "ls ./novels/*/project.json"})

// Step 2: 读取每个项目状态
read({"path": "./novels/xianxia/project.json"})

// Step 3: 检查 lifecycle.stage 是否为 brainstorming
```

### 8. create_draft_project - 创建临时项目

**用途**: 为灵感探索创建临时项目。

**实现**: 使用 write 创建项目结构

**伪代码**:
```python
def create_draft_project(hint):
    # 1. 生成临时书名
    temp_name = f"未命名创作项目_{datetime.now().strftime('%Y%m%d')}"
    
    # 2. 创建项目目录
    mkdir(f"./novels/{temp_name}")
    
    # 3. 创建 project.json
    project = {
        "id": f"proj_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
        "name": temp_name,
        "is_temp_name": True,
        "lifecycle": {"stage": "brainstorming"},
        "brainstorm": {"decisions": {}},
        "created_at": datetime.now().isoformat()
    }
    write(f"./novels/{temp_name}/project.json", json.dumps(project))
    
    return project
```

**实际调用**:
```json
// Step 1: 生成临时书名
temp_name = "未命名创作项目_20260326"

// Step 2: 创建目录
exec({"command": "mkdir -p ./novels/未命名创作项目_20260326"})

// Step 3: 创建 project.json
write({
  "path": "./novels/未命名创作项目_20260326/project.json",
  "content": "{\n  \"id\": \"proj_20260326_090000\",\n  \"name\": \"未命名创作项目_20260326\",\n  \"is_temp_name\": true,\n  \"lifecycle\": {\"stage\": \"brainstorming\"},\n  ...\n}"
})
```

## 存储路径说明

### 项目存储结构
```
./novels/{项目名}/
├── project.json          # 项目元数据
├── settings/             # 世界观设定
├── characters/           # 角色设定
├── outline/              # 大纲
├── chapters/             # 章节
├── context/              # 上下文追踪
└── brainstorm/           # 灵感探索
```

### 知识库路径
```
./knowledge/
├── techniques/           # 写作技巧
└── analysis/             # 作品分析
```

## 使用建议

### 优先使用 sessions_spawn
- 后台任务
- 并行处理
- 长时间运行

### 使用 sessions_send 的场景
- 多轮对话
- 实时交互
- 需要完整上下文

### 错误处理
1. 子智能体失败 → 查看日志，重试或简化任务
2. 文件不存在 → 引导用户创建或使用默认值
3. 权限问题 → 检查文件权限，提示用户

---

## IMA云端同步工具

> **职责说明**: 主Agent统一负责云端同步，子Agent只写本地文件并返回 `sync_hint`。
>
> **Skill引用**: 详细API说明见 `skills/ima-skill/SKILL.md`
>
> **前置配置**: 在 https://ima.qq.com/agent-interface 获取凭证

### 9. IMA凭证配置

**方式A - 环境变量（推荐）**:
```bash
export IMA_OPENAPI_CLIENTID="your_client_id"
export IMA_OPENAPI_APIKEY="your_api_key"
```

**方式B - 配置文件**:
```bash
mkdir -p ~/.config/ima
echo "your_client_id" > ~/.config/ima/client_id
echo "your_api_key" > ~/.config/ima/api_key
```

### 10. ima_api - API调用辅助函数

**用途**: 封装IMA API调用，统一处理认证。

**实现**:
```bash
# 加载凭证
IMA_CLIENT_ID="${IMA_OPENAPI_CLIENTID:-$(cat ~/.config/ima/client_id 2>/dev/null)}"
IMA_API_KEY="${IMA_OPENAPI_APIKEY:-$(cat ~/.config/ima/api_key 2>/dev/null)}"

# API调用函数
ima_api() {
  local path="$1" body="$2"
  curl -s -X POST "https://ima.qq.com/$path" \
    -H "ima-openapi-clientid: $IMA_CLIENT_ID" \
    -H "ima-openapi-apikey: $IMA_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body"
}
```

### 11. ima_sync_file - 同步本地文件到云端

**用途**: 子Agent完成任务后，主Agent执行云端同步。

**参数** (sync_hint):
```json
{
  "type": "settings|characters|outline|chapters|technique",
  "project": "项目名称",
  "file": "本地文件路径"
}
```

**实现流程**:
```bash
# 1. 读取本地文件
content=$(cat "$file_path")

# 2. 确定目标笔记本名称
notebook_name="小说：《$project_name》"

# 3. 搜索笔记本
ima_api "openapi/note/v1/search_note_book" '{
  "search_type": 0,
  "query_info": {"title": "'"$notebook_name"'"},
  "start": 0,
  "end": 20
}'

# 4. 创建笔记
ima_api "openapi/note/v1/import_doc" '{
  "content_format": 1,
  "content": "'"$content"'"
}'
```

**调用时机**:
```json
// 1. 调用子Agent
result = sessions_spawn({"agentId": "planner", "task": "创建世界观设定"})

// 2. 检查返回的sync_hint
if (result.sync_hint) {
  // 3. 执行云端同步
  exec({"command": "scripts/ima-sync.sh sync " + result.sync_hint.file})
}

// 4. 返回结果给用户
return result.response
```

### 12. ima_search - 搜索云端内容

**用途**: 从IMA知识库搜索内容（回退读取场景）。

**实现**:
```bash
# 搜索笔记
ima_api "openapi/note/v1/search_note_book" '{
  "search_type": 1,
  "query_info": {"content": "'"$query"'"},
  "start": 0,
  "end": 20
}'
```

### 13. ima_read - 读取云端笔记

**用途**: 本地文件不存在时，从云端回退读取。

**实现**:
```bash
ima_api "openapi/note/v1/get_doc_content" '{
  "doc_id": "'"$doc_id"'",
  "target_content_format": 0
}'
```

---

## 同步协调流程

### 子Agent返回格式

子Agent完成任务后，返回包含 `sync_hint` 的结果：

```json
{
  "status": "success",
  "response": "世界观设定已完成",
  "files_created": ["./novels/仙道长生/settings/world.md"],
  "sync_hint": {
    "type": "settings",
    "project": "仙道长生",
    "file": "./novels/仙道长生/settings/world.md"
  }
}
```

### 主Agent处理流程

```
用户请求
    │
    ▼
┌─────────────────────────────────────┐
│  1. sessions_spawn 调用子Agent       │
│  2. 接收结果 + sync_hint             │
│  3. ima_sync_file 执行云端同步       │
│  4. 返回结果给用户                   │
└─────────────────────────────────────┘
```

### 双写双读机制

**写入（双写）**:
```
子Agent → 本地文件 → 主Agent → IMA云端
```

**读取（回退）**:
```
尝试本地 → 不存在 → 从IMA读取 → 回写本地
```

### 笔记本组织结构

**小说项目**（每本小说一个笔记本）:
```
📚 小说：《仙道长生》
  📁 世界观设定
  📁 角色设定
  📁 大纲
  📁 章节正文
```

**技巧库**:
```
📚 写作技巧库
  📁 知乎短篇技巧
  📁 公众号文章技巧
  📁 抖音脚本技巧
  📁 通用写作技巧
```

### 注意事项

- **UTF-8编码**: 写入前确保内容为UTF-8
- **敏感操作**: 追加内容需确认目标笔记
- **网络错误**: 同步失败不影响本地存储，可稍后重试
- **更多API**: 详见 `skills/ima-skill/notes/SKILL.md`