# AI网文写作智能体

基于 OpenClaw 多Agent架构的网文写作智能体系统，通过 Supervisor 统一协调 11 个专业 Agent 协作完成网文创作任务。

## 快速开始

```bash
git clone <repo-url>
cd workspace-ai-novel-agent
./install.sh
openclaw start
```

## 安装说明

运行 `./install.sh` 会将 content package `workspace-ai-novel-content` 注册到 `~/.openclaw/`，包括：
- 11 个 Agent 工作空间定义
- openclaw.json 配置
- Skills（IMA云端同步）
- Agent 状态目录

## 可选配置

```bash
# IMA 云端同步
export IMA_OPENAPI_CLIENTID=your_client_id
export IMA_OPENAPI_APIKEY=your_api_key

# 飞书群组绑定
export FEISHU_CHAT_ID=your_chat_id
```

## 文档

- [CLAUDE.md](CLAUDE.md) - 完整项目文档（架构、Agent职责、工作流程、核心机制）
- [docs/USAGE.md](docs/USAGE.md) - 使用指南
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - 架构设计

## License

MIT
