# 写后验证器

**用途**: 11 条确定性规则，零 LLM 成本，每章写完立刻触发。

## 验证规则

| 规则 | 级别 | 说明 |
|------|------|------|
| **禁止句式** | error | 「不是……而是……」 |
| **禁止破折号** | error | 「——」 |
| **转折词密度** | warning | 仿佛/忽然/竟然等，每 3000 字 ≤ 1 次 |
| **高疲劳词** | warning | 题材疲劳词单章每词 ≤ 1 次 |
| **元叙事** | error | 编剧旁白式表述 |
| **报告术语** | warning | 分析框架术语不入正文 |
| **作者说教** | warning | 显然/不言而喻等 |
| **集体反应** | warning | 「全场震惊」类套话 |
| **连续了字** | warning | ≥ 6 句连续含「了」 |
| **段落过长** | warning | ≥ 2 个段落超 300 字 |
| **本书禁忌** | error | book_rules.md 中的禁令 |

## 实现代码

```python
def validate_post_write(content, book_rules, genre_profile):
    violations = []

    # 1. 禁止句式检测
    if re.search(r'不是[^。]{0,10}而是', content):
        violations.append({
            "rule": "禁止句式",
            "severity": "error",
            "message": "检测到「不是...而是」句式"
        })

    # 2. 禁止破折号
    if '——' in content:
        violations.append({
            "rule": "禁止破折号",
            "severity": "error",
            "message": "检测到破折号「——」"
        })

    # 3. 转折词密度
    transition_words = ['仿佛', '忽然', '竟然', '居然', '不由得', '不禁']
    for word in transition_words:
        count = content.count(word)
        if count > len(content) / 3000:
            violations.append({
                "rule": "转折词密度",
                "severity": "warning",
                "message": f"「{word}」出现{count}次，超过阈值"
            })

    # 4. 高疲劳词（题材相关）
    fatigue_words = genre_profile.get('fatigueWords', [])
    for word in fatigue_words:
        if content.count(word) > 1:
            violations.append({
                "rule": "高疲劳词",
                "severity": "warning",
                "message": f"疲劳词「{word}」出现{content.count(word)}次"
            })

    # 5. 元叙事检测
    meta_patterns = [
        r'作为[^，]{0,5}，',
        r'要知道，',
        r'不得不说，'
    ]
    for pattern in meta_patterns:
        if re.search(pattern, content):
            violations.append({
                "rule": "元叙事",
                "severity": "error",
                "message": f"检测到元叙事表达"
            })

    # 6. 作者说教
    preach_words = ['显然', '不言而喻', '众所周知', '毋庸置疑']
    for word in preach_words:
        if word in content:
            violations.append({
                "rule": "作者说教",
                "severity": "warning",
                "message": f"检测到说教词「{word}」"
            })

    # 7. 集体反应套话
    collective_patterns = [
        r'全场[^，]{0,5}震惊',
        r'所有人[^，]{0,5}倒吸.*气',
        r'众人[^，]{0,5}瞳孔.*缩'
    ]
    for pattern in collective_patterns:
        if re.search(pattern, content):
            violations.append({
                "rule": "集体反应",
                "severity": "warning",
                "message": "检测到集体反应套话"
            })

    # 8. 连续了字
    sentences = re.split(r'[。！？]', content)
    consecutive_le = 0
    for sentence in sentences:
        if '了' in sentence:
            consecutive_le += 1
            if consecutive_le >= 6:
                violations.append({
                    "rule": "连续了字",
                    "severity": "warning",
                    "message": f"连续{consecutive_le}句含「了」"
                })
                break
        else:
            consecutive_le = 0

    # 9. 段落过长
    paragraphs = content.split('\n\n')
    long_paragraphs = [p for p in paragraphs if len(p) > 300]
    if len(long_paragraphs) >= 2:
        violations.append({
            "rule": "段落过长",
            "severity": "warning",
            "message": f"有{len(long_paragraphs)}个段落超过300字"
        })

    # 10. 本书禁忌（从 book_rules 读取）
    if book_rules and 'forbiddenWords' in book_rules:
        for word in book_rules['forbiddenWords']:
            if word in content:
                violations.append({
                    "rule": "本书禁忌",
                    "severity": "error",
                    "message": f"检测到禁忌词「{word}」"
                })

    return {
        "errors": [v for v in violations if v["severity"] == "error"],
        "warnings": [v for v in violations if v["severity"] == "warning"]
    }
```

## 自动修复

当验证器发现 **error** 级别违规时：
```python
if len(violations["errors"]) > 0:
    # 自动触发 spot-fix 模式
    fixed_content = spot_fix(content, violations["errors"])
    return fixed_content
```
