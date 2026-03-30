# 审计结果处理逻辑

> 审计通过条件、自动修订触发与修订模式选择。

---

## 审计通过条件

```python
def is_audit_passed(audit_result):
    # 无 critical 问题
    if len(audit_result['critical']) > 0:
        return False

    # warning 问题 ≤ 5 个
    if len(audit_result['warning']) > 5:
        return False

    # 通过维度 ≥ 28/33
    if audit_result['passed_dimensions'] < 28:
        return False

    return True
```

## 自动修订触发

```python
def handle_audit_result(audit_result, chapter_content):
    if is_audit_passed(audit_result):
        return {
            "status": "passed",
            "content": chapter_content
        }

    # 有 critical 问题，触发修订
    if len(audit_result['critical']) > 0:
        # 确定修订模式
        mode = determine_revision_mode(audit_result)

        return {
            "status": "needs_revision",
            "mode": mode,
            "issues": audit_result['critical'],
            "suggestions": audit_result['suggestions']
        }

    # 只有 warning 问题
    return {
        "status": "passed_with_warnings",
        "warnings": audit_result['warning']
    }
```

## 修订模式选择

| 问题类型 | 修订模式 | 说明 |
|----------|----------|------|
| 1-3 个 critical | spot-fix | 定点修复问题句子 |
| 4-6 个 critical | polish | 润色整个段落 |
| >6 个 critical | rewrite | 重写整个章节 |
| AI 痕迹过多 | anti-detect | 去AI味改写 |
| 大纲偏离 | rework | 调整结构 |
