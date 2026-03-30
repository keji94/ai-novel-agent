# 真相文件版本控制

## 为什么需要版本控制？

Phase 2 状态结算会更新 7 个真相文件。如果结算结果有误（如遗漏角色状态变化、错误记录资源消耗），会影响后续所有章节的一致性。版本控制允许回退到上一个正确状态。

## 快照机制

**创建时机**: Phase 2 结算开始之前

**实现**:
```json
exec({
  "command": "mkdir -p ./novels/{project}/context/tracking/.snapshots/chapter_{N}_pre && cp ./novels/{project}/context/tracking/*.md ./novels/{project}/context/tracking/*.json ./novels/{project}/context/tracking/.snapshots/chapter_{N}_pre/"
})
```

**快照目录**:
```
./novels/{project}/context/tracking/.snapshots/
├── chapter_10_pre/    # 第 10 章结算前快照
├── chapter_11_pre/    # 第 11 章结算前快照
├── ...
```

## 快照保留策略

- 保留最近 5 个章节的快照
- 超过 5 个时自动删除最旧的快照
- 删除命令: `rm -rf ./novels/{project}/context/tracking/.snapshots/chapter_{N-5}_pre/`

## 回滚流程

当发现真相文件结算有误时：

```
1. 确认需要回退到的版本（通常是上一个章节的快照）
2. 将快照内容复制回 tracking 目录
   exec({
     "command": "cp ./novels/{project}/context/tracking/.snapshots/chapter_{N}_pre/* ./novels/{project}/context/tracking/"
   })
3. 重新执行 Phase 2 状态结算
4. 验证新的结算结果
```

## 注意事项

- 快照是目录级别的完整复制，不是增量
- 回滚后必须重新结算当前章节，否则状态不连续
- 如果连续多章结算都有问题，可能需要回退到更早的快照
