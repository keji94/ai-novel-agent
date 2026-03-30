# IMA云端同步工具

> **职责说明**: 主Agent统一负责云端同步，子Agent只写本地文件并返回 `sync_hint`。
>
> **Skill引用**: 详细API说明见 `skills/ima-skill/SKILL.md`
>
> **前置配置**: 在 https://ima.qq.com/agent-interface 获取凭证

## 9. IMA凭证配置

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

## 10. ima_api - API调用辅助函数

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

## 11. ima_sync_file - 同步本地文件到云端

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

## 12. ima_search - 搜索云端内容

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

## 13. ima_read - 读取云端笔记

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
