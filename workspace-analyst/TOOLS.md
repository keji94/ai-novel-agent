# analyst 工具手册

## 文件操作工具

### 1. read - 读取文件

**用途**: 读取待分析内容、参考资料。

**常用路径**:
- `./novels/{项目名}/chapters/chapter_{n}.md` - 章节正文
- `./references/{作品名}/` - 参考作品库
- `./knowledge/techniques/` - 已有技巧知识库

### 2. write - 写入分析报告

**用途**: 保存分析结果。

**路径约定**:
- 分析报告: `./knowledge/analysis/{作品名}_分析报告.md`
- 技巧提取: 通过 Learner 入库到 `./knowledge/techniques/items/`

---

## 内容获取工具

### 3. playwright-scraper - 网页抓取

**用途**: 抓取知乎、微信公众号等平台的网页内容。

**适用平台**: 知乎回答/专栏、微信公众号文章、其他公开网页。

**使用方式**: 启动浏览器隐私模式抓取页面文本。

### 4. yzfly-douyin-mcp-server - 抖音视频

**用途**: 获取抖音视频的文案/脚本内容。

**适用平台**: douyin.com 视频。

**使用方式**: 通过 douyin-video skill 获取视频文字稿。

### 5. openclaw-tavily-search - 搜索

**用途**: 搜索补充信息、查找相关资料。

**使用方式**: 通过 tavily-search skill 执行搜索。

---

## URL 识别规则

| URL 模式 | 平台 | 内容类型 | 获取工具 |
|---------|------|----------|---------|
| zhihu.com/question/*/answer | 知乎回答 | answer | playwright-scraper |
| zhuanlan.zhihu.com/p/* | 知乎专栏 | article | playwright-scraper |
| mp.weixin.qq.com/s/* | 微信公众号 | article | playwright-scraper |
| douyin.com/video/* | 抖音视频 | video_script | douyin-video skill |

---

## 分析能力说明

Analyst 的核心分析能力（结构分析、节奏分析、爽点分析、技巧提取）不是独立工具，而是 Agent 自身的分析能力。

- **技巧提取标准**: `reference/technique-extraction.md`
- **长内容处理策略**: `reference/long-content-strategy.md`
- **输出格式模板**: `reference/output-templates.md`
