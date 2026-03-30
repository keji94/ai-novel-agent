# generate_truth_files 详细实现

> 主文件: TOOLS.md 工具 7

## 生成流程

```python
async def generate_truth_files(project_name, consolidated_info):
    base = f"./novels/{project_name}/context"

    # 确保目录存在
    await mkdir(f"{base}/tracking", recursive=True)
    await mkdir(f"{base}/summaries", recursive=True)

    # 1. 生成 current_state.md
    current_state = build_current_state(consolidated_info)
    await write(f"{base}/tracking/current_state.md", current_state)

    # 2. 生成 particle_ledger.md
    particle_ledger = build_particle_ledger(consolidated_info['resources'])
    await write(f"{base}/tracking/particle_ledger.md", particle_ledger)

    # 3. 生成 pending_hooks.md
    pending_hooks = build_pending_hooks(consolidated_info['foreshadowing'])
    await write(f"{base}/tracking/foreshadowing.json", pending_hooks)

    # 4. 生成 chapter_summaries.md
    chapter_summaries = build_chapter_summaries(consolidated_info)
    await write(f"{base}/summaries/chapter_summaries.md", chapter_summaries)

    # 5. 生成 subplot_board.md
    subplot_board = build_subplot_board(consolidated_info['subplots'])
    await write(f"{base}/tracking/subplot_board.md", subplot_board)

    # 6. 生成 emotional_arcs.md
    emotional_arcs = build_emotional_arcs(consolidated_info['emotions'])
    await write(f"{base}/tracking/emotional_arcs.md", emotional_arcs)

    # 7. 生成 character_matrix.md
    character_matrix = build_character_matrix(consolidated_info['characters'])
    await write(f"{base}/tracking/character_states.json", character_matrix)
```
