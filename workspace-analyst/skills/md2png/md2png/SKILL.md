# Markdown 转图片工具 (md2png)

## 概述
将 Markdown 文档渲染为精美图片，支持自动分页。适用于生成网文扫榜报告的分享图。

## 适用场景
- 将 Markdown 报告转为图片分享
- 网文扫榜报告生成分享图
- 长文档自动分页截图

---

## 使用方法

### 基本用法

```
将 Markdown 文件转为图片：
- 输入文件：{md文件路径}
- 输出目录：{输出目录}
- 每张图高度：{高度px，默认2000}
```

### 执行步骤

1. **读取 Markdown 文件内容**
2. **转换为带样式的 HTML**
3. **使用 Playwright 渲染并截图**
4. **自动分页，保存多张图片**

---

## 输出规范

### 文件命名
```
{原文件名}_1.png
{原文件名}_2.png
...
```

### 默认样式
- 宽度：800px
- 每张图高度：2000px（可自定义）
- 字体：系统默认字体
- 配色：白色背景，深色文字，蓝色标题

---

## 依赖工具

- Node.js
- Playwright
- marked（Markdown 解析）

---

## 实现代码

### 步骤 1：检查依赖

```bash
# 检查 Node.js
node --version

# 安装依赖（如果未安装）
npm install -g marked playwright
npx playwright install chromium
```

### 步骤 2：创建转换脚本

创建脚本文件 `~/.openclaw/workspace/skills/md2png/md2png.js`：

```javascript
const { marked } = require('marked');
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  width: 800,
  pageHeight: 2000,
  padding: 40
};

// HTML 模板
const HTML_TEMPLATE = (content) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
      line-height: 1.8;
      color: #333;
      background: #fff;
      padding: ${CONFIG.padding}px;
      max-width: ${CONFIG.width}px;
      margin: 0 auto;
    }
    
    /* 标题样式 */
    h1 {
      font-size: 28px;
      font-weight: 700;
      color: #1a1a1a;
      margin-bottom: 20px;
      padding-bottom: 15px;
      border-bottom: 3px solid #2d8cf0;
    }
    
    h2 {
      font-size: 22px;
      font-weight: 600;
      color: #2d8cf0;
      margin: 30px 0 15px 0;
      padding-left: 12px;
      border-left: 4px solid #2d8cf0;
    }
    
    h3 {
      font-size: 18px;
      font-weight: 600;
      color: #333;
      margin: 20px 0 10px 0;
    }
    
    /* 段落 */
    p {
      font-size: 16px;
      line-height: 1.9;
      margin-bottom: 15px;
      text-align: justify;
    }
    
    /* 列表 */
    ul, ol {
      margin: 15px 0;
      padding-left: 25px;
    }
    
    li {
      font-size: 16px;
      line-height: 1.8;
      margin-bottom: 8px;
    }
    
    /* 强调 */
    strong {
      color: #e74c3c;
      font-weight: 600;
    }
    
    /* 分割线 */
    hr {
      border: none;
      height: 2px;
      background: linear-gradient(to right, #2d8cf0, #67c23a);
      margin: 30px 0;
      border-radius: 2px;
    }
    
    /* 代码 */
    code {
      background: #f5f7fa;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: "Fira Code", Consolas, monospace;
      font-size: 14px;
      color: #e96900;
    }
    
    /* 引用 */
    blockquote {
      border-left: 4px solid #67c23a;
      padding: 10px 15px;
      margin: 15px 0;
      background: #f9f9f9;
      color: #666;
      font-style: italic;
    }
    
    /* 表格 */
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 15px 0;
    }
    
    th, td {
      border: 1px solid #e0e0e0;
      padding: 10px 12px;
      text-align: left;
    }
    
    th {
      background: #2d8cf0;
      color: #fff;
      font-weight: 600;
    }
    
    tr:nth-child(even) {
      background: #f9f9f9;
    }
    
    /* Emoji 图标 */
    .emoji {
      font-size: 20px;
    }
    
    /* 页脚 */
    .footer {
      text-align: center;
      color: #999;
      font-size: 14px;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #eee;
    }
  </style>
</head>
<body>
${content}
</body>
</html>
`;

async function md2png(mdPath, outputDir, pageHeight = CONFIG.pageHeight) {
  // 读取 Markdown 文件
  const mdContent = fs.readFileSync(mdPath, 'utf-8');
  
  // 转换为 HTML
  const htmlContent = await marked.parse(mdContent);
  const fullHtml = HTML_TEMPLATE(htmlContent);
  
  // 确保输出目录存在
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // 生成输出文件名前缀
  const baseName = path.basename(mdPath, '.md');
  
  // 启动浏览器
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  // 设置内容
  await page.setContent(fullHtml, { waitUntil: 'networkidle' });
  
  // 获取总高度
  const totalHeight = await page.evaluate(() => document.body.scrollHeight);
  
  console.log(`文档总高度: ${totalHeight}px`);
  console.log(`每页高度: ${pageHeight}px`);
  console.log(`预计页数: ${Math.ceil(totalHeight / pageHeight)} 页`);
  
  const images = [];
  const pageCount = Math.ceil(totalHeight / pageHeight);
  
  // 分页截图
  for (let i = 0; i < pageCount; i++) {
    const outputPath = path.join(outputDir, `${baseName}_${i + 1}.png`);
    
    // 计算当前页的截图区域
    const y = i * pageHeight;
    const height = Math.min(pageHeight, totalHeight - y);
    
    await page.screenshot({
      path: outputPath,
      clip: {
        x: 0,
        y: y,
        width: CONFIG.width + CONFIG.padding * 2,
        height: height
      }
    });
    
    images.push(outputPath);
    console.log(`已生成: ${outputPath}`);
  }
  
  await browser.close();
  
  console.log(`\n完成！共生成 ${images.length} 张图片`);
  return images;
}

// 命令行调用
const args = process.argv.slice(2);
if (args.length >= 2) {
  const [mdPath, outputDir, pageHeight] = args;
  md2png(mdPath, outputDir, pageHeight ? parseInt(pageHeight) : CONFIG.pageHeight)
    .catch(console.error);
} else {
  console.log('用法: node md2png.js <md文件路径> <输出目录> [每页高度]');
}

module.exports = { md2png };
```

---

## 使用示例

### 命令行使用

```bash
# 基本用法
node ~/.openclaw/workspace/skills/md2png/md2png.js input.md ./output/

# 指定每页高度
node ~/.openclaw/workspace/skills/md2png/md2png.js input.md ./output/ 1500
```

### 在其他 Skill 中调用

```javascript
const { md2png } = require('/root/.openclaw/workspace/skills/md2png/md2png.js');

// 转换 Markdown 为图片
const images = await md2png(
  '/path/to/report.md',
  '/path/to/output/',
  2000  // 每页高度
);

console.log('生成的图片:', images);
```

---

## 与 sanjiang-analyzer 集成

在三江书单分析完成后，自动生成分享图片：

```bash
# 分析完成后，将报告转为图片
node ~/.openclaw/workspace/skills/md2png/md2png.js \
  ~/.openclaw/workspace/article/{书名}_三江速评.md \
  ~/.openclaw/workspace/article/images/
```

---

## 注意事项

1. **首次使用需要安装 Chromium**：
   ```bash
   npx playwright install chromium
   ```

2. **图片宽度固定 800px**，适合社交媒体分享

3. **长文档自动分页**，每页默认 2000px

4. **支持中文**，使用系统默认中文字体
