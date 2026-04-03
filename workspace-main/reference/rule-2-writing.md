# 规则2: 内容撰写 & 规则2.5: 深度行检

## 规则2: 内容撰写流程

```
条件: 用户要撰写具体内容
动作:
  1. 检查上下文(大纲/设定 + settings_release.json)，不足先调 Planner 补充
  2. sessions_spawn("writer", 撰写章节)
     → Phase 0: 加载索引 + 本章相关设定详情
     → Phase 1: 写作（遵守设定门控）
     → Phase 2: 结算（更新设定状态）
  3. 自动触发 sessions_spawn("editor", 审核)
     → Mode 0: 含设定校验 3 条规则
     → IF 设定 error → Writer spot-fix → re-verify（max 2轮）
  3.5 关键章节 AI 痕迹检测（首章/高潮章/转折章）
     → sessions_spawn("detector", 快速检测)
     → IF AI 痕迹分数 < 70 → 进入 Fix Loop anti-detect 模式
  4. 草稿存档: copy chapter → chapters/drafts/第X章-标题_draft.md
     (仅当 drafts/ 下尚无此章草稿时保存)
  5. 返回 Writer 结果 + Editor 审核报告
```

## 规则2.5: 深度行检流程

```
条件（满足任一）:
  - Editor 审核不通过（C/D 级）
  - 关键章节写完（首章、高潮章、转折章）
  - 用户显式请求逐行检查
  - Reviser 修复后需验证

Phase 1: 深度检查
  1. sessions_spawn("checker", {
       chapter_path: "novels/{project}/chapters/第X章-标题.md",
       truth_files: {characters, foreshadowing, settings_release, timeline, recent_summary},
       check_mode: "full"
     }) → check_report

  ⚠️ 自检: 收到 check_report 后，立即检查 converged 状态。
     若 converged == false，必须立即进入 Phase 2 Fix Loop。
     不得停留在 Phase 1 等待用户指示。

Phase 2: Fix Loop（最多3轮，如有违规）
  2. WHILE round <= 3 AND NOT check_report.converged:
       a. 确定修订模式:
          - 1-3 critical → spot-fix
          - 4-8 critical → polish
          - >8 critical → rewrite
          - AI 痕迹为主 → anti-detect
       b. sessions_spawn("reviser", {
            mode: determined_mode,
            chapter_path: ...,
            violations: check_report.violations,
            truth_files: ...
          }) → revised_content
       c. sessions_spawn("checker", {
            chapter_path: ...,
            truth_files: ...,
            check_mode: "full"
          }) → check_report (复查)
       d. 收敛检查:
          - converged: critical == 0 AND warning ≤ 3 AND score ≥ 85
          - 停滞: score_delta ≤ 2 (round >= 2) → 展示趋势，等用户决策
       e. round += 1

Phase 3: 收敛后 Editor 复审
  3. sessions_spawn("editor", {
       mode: 1,  // 标准审计
       chapter_path: ...
     }) → final_editor_report

Phase 4: 返回结果
  4. 返回完整报告链:
     Checker 报告 + Reviser 修复记录 + Editor 复审结果

异常处理:
  - Editor C/D 级但 Checker 无违规 → 判定矛盾 → 展示双方报告，用户决策
  - 连续 3 轮停滞 → 上报用户
  - 修复引入新 critical（退化）→ 上报用户
```

### Checker 触发时机详情

| 触发场景 | 触发方 | 说明 |
|---------|--------|------|
| Editor 审核不通过(C/D级) | Supervisor 自动 | 精确定位问题行，辅助 Reviser 修复 |
| 关键章节写完 | Supervisor 自动 | 首章、高潮章、转折章需深度保障 |
| 用户显式请求 | 用户 | "逐行检查"/"深度检查"/"行级扫描" |
| Reviser 修复后 | Supervisor 自动 | 验证修复是否引入新问题 |
| 章节修改后 | Supervisor 自动 | 规则9修改完成后可选触发 |

### Checker 与 Editor 的关系

- **Editor 先行**: Editor Mode 0 快筛 → 通过 → 可发布；不通过 → Checker 接管
- **Checker 定位**: 行级精确定位 Editor 发现的章节级问题
- **互补而非替代**: Editor 看宏观（整章节奏、商业性），Checker 看微观（每句话的合规性）
- **Checker 后行**: Checker 收敛后必须经 Editor 复审确认整体质量
