# 检测流程示例

本文档包含完整的检测流程代码示例和批量检测实现。

---

## 单章检测流程

```json
// 用户请求: "检测第1章的AI痕迹"

// Step 1: 读取章节
content = read({"path": "./novels/仙道长生/chapters/chapter_001.md"})

// Step 2: 获取题材配置
genre_profile = read({"path": "./novels/仙道长生/story/genre_profile.json"})

// Step 3: 执行确定性规则检测
violations = []
violations.extend(detect_forbidden_patterns(content))
violations.extend(detect_transition_words(content))
violations.extend(detect_fatigue_words(content, genre_profile))
violations.extend(detect_meta_narrative(content))
violations.extend(detect_preachy_words(content))
violations.extend(detect_collective_reactions(content))
violations.extend(detect_consecutive_le(content))
violations.extend(detect_long_paragraphs(content))
violations.extend(detect_list_structure(content))

// Step 4: 计算统计特征
statistics = calculate_statistics(content)

// Step 5: 计算得分
score = calculate_ai_tell_score(violations)

// Step 6: 生成报告
report = generate_detection_report(1, content, violations, statistics, score)

// Step 7: 返回结果
return {
    "score": score['score'],
    "level": score['level'],
    "suggestion": score['suggestion'],
    "violations_count": len(violations),
    "report": report
}
```

---

## 批量检测

```json
// 检测整本书
for chapter_num in range(1, total_chapters + 1):
    content = read({"path": f"./novels/{project}/chapters/chapter_{chapter_num:03d}.md"})
    result = detect(content, genre_profile)
    results.append(result)

// 计算平均分
average_score = sum(r['score'] for r in results) / len(results)

// 分布统计
distribution = {
    "90-100": sum(1 for r in results if r['score'] >= 90),
    "80-89": sum(1 for r in results if 80 <= r['score'] < 90),
    "70-79": sum(1 for r in results if 70 <= r['score'] < 80),
    "60-69": sum(1 for r in results if 60 <= r['score'] < 70),
    "<60": sum(1 for r in results if r['score'] < 60)
}

// 高风险章节
high_risk = [i+1 for i, r in enumerate(results) if r['score'] < 70]
```
