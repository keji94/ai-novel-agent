# 分析流程示例

本文档展示 StyleAnalyzer 完整的文风分析流程。

---

## 完整流程

```json
// 用户请求: "分析 ./reference/作者A.txt 的文风"

// Step 1: 读取参考文本
content = read({"path": "./reference/作者A.txt"})

// Step 2: 检查字数
word_count = len(tokenize(content))
if word_count < 10000:
    return "警告：样本字数不足 10000，分析结果可能不准确"

// Step 3: 执行各项分析
profile = {
    "sentence_length": analyze_sentence_length(content),
    "vocabulary": analyze_vocabulary(content),
    "paragraph": analyze_paragraph(content),
    "sentence_types": analyze_sentence_types(content),
    "rhetoric": analyze_rhetoric(content),
    "rhythm": analyze_rhythm(content)
}

// Step 4: 保存风格指纹
write({
    "path": "./output/style_profile.json",
    "content": json.dumps(profile, ensure_ascii=False, indent=2)
})

// Step 5: 生成风格指南（调用 LLM）
guide = generate_style_guide(profile)

// Step 6: 保存风格指南
write({
    "path": "./output/style_guide.md",
    "content": guide
})

// Step 7: 返回分析报告
return {
    "status": "success",
    "word_count": word_count,
    "key_features": [
        f"平均句长: {profile['sentence_length']['mean']:.1f}字",
        f"词汇多样性: {profile['vocabulary']['ttr']:.3f}",
        f"对话占比: {profile['paragraph']['dialogue_ratio']*100:.1f}%"
    ],
    "files": [
        "./output/style_profile.json",
        "./output/style_guide.md"
    ]
}
```
