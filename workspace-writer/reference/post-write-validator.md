# 写后验证器

**用途**: 确定性规则验证，零 LLM 成本，每章写完立刻触发。

## 实现方式

规则定义：`rules/deterministic/` (D001-D010)
执行脚本：`.openclaw/skills/content-scanner/scripts/run_deterministic.py`
规则详情：`rules/_index.md`

```bash
python3 .openclaw/skills/content-scanner/scripts/run_deterministic.py \
  --input {章节文件} \
  --rules-dir rules/deterministic/ \
  --config workspace-checker/context/domain-config.yaml \
  --context-dir workspace-checker/context/ \
  --genre {题材}
```

## 本地额外规则

以下规则不在共享 `rules/` 中，由 Writer 本地维护：

| 规则 | 级别 | 说明 |
|------|------|------|
| **本书禁忌** | error | `book_rules.md` 中的禁令（每本书不同） |

## 自动修复

当验证器发现 **error** 级别违规时，自动触发 spot-fix 模式。
