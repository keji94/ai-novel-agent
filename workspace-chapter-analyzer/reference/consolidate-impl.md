# consolidate_info 详细实现

> 主文件: TOOLS.md 工具 6

## 整合策略

```python
def consolidate_info(all_chapters_info):
    consolidated = {
        "characters": {},
        "resources": {},
        "foreshadowing": {},
        "emotions": {},
        "subplots": {}
    }

    # 1. 按时间顺序遍历章节
    for chapter_num, info in sorted(all_chapters_info.items()):
        # 2. 更新角色状态（后出现的覆盖前面的）
        for char in info['characters']:
            if char['name'] not in consolidated['characters']:
                consolidated['characters'][char['name']] = {
                    "first_appearance": chapter_num,
                    "states": []
                }
            consolidated['characters'][char['name']]['states'].append({
                "chapter": chapter_num,
                "state": char['state']
            })

        # 3. 累积资源变化
        for change in info['resources']:
            key = change['item']
            if key not in consolidated['resources']:
                consolidated['resources'][key] = []
            consolidated['resources'][key].append({
                "chapter": chapter_num,
                "change": change
            })

        # 4. 追踪伏笔状态
        for f in info['foreshadowing']:
            if f['status'] == 'planted':
                consolidated['foreshadowing'][f['context']] = {
                    "planted_chapter": chapter_num,
                    "status": "pending"
                }
            elif f['status'] == 'resolved':
                # 查找对应的已埋设伏笔
                for key in consolidated['foreshadowing']:
                    if is_related(f['context'], key):
                        consolidated['foreshadowing'][key]['resolved_chapter'] = chapter_num
                        consolidated['foreshadowing'][key]['status'] = "resolved"

    return consolidated
```
