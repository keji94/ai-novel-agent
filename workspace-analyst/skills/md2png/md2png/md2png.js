const { marked } = require('marked');
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// 配置 - 小红书风格，更紧凑
const CONFIG = {
  width: 1080,
  padding: 40,
  fontSize: 24,
  lineHeight: 1.6
};

// HTML 模板 - 紧凑风格
const HTML_TEMPLATE = (content) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Color+Emoji&display=swap');
    
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 
        "PingFang SC", 
        "Hiragino Sans GB", 
        "Microsoft YaHei", 
        "Noto Sans SC",
        -apple-system, 
        BlinkMacSystemFont, 
        "Segoe UI", 
        sans-serif,
        "Apple Color Emoji", 
        "Segoe UI Emoji", 
        "Noto Color Emoji";
      line-height: ${CONFIG.lineHeight};
      color: #333;
      background: #fff;
      padding: ${CONFIG.padding}px;
      width: ${CONFIG.width}px;
      margin: 0 auto;
      font-size: ${CONFIG.fontSize}px;
      font-variant-numeric: tabular-nums;
    }
    
    h1 {
      font-size: 36px;
      font-weight: 700;
      color: #1a1a1a;
      margin-bottom: 15px;
      padding-bottom: 10px;
      border-bottom: 3px solid #FF2442;
      line-height: 1.3;
    }
    
    h2 {
      font-size: 28px;
      font-weight: 600;
      color: #FF2442;
      margin: 25px 0 12px 0;
      padding-left: 10px;
      border-left: 4px solid #FF2442;
      line-height: 1.3;
    }
    
    h3 {
      font-size: 24px;
      font-weight: 600;
      color: #333;
      margin: 18px 0 10px 0;
    }
    
    p {
      margin: 10px 0;
      text-align: justify;
      line-height: 1.7;
    }
    
    ul, ol {
      margin: 12px 0;
      padding-left: 28px;
    }
    
    li {
      margin: 6px 0;
      line-height: 1.6;
    }
    
    strong {
      color: #FF2442;
      font-weight: 600;
    }
    
    hr {
      border: none;
      height: 2px;
      background: linear-gradient(to right, #FF2442, #FFE4E1);
      margin: 25px 0;
    }
    
    code {
      background: #f5f5f5;
      padding: 2px 5px;
      border-radius: 4px;
      font-family: "SF Mono", Consolas, monospace;
      font-size: 20px;
      color: #e74c3c;
    }
    
    blockquote {
      border-left: 4px solid #FF2442;
      padding-left: 12px;
      margin: 12px 0;
      color: #666;
      background: #fff5f5;
      padding: 8px 12px;
      border-radius: 0 6px 6px 0;
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 12px 0;
      font-size: 20px;
    }
    
    th, td {
      border: 1px solid #eee;
      padding: 8px 10px;
      text-align: left;
    }
    
    th {
      background: #FF2442;
      color: #fff;
      font-weight: 600;
    }
    
    tr:nth-child(even) {
      background: #fafafa;
    }
    
    em {
      color: #999;
      font-size: 18px;
      font-style: normal;
    }
    
    /* 分页标记 - 用于智能分页 */
    .page-break {
      page-break-after: always;
      break-after: page;
    }
  </style>
</head>
<body>
${content}
</body>
</html>
`;

/**
 * Launch browser - prefer system Edge on Windows to avoid slow Chromium download
 */
async function launchBrowser() {
  if (process.platform === 'win32') {
    try {
      return await chromium.launch({ channel: 'msedge' });
    } catch (e) {
      console.log('Edge not available, fallback to Playwright Chromium');
    }
  }
  return chromium.launch();
}

/**
 * 智能分页截图 - 按内容块分页，避免截断文字
 */
async function md2png(mdPath, outputDir) {
  const mdContent = fs.readFileSync(mdPath, 'utf-8');
  
  // 解析 Markdown，按 h2 章节分割
  const sections = await parseMarkdownSections(mdContent);
  
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const baseName = path.basename(mdPath, '.md');
  console.log(`正在处理: ${mdPath}`);
  console.log(`共 ${sections.length} 个章节`);

  const browser = await launchBrowser();
  
  try {
    const images = [];
    
    // 按策略分两张图
    // 图1: 书名 + 简介 + 世界观 + 金手指 + 黄金一章
    // 图2: 前三章 + 前{N}章 + 推荐亮点

    // 找出书名（第一个 h1 标题）
    const bookTitleSection = sections.find(s => s.content.startsWith('# '));

    // 图1: 简介、世界观、金手指、黄金一章（排除所有"前X章"）
    const page1Sections = sections.filter(s => {
      const title = s.title;
      // 排除所有"前X章"的内容
      if (/前\d*章/.test(title)) return false;
      // 排除推荐亮点
      if (title.includes('💡') || title.includes('推荐亮点')) return false;
      // 包含：📝简介、🌍世界观、✨金手指、🔥黄金一章
      return title.includes('📝') ||
             title.includes('🌍') ||
             title.includes('✨') ||
             title.includes('🔥');
    });

    // 把书名放在最前面
    if (bookTitleSection && !page1Sections.includes(bookTitleSection)) {
      page1Sections.unshift(bookTitleSection);
    }

    // 图2: 前三章、前{N}章、推荐亮点
    const page2Sections = sections.filter(s => {
      const title = s.title;
      // 包含：📚前三章、📖前{N}章、💡推荐亮点
      return title.includes('📚') ||
             /前\d*章/.test(title) ||
             title.includes('💡') ||
             title.includes('推荐亮点');
    });

    // 生成第一张图
    if (page1Sections.length > 0) {
      const page1Html = HTML_TEMPLATE(page1Sections.map(s => s.html).join('\n'));
      const img1 = await renderPage(browser, page1Html, outputDir, `${baseName}_1`);
      if (img1) images.push(img1);
    }

    // 生成第二张图
    if (page2Sections.length > 0) {
      const page2Html = HTML_TEMPLATE(page2Sections.map(s => s.html).join('\n'));
      const img2 = await renderPage(browser, page2Html, outputDir, `${baseName}_2`);
      if (img2) images.push(img2);
    }

    console.log(`\n✨ 完成！共生成 ${images.length} 张图片`);
    return images;
    
  } finally {
    await browser.close();
  }
}

/**
 * 解析 Markdown，按 h2 章节分割
 */
async function parseMarkdownSections(mdContent) {
  const lines = mdContent.split('\n');
  const sections = [];
  let currentSection = null;
  let currentLines = [];

  for (const line of lines) {
    // 检测 h2 标题 (## 开头)
    if (line.startsWith('## ')) {
      // 保存上一个章节
      if (currentSection) {
        sections.push({
          title: currentSection,
          content: currentLines.join('\n'),
          html: await marked.parse(currentLines.join('\n'))
        });
      }
      // 开始新章节
      currentSection = line.replace('## ', '').trim();
      currentLines = [line];
    } else if (line.startsWith('# ')) {
      // h1 标题，作为第一个章节
      if (currentSection) {
        sections.push({
          title: currentSection,
          content: currentLines.join('\n'),
          html: await marked.parse(currentLines.join('\n'))
        });
      }
      currentSection = line.replace('# ', '').trim();
      currentLines = [line];
    } else {
      currentLines.push(line);
    }
  }
  
  // 保存最后一个章节
  if (currentSection) {
    sections.push({
      title: currentSection,
      content: currentLines.join('\n'),
      html: await marked.parse(currentLines.join('\n'))
    });
  }

  return sections;
}

/**
 * 渲染单页并截图（整页截图，不裁剪）
 */
async function renderPage(browser, html, outputDir, fileName) {
  const page = await browser.newPage();
  
  try {
    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1000);

    // 获取内容实际高度
    const height = await page.evaluate(() => document.body.scrollHeight);
    
    // 设置视口为内容实际大小
    await page.setViewportSize({ width: CONFIG.width, height: height + 100 });

    const outputPath = path.join(outputDir, `${fileName}.png`);
    
    await page.screenshot({
      path: outputPath,
      fullPage: true
    });

    const size = (fs.statSync(outputPath).size / 1024).toFixed(1);
    console.log(`✅ 已生成: ${outputPath} (${size}KB, ${height}px高)`);
    
    return outputPath;
    
  } finally {
    await page.close();
  }
}

// 命令行调用
const args = process.argv.slice(2);
if (args.length >= 2) {
  const [mdPath, outputDir] = args;
  md2png(mdPath, outputDir).catch(console.error);
} else {
  console.log('用法: node md2png.js <md文件路径> <输出目录>');
}

module.exports = { md2png, CONFIG };
