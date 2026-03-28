# Planner 工具手册

本文档定义 Planner (策划/大纲师) 可使用的工具。

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取项目设定、大纲、角色等文件。

**常用路径**:
- `./novels/{项目名}/project.json` - 项目元数据
- `./novels/{项目名}/settings/world.md` - 世界观设定
- `./novels/{项目名}/characters/main.md` - 主角设定
- `./novels/{项目名}/outline/main.md` - 总大纲

**示例**:
```json
read({"path": "./novels/仙道长生/settings/world.md"})
```

### 2. write - 写入文件

**用途**: 创建设定文件、大纲文件。

**示例**:
```json
write({
  "path": "./novels/仙道长生/settings/world.md",
  "content": "# 世界观设定\n\n..."
})
```

### 3. edit - 编辑文件

**用途**: 精确修改已有设定。

**示例**:
```json
edit({
  "path": "./novels/仙道长生/characters/main.md",
  "oldText": "境界：练气期",
  "newText": "境界：筑基期"
})
```

## 项目结构工具

### 4. 创建新项目结构

**用途**: 为新小说创建完整的目录结构。

**实现**: 使用 exec 命令

```json
exec({
  "command": "mkdir -p ./novels/项目名/{settings,characters,outline,chapters,context/{summaries,tracking,indexes},brainstorm}"
})
```

### 5. 创建项目元数据

**用途**: 创建 project.json。

**示例**:
```json
write({
  "path": "./novels/项目名/project.json",
  "content": "{\n  \"id\": \"proj_20260326_xxx\",\n  \"name\": \"项目名\",\n  \"genre\": \"仙侠\",\n  \"lifecycle\": {\"stage\": \"basic_design\"},\n  ...\n}"
})
```

## 灵感探索工具

### 6. 引导式提问

**用途**: 通过提问帮助用户明确创作方向。

**实现**: 直接输出问题，等待用户回答。

**探索维度**:
1. **类型偏好**: 仙侠/玄幻/都市/科幻/其他
2. **核心元素**: 穿越/重生/系统/签到/修炼体系
3. **金手指设计**: 类型选择、限制条件、成长空间
4. **主角身份**: 开局身份、性格特点、成长目标
5. **爽点定位**: 装逼打脸/逆袭成长/智斗布局/热血战斗

**示例输出**:
```
好的！让我帮你探索灵感。

首先，你喜欢什么类型的小说？
1. 仙侠（修仙飞升）
2. 玄幻（异世大陆）
3. 都市（现代异能）
4. 其他（请告诉我）
```

### 7. 记录用户决策

**用途**: 将用户的决策记录到 project.json。

**示例**:
```json
// 读取现有配置
project = read({"path": "./novels/项目名/project.json"})

// 更新决策
project.brainstorm.decisions.genre = {"value": "仙侠", "confirmed": true}

// 写回
write({"path": "./novels/项目名/project.json", "content": json.dumps(project)})
```

## 模板工具

### 8. 世界观模板

**输出格式**:
```markdown
# 世界观设定

## 基本信息
- 作品类型: {类型}
- 核心卖点: {卖点}
- 整体风格: {风格}

## 世界背景
[详细的世界背景描述]

## 力量体系
[修炼/能力体系详细设定]

## 势力格局
[各大势力介绍]

## 地理设定
[重要地点与地图]

## 特殊设定
[独特设定元素]

## 历史背景
[重要历史事件与时间线]
```

### 9. 角色卡片模板

**输出格式**:
```markdown
# 角色卡片：{角色名}

## 基本信息
- 姓名:
- 年龄:
- 身份:
- 初登场:

## 外貌特征
[详细外貌描述]

## 性格特点
[性格分析]

## 能力设定
[能力/境界/技能]

## 背景故事
[人物背景]

## 人物关系
[与其他角色的关系]

## 角色定位
- 功能定位:
- 剧情作用:
- 发展轨迹:

## 经典台词
[代表性台词]
```

### 10. 大纲模板

**输出格式**:
```markdown
# 剧情大纲

## 整体规划
- 预计字数:
- 卷数规划:
- 核心主题:

## 第一卷：{卷名}

### 卷简介
[本卷核心内容和目标]

### 章节规划

**第1-10章：开篇布局**
- 第1章：开篇钩子
- 第2章：世界观展示
...

### 本卷高潮
[本卷主要高潮点]

### 伏笔埋设
[本卷埋设的重要伏笔]

## 后续规划
[后续卷节简要规划]
```

## 输出建议

### 设定输出位置
- 世界观 → `./novels/{项目名}/settings/world.md`
- 力量体系 → `./novels/{项目名}/settings/power_system.md`
- 主角设定 → `./novels/{项目名}/characters/main.md`
- 配角设定 → `./novels/{项目名}/characters/supporting.md`
- 总大纲 → `./novels/{项目名}/outline/main.md`
- 卷大纲 → `./novels/{项目名}/outline/volume_{n}.md`

### 返回给 Supervisor
完成后，返回包含 `sync_hint` 的结果：

```json
{
  "status": "success",
  "response": "世界观设定已完成，包括：\n- 修仙世界框架\n- 力量体系（练气→筑基→金丹...）\n- 主角设定\n- 初步大纲（3卷规划）",
  "files_created": [
    "./novels/仙道长生/settings/world.md",
    "./novels/仙道长生/characters/main.md",
    "./novels/仙道长生/outline/main.md"
  ],
  "sync_hint": {
    "type": "settings",
    "project": "仙道长生",
    "files": [
      "./novels/仙道长生/settings/world.md",
      "./novels/仙道长生/characters/main.md",
      "./novels/仙道长生/outline/main.md"
    ]
  }
}
```

> **注意**: 子Agent只负责本地文件操作，云端同步由主Agent统一处理。返回 `sync_hint` 提示主Agent执行同步。