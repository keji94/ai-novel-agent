# 项目管理工具

## 7. check_project_recovery - 检查项目恢复

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

## 8. create_draft_project - 创建临时项目

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
