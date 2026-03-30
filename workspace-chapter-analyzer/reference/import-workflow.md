# 导入流程与断点续导

> 主文件: TOOLS.md

## 完整导入命令

```json
// 假设用户请求: "导入 ./source/我的小说.txt"

// Step 1: 读取源文件
content = read({"path": "./source/我的小说.txt"})

// Step 2: 创建项目
project_name = extract_project_name(content)  // 从内容中提取书名
exec({"command": f"mkdir -p ./novels/{project_name}/{{chapters,context}}"})

// Step 3: 拆分章节
chapters = split_chapters(content, "chinese")

// Step 4: 保存章节
for chapter in chapters:
    write({
        "path": f"./novels/{project_name}/chapters/chapter_{chapter['number']:03d}.md",
        "content": chapter['content']
    })

// Step 5: 逐章分析
all_info = {}
for chapter in chapters:
    info = analyze_chapter(chapter['content'], chapter['number'])
    all_info[chapter['number']] = info

// Step 6: 信息整合
consolidated = consolidate_info(all_info)

// Step 7: 生成真相文件
generate_truth_files(project_name, consolidated)

// Step 8: 生成导入报告
report = generate_import_report(chapters, consolidated)
write({"path": f"./novels/{project_name}/import_report.md", "content": report})
```

---

## 断点续导

**用途**: 导入中断后，从指定章节继续。

```json
// 用户请求: "继续导入，从第50章开始"

// Step 1: 读取已导入的章节
existing_chapters = exec({"command": f"ls ./novels/{project}/chapters/*.md"})

// Step 2: 确定续导起点
resume_from = 50

// Step 3: 只处理后续章节
for chapter in chapters[resume_from-1:]:
    // ... 分析和保存
```
