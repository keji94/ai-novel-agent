# TOOLS.md 编写指南

## 重要说明

### TOOLS.md 的定位

TOOLS.md 是 Agent 的工具手册，包含：
1. **可调用工具**: OpenClaw 提供的基础工具（read/write/exec/sessions_spawn 等）
2. **实现指南**: 用伪代码说明如何组合基础工具完成复杂任务

### 伪代码的使用

**TOOLS.md 中的伪代码不是可调用的函数**，而是实现指南，帮助 Agent 理解任务流程。

**正确理解方式**:
```markdown
### split_chapters - 拆分章节

**用途**: 从单文件中拆分出各章节

**实现指南**（使用基础工具组合）:
```python
# 这是伪代码，展示实现思路，不是可调用的函数

# Step 1: 读取源文件（使用 read 工具）
content = read({"path": "./source/novel.txt"})

# Step 2: 使用正则拆分（使用 exec 调用脚本）
chapters = exec({"command": "python3 -c '...'"})

# Step 3: 保存各章节（使用 write 工具）
for chapter in chapters:
    write({"path": f"./novels/{project}/chapters/chapter_{n}.md", ...})
```

**实际调用方式**:
Agent 应该使用基础工具逐步执行上述流程。
```

### 工具调用优先级

1. **优先使用**: OpenClaw 基础工具
   - `read` - 读取文件
   - `write` - 写入文件
   - `edit` - 编辑文件
   - `exec` - 执行命令
   - `sessions_spawn` - 启动子智能体
   - `sessions_send` - 发送消息到其他 Agent

2. **其次使用**: LLM 能力
   - 文本生成
   - 内容分析
   - 创意写作

3. **最后使用**: 外部脚本
   - `scripts/export.sh` - 导出工具

### 文档结构建议

```markdown
# Agent 工具手册

## 基础工具

### 1. read - 读取文件
（说明 + 示例）

### 2. write - 写入文件
（说明 + 示例）

## 复杂任务指南

### 3. 章节拆分

**用途**: ...

**实现步骤**:
1. 调用 `read` 读取源文件
2. 调用 `exec` 使用脚本拆分
3. 调用 `write` 保存章节

**示例调用流程**:
```json
// Step 1
read({"path": "./source/novel.txt"})

// Step 2
exec({"command": "python3 -c '...'"})

// Step 3
write({"path": "./novels/项目名/chapters/chapter_001.md", ...})
```

## 注意事项
（使用建议和限制）
```

---

## 更新记录

- 2026-03-26: 初始版本，明确伪代码定位