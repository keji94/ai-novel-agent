# 输出格式模板

> 主文件: TOOLS.md

## current_state.md 模板

```markdown
# 世界状态

> 最后更新: 第{N}章

## 当前地点

### 主要场景
- {地点1}: {描述}
- {地点2}: {描述}

## 势力格局

### 主要势力
| 势力 | 类型 | 实力 | 关系 |
|------|------|------|------|
| 青云宗 | 宗门 | 强 | 友好 |
| 魔教 | 门派 | 极强 | 敌对 |

## 已知信息

### 主角已知
- {信息1}
- {信息2}

## 时间线

- 第1章: {事件}
- 第5章: {事件}
- 第10章: {事件}
```

## character_matrix.md 模板

```json
{
  "characters": {
    "林风": {
      "name": "林风",
      "first_appearance": 1,
      "last_appearance": 157,
      "current_state": {
        "cultivation": "筑基初期",
        "location": "青云宗内门",
        "equipment": ["玄铁剑", "储物袋(中品)"],
        "skills": ["青云剑诀(圆满)"],
        "resources": ["下品灵石 x500"]
      },
      "personality": ["谨慎", "果断", "重情义"],
      "speaking_style": "简洁直接",
      "known_info": ["宗门秘辛", "师姐身份"],
      "unknown_info": ["师父真实身份", "系统来源"],
      "relationships": {
        "苏婉": "相识→好友",
        "赵天": "仇敌"
      },
      "emotional_arc": {
        "start": "压抑、渴望变强",
        "current": "自信、有责任感",
        "key_events": [
          {"chapter": 1, "event": "觉醒签到系统", "emotion": "惊喜→期待"},
          {"chapter": 10, "event": "突破筑基", "emotion": "焦虑→喜悦"}
        ]
      }
    }
  }
}
```
