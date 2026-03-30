# 题材专属规则

## 仙侠题材

```yaml
---
name: 仙侠
fatigueWords:
  - 冷笑
  - 蝼蚁
  - 倒吸凉气
  - 瞳孔骤缩
  - 天道
  - 大道
  - 因果
  - 气运
  - 仿佛
  - 不禁
  - 宛如
  - 竟然
auditDimensions: [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26]
---

## 题材禁忌
- 主角为推剧情突然仁慈、犯蠢
- 修为无铺垫跳跃式突破
- 法宝凭空出现解决危机
- 天道规则前后矛盾
- 用"大道无形"跳过修炼过程
- 同质资源不写衰减

## 修炼规则
- 境界突破必须有积累过程
- 同质资源重复炼化必须写明衰减
- 金手指四维约束：上限/代价/条件/路径
```

## 玄幻题材

```yaml
---
name: 玄幻
fatigueWords:
  - 妖孽
  - 逆天
  - 震撼
  - 恐怖
  - 惊人
  - 无法想象
  - 不可思议
auditDimensions: [1,2,3,4,5,6,7,8,9,10,11,13,14,15,16,17,18,19,24,25,26]
---

## 题材禁忌
- 主角光环过重
- 配角工具人化
- 战力崩坏
- 无脑打脸
```

---

## Token 用量统计

每次写作后，返回 Token 用量：

```json
{
  "phase1": {
    "promptTokens": 2500,
    "completionTokens": 3000,
    "totalTokens": 5500
  },
  "phase2": {
    "promptTokens": 1500,
    "completionTokens": 500,
    "totalTokens": 2000
  },
  "total": {
    "promptTokens": 4000,
    "completionTokens": 3500,
    "totalTokens": 7500
  }
}
```
