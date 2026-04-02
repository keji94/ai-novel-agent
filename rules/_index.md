# Rules 总索引

> 所有质量规则的单一事实来源。各 Agent 引用此目录，不复制规则内容。

## 概览

| 类别 | 数量 | 目录 | 执行方 |
|------|------|------|--------|
| 确定性规则 (Phase 1) | 21 | `deterministic/` | Checker（脚本执行）、Editor Mode 0、Detector、Writer |
| LLM 规则 (Phase 2) | 19 | `llm/` | Checker（语义判断） |
| AI 替换表 | 8 | `replacements/` | Reviser、Writer |
| 学习规则 | 动态 | `learned/` | Checker（自管理） |

## 确定性规则 (deterministic/)

Phase 1 规则，零 LLM 成本，由 `run_deterministic.py` 脚本执行。

| 文件 | 规则 ID | 内容 | severity |
|------|---------|------|----------|
| `forbidden-patterns.yaml` | D001-D003 | 禁止句式、破折号、元叙事 | critical |
| `word-frequency.yaml` | D004-D008 | 转折词密度、疲劳词、报告术语、说教词、集体套话 | warning |
| `structure.yaml` | D009-D012 | 连续了字、段落过长、列表式结构、段首重复 | warning/critical |
| `settings-gate.yaml` | D013-D015 | 设定提前释放、认知越级、重复引入 | critical/warning |
| `statistics.yaml` | D016-D021 | TTR、句长std、段长std、主动句比例、字数下限、字数上限 | warning |

## LLM 规则 (llm/)

Phase 2 规则，逐段 LLM 语义判断。

| 文件 | 规则 ID | 内容 | severity |
|------|---------|------|----------|
| `consistency.yaml` | L001-L005 | OOC、时间线、设定冲突、战力、数值 | critical |
| `quality.yaml` | L006-L010 | 信息越界、利益链、配角降智、视角、伏笔 | critical/warning |
| `narrative.yaml` | L011-L015 | 对话失真、流水账、情感突变、节奏单调、知识污染 | warning |
| `contextual.yaml` | L016-L019 | 角色状态、场景连续、指代消解、逻辑连贯 | critical/warning |

## AI 替换表 (replacements/)

| 文件 | 内容 |
|------|------|
| `ai-traces.yaml` | 8 条 AI 套话 → 人类表达替换 |

## 学习规则 (learned/)

从 Checker 反馈自动生成，经用户审核后生效。详见 `learned/_index.yaml`。

生命周期：experimental → review_pending → active / deprecated

## Agent 引用指南

| Agent | 引用规则 | 用途 |
|-------|---------|------|
| **Checker** | deterministic/ + llm/ + learned/ | 执行检查（权威执行者） |
| **Editor** | deterministic/ (Mode 0), llm/ (交叉引用) | 快速验证 + 章节审计 |
| **Detector** | deterministic/ (D001-D012, D016-D021) + replacements/ | AI 痕迹检测 |
| **Reviser** | replacements/ai-traces.yaml | anti-detect 修复 |
| **Writer** | deterministic/ (D001-D010) + replacements/ | 写作约束 + 后验证 |

## 维护指南

- **新增规则**: 在对应分类文件中添加 → 更新本索引统计 → 检查 domain-config.yaml
- **修改规则**: 修改 YAML → 更新本索引 changelog → 检查 domain-config + 引用方
- **废弃规则**: 设 status: deprecated，不删除 ID
- **命名规范**: ID 连续编号，文件名小写中划线

## Changelog

- 2026-04-02: 初始创建，从 workspace-checker/rules/ 迁移，38 条规则
- 2026-04-02: 新增 D020-D021 章节字数规则（2000-3000字）
