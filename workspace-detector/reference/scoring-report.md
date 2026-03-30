# 评分与报告实现细节

本文档包含工具 12-13 的完整实现代码。

---

### 12. calculate_ai_tell_score - 计算 AI 痕迹得分

**用途**: 综合所有检测结果，计算最终得分。

**实现**:
```python
def calculate_ai_tell_score(violations):
    total_deduction = sum(v['weight'] for v in violations)
    score = max(0, 100 - total_deduction)

    if score >= 90:
        level = "极低 AI 痕迹"
        suggestion = "通过"
    elif score >= 80:
        level = "低 AI 痕迹"
        suggestion = "通过"
    elif score >= 70:
        level = "中等 AI 痕迹"
        suggestion = "建议修订"
    elif score >= 60:
        level = "较高 AI 痕迹"
        suggestion = "需要修订"
    else:
        level = "高 AI 痕迹"
        suggestion = "建议重写"

    return {
        "score": score,
        "level": level,
        "suggestion": suggestion,
        "total_deduction": total_deduction
    }
```

---

### 13. generate_detection_report - 生成检测报告

**用途**: 生成完整的检测报告。

**实现**:
```python
def generate_detection_report(chapter_num, content, violations, statistics, score):
    report = f"""# AI 痕迹检测报告

## 基本信息
- 章节: 第{chapter_num}章
- 字数: {len(tokenize(content))}
- 检测时间: {datetime.now().isoformat()}
- AI 痕迹得分: {score['score']}/100

## 检测结果

### 确定性规则检测

| 规则 | 发现次数 | 权重 | 扣分 |
|------|----------|------|------|
"""

    # 按规则分组
    rule_counts = {}
    for v in violations:
        rule = v['rule']
        if rule not in rule_counts:
            rule_counts[rule] = {'count': 0, 'weight': v['weight']}
        rule_counts[rule]['count'] += 1

    for rule, data in rule_counts.items():
        deduction = data['count'] * data['weight']
        report += f"| {rule} | {data['count']} 次 | {data['weight']} | -{deduction} |\n"

    report += f"\n**总扣分**: -{score['total_deduction']}\n"

    # 统计特征
    report += f"""
### 统计特征检测

| 特征 | 数值 | 阈值 | 状态 |
|------|------|------|------|
| TTR | {statistics['ttr']:.3f} | ≥{statistics['thresholds']['ttr_min']} | {'✅' if statistics['ttr'] >= statistics['thresholds']['ttr_min'] else '⚠️'} |
| 句长标准差 | {statistics['sentence_length_std']:.1f} | ≥{statistics['thresholds']['sentence_std_min']} | {'✅' if statistics['sentence_length_std'] >= statistics['thresholds']['sentence_std_min'] else '⚠️'} |
| 主动句比例 | {statistics['active_ratio']*100:.1f}% | ≥{statistics['thresholds']['active_ratio_min']*100}% | {'✅' if statistics['active_ratio'] >= statistics['thresholds']['active_ratio_min'] else '⚠️'} |
"""

    # 问题定位
    report += "\n## 问题段落定位\n"
    for i, v in enumerate(violations[:10], 1):  # 只显示前10个
        if 'position' in v:
            report += f"""
### 问题 {i}: {v['rule']}
**位置**: 第{v['position']}段
**建议**: {v.get('suggestion', '')}
"""

    # 总结
    report += f"""
## 总结

- AI 痕迹得分: {score['score']}/100
- 检测级别: {score['level']}
- 建议: {score['suggestion']}
"""

    return report
```
