#!/bin/bash

# ============================================
# AI网文写作智能体 安装脚本
# Content Package: workspace-ai-novel-content
# ============================================

# 注意: 不要在最顶层 set -e，因为 read -p 在收到 EOF 时返回非零
# 改为在关键命令后手动检查退出码

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查工作目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载项目 .env 文件（如果存在）
# 优先级：环境变量 > .env 文件 > .env.example
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     📚 AI网文写作智能体 - 多Agent架构 安装程序          ║"
echo "║     Content Package: workspace-ai-novel-content         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Step 0: 依赖检查 ─────────────────────────────────────────────
print_info "检查依赖..."

DEPS_OK=true

if ! command -v python3 &>/dev/null; then
    print_error "未找到 python3，Agent 注册需要 Python 3"
    DEPS_OK=false
fi

if ! command -v openclaw &>/dev/null; then
    print_warning "未找到 openclaw CLI，安装完成后请先安装 OpenClaw"
fi

if [ "$DEPS_OK" = false ]; then
    print_error "缺少必要依赖，请安装后重试"
    exit 1
fi

# ── 检查是否已存在工作目录 ──────────────────────────────────────
WORKSPACE_BASE="$OC_HOME/workspace-ai-novel-agent"
if [ -d "$WORKSPACE_BASE" ]; then
    print_warning "检测到已存在工作目录: $WORKSPACE_BASE"
    read -p "是否备份现有配置并继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "安装已取消"
        exit 0
    fi

    # 备份现有配置
    BACKUP_DIR="$OC_HOME/workspace-ai-novel-agent_backup_$(date +%Y%m%d_%H%M%S)"
    print_info "备份现有配置到: $BACKUP_DIR"
    cp -r "$WORKSPACE_BASE" "$BACKUP_DIR"
fi

# ── Step 1: 复制 Agent 工作空间 ─────────────────────────────────
print_info "复制多Agent工作空间..."

SOURCE_WORKSPACE="$SCRIPT_DIR/workspace-ai-novel-agent"

if [ ! -d "$SOURCE_WORKSPACE" ]; then
    print_error "未找到源工作空间目录: $SOURCE_WORKSPACE"
    print_info "请确保项目完整，或从仓库重新克隆"
    exit 1
fi

# 定义所有Agent的工作空间（11个Agent）
declare -A WORKSPACES=(
    ["workspace-main"]="入口/Supervisor"
    ["workspace-planner"]="策划/大纲师"
    ["workspace-writer"]="写作/作者"
    ["workspace-editor"]="编辑/审核"
    ["workspace-reviser"]="修订者"
    ["workspace-chapter-analyzer"]="章节分析器"
    ["workspace-style-analyzer"]="文风分析器"
    ["workspace-detector"]="AI痕迹检测器"
    ["workspace-analyst"]="网文分析"
    ["workspace-operator"]="运营/分析"
    ["workspace-learner"]="写作技巧学习"
)

mkdir -p "$WORKSPACE_BASE"

for ws in "${!WORKSPACES[@]}"; do
    ws_path="$WORKSPACE_BASE/$ws"
    source_ws="$SOURCE_WORKSPACE/$ws"

    if [ -d "$source_ws" ]; then
        mkdir -p "$ws_path"
        mkdir -p "$ws_path/memory"

        # 复制所有 .md 文件
        for file in "$source_ws"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                cp "$file" "$ws_path/"
                print_info "  安装: $ws/$filename"
            fi
        done

        # 创建今日日记文件
        TODAY=$(date +%Y-%m-%d)
        touch "$ws_path/memory/$TODAY.md"
    else
        print_warning "  跳过: $source_ws 不存在"
    fi
done

# 复制 novel-config.json 到 workspace-main
if [ -f "$SCRIPT_DIR/config/novel-config.json" ]; then
    cp "$SCRIPT_DIR/config/novel-config.json" "$WORKSPACE_BASE/workspace-main/"
    print_info "  安装: novel-config.json"
fi

# 设置权限
find "$WORKSPACE_BASE" -type f -name "*.md" -exec chmod 644 {} \;
find "$WORKSPACE_BASE" -type f -name "*.json" -exec chmod 644 {} \;

print_success "Agent工作空间复制完成"

# ── Step 2: 安装 openclaw.json ──────────────────────────────────
install_openclaw_config() {
  print_info "安装 openclaw.json..."

  local SRC_CFG="$SCRIPT_DIR/openclaw.json"

  if [ ! -f "$SRC_CFG" ]; then
    print_error "未找到 openclaw.json: $SRC_CFG"
    return 1
  fi

  mkdir -p "$OC_HOME"

  # 如果已存在配置，备份
  if [ -f "$OC_CFG" ]; then
    cp "$OC_CFG" "$OC_CFG.bak.novel-agent-$(date +%Y%m%d-%H%M%S)"
    print_info "已备份配置: $OC_CFG.bak.*"
  fi

  # 复制源配置
  cp "$SRC_CFG" "$OC_CFG"
  print_success "openclaw.json 安装完成"
}

install_openclaw_config

# ── Step 3: 注册所有 Agents + Content Package ───────────────────
register_agents() {
  print_info "注册网文写作多Agent系统..."

  python3 << 'PYEOF'
import json, pathlib, sys, os
from datetime import datetime

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text(encoding='utf-8'))

# 定义所有 Agent（11个）
AGENTS = [
    {"id": "ai-novel-agent", "name": "网文写作智能体", "is_entry": True,
     "workspace": "workspace-ai-novel-agent/workspace-main"},
    {"id": "planner", "name": "策划/大纲师",
     "workspace": "workspace-ai-novel-agent/workspace-planner"},
    {"id": "writer", "name": "写作/作者",
     "workspace": "workspace-ai-novel-agent/workspace-writer"},
    {"id": "editor", "name": "编辑/审核",
     "workspace": "workspace-ai-novel-agent/workspace-editor"},
    {"id": "reviser", "name": "修订者",
     "workspace": "workspace-ai-novel-agent/workspace-reviser"},
    {"id": "chapter-analyzer", "name": "章节分析器",
     "workspace": "workspace-ai-novel-agent/workspace-chapter-analyzer"},
    {"id": "style-analyzer", "name": "文风分析器",
     "workspace": "workspace-ai-novel-agent/workspace-style-analyzer"},
    {"id": "detector", "name": "AI痕迹检测器",
     "workspace": "workspace-ai-novel-agent/workspace-detector"},
    {"id": "analyst", "name": "网文分析",
     "workspace": "workspace-ai-novel-agent/workspace-analyst"},
    {"id": "operator", "name": "运营/分析",
     "workspace": "workspace-ai-novel-agent/workspace-operator"},
    {"id": "learner", "name": "写作技巧学习",
     "workspace": "workspace-ai-novel-agent/workspace-learner"},
]

agents_cfg = cfg.setdefault('agents', {})

# 扁平对象格式
added = 0
for ag in AGENTS:
    ag_id = ag['id']
    if ag_id not in agents_cfg:
        entry = {
            'name': ag['name'],
            'workspace': ag['workspace'],
            'description': ag['name'],
            'enabled': True,
        }
        if ag.get('is_entry'):
            entry['is_entry'] = True
        agents_cfg[ag_id] = entry
        added += 1
        print(f'  + added: {ag_id} ({ag["name"]})')
    else:
        print(f'  ~ exists: {ag_id} (skipped)')

# 更新 ai-novel-agent 的 allowAgents 列表
if 'ai-novel-agent' in agents_cfg:
    subagents = agents_cfg['ai-novel-agent'].setdefault('subagents', {})
    allow = subagents.setdefault('allowAgents', [])
    expected_agents = [ag['id'] for ag in AGENTS if not ag.get('is_entry')]
    for agent_id in expected_agents:
        if agent_id not in allow:
            allow.append(agent_id)
            print(f'  + allowAgent: {agent_id}')

# 注册 Content Package: workspace-ai-novel-content
packages = cfg.setdefault('packages', {})
packages['workspace-ai-novel-content'] = {
    'name': 'AI网文写作智能体内容包',
    'version': '1.0.0',
    'description': '多Agent网文写作系统 - 11个Agent协作',
    'source': 'workspace-ai-novel-agent',
    'installedAt': datetime.now().isoformat()
}
print(f'  + registered: workspace-ai-novel-content')

# 绑定飞书群组（如果提供了 chat_id）
chat_id = os.environ.get('FEISHU_CHAT_ID', '')
if chat_id:
    bindings = cfg.setdefault('bindings', [])
    existing_binding = any(
        b.get('agentId') == 'ai-novel-agent' and
        b.get('match', {}).get('peer', {}).get('id') == chat_id
        for b in bindings
    )
    if not existing_binding:
        binding = {
            "agentId": "ai-novel-agent",
            "match": {
                "channel": "feishu",
                "peer": {"kind": "group", "id": chat_id}
            }
        }
        bindings.append(binding)
        print(f'  + bound: feishu group {chat_id} -> ai-novel-agent')
    else:
        print(f'  ~ binding exists: {chat_id} (skipped)')

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Done: {added} agents added')
PYEOF

  if [ $? -ne 0 ]; then
    print_error "Agent 注册失败"
    return 1
  fi

  print_success "Agents 注册完成"
}

register_agents

# ── Step 4: 创建所有 Agent 状态目录 (agentDir) ─────────────────────
create_agent_dirs() {
  print_info "创建所有Agent状态目录..."

  local AGENT_IDS=(
      "ai-novel-agent"
      "planner"
      "writer"
      "editor"
      "reviser"
      "chapter-analyzer"
      "style-analyzer"
      "detector"
      "analyst"
      "operator"
      "learner"
  )

  for agent_id in "${AGENT_IDS[@]}"; do
    local AGENT_DIR="$HOME/.openclaw/agents/$agent_id/agent"

    mkdir -p "$AGENT_DIR"

    local AUTH_PROFILES="$AGENT_DIR/auth-profiles.json"
    if [ ! -f "$AUTH_PROFILES" ]; then
      echo '{}' > "$AUTH_PROFILES"
      print_info "  创建: $agent_id/auth-profiles.json"
    else
      print_info "  已存在: $agent_id/auth-profiles.json (跳过)"
    fi

    local MODELS_JSON="$AGENT_DIR/models.json"
    if [ ! -f "$MODELS_JSON" ]; then
      echo '{}' > "$MODELS_JSON"
      print_info "  创建: $agent_id/models.json"
    else
      print_info "  已存在: $agent_id/models.json (跳过)"
    fi

    chmod 600 "$AUTH_PROFILES" "$MODELS_JSON" 2>/dev/null
  done

  print_success "Agent状态目录创建完成"
}

create_agent_dirs

# ── Step 5: 安装本地 Skills ─────────────────────────────────────
install_local_skills() {
  print_info "安装本地 Skills..."

  local SKILLS_SRC="$SCRIPT_DIR/skills"
  local SKILLS_DEST="$OC_HOME/skills"

  if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DEST"

    local skill_count=0
    for skill_dir in "$SKILLS_SRC"/*; do
      if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        # 如果目标目录已存在，先备份
        if [ -d "$SKILLS_DEST/$skill_name" ]; then
          print_info "  备份已存在的: $skill_name"
          mv "$SKILLS_DEST/$skill_name" "$SKILLS_DEST/${skill_name}_backup_$(date +%Y%m%d_%H%M%S)"
        fi
        cp -r "$skill_dir" "$SKILLS_DEST/"
        print_info "  安装: $skill_name"
        skill_count=$((skill_count + 1))
      fi
    done

    if [ $skill_count -gt 0 ]; then
      print_success "本地Skills安装完成 ($skill_count 个)"
    else
      print_warning "未找到有效的Skill目录"
    fi
  else
    print_warning "未找到本地Skills目录: $SKILLS_SRC"
  fi
}

install_local_skills

# ── Step 6: 配置 API Keys ───────────────────────────────────────
configure_api_keys() {
  print_info "配置 API Keys..."

  local ENV_FILE="$OC_HOME/.env"
  local SKILLS_DEST="$OC_HOME/skills"

  local API_KEY_CONFIGS=(
    "FEISHU_CHAT_ID:飞书群组ID:global"
    "IMA_OPENAPI_CLIENTID:IMA客户端ID:skill:ima-skill"
    "IMA_OPENAPI_APIKEY:IMA API密钥:skill:ima-skill"
  )

  local has_keys=0

  for item in "${API_KEY_CONFIGS[@]}"; do
    key_name="${item%%:*}"
    rest="${item#*:}"
    key_desc="${rest%%:*}"
    key_location="${rest#*:}"

    key_value="${!key_name}"

    if [ -n "$key_value" ]; then
      has_keys=1
      print_info "  检测到 $key_desc ($key_name)"

      if [ "$key_location" = "global" ]; then
        write_env_key "$ENV_FILE" "$key_name" "$key_value"
        print_info "    → $ENV_FILE"
      else
        skill_name="${key_location#skill:}"
        skill_env_file="$SKILLS_DEST/$skill_name/.env"
        write_env_key "$skill_env_file" "$key_name" "$key_value"
        print_info "    → $skill_env_file"
      fi
    fi
  done

  if [ $has_keys -eq 1 ]; then
    [ -f "$ENV_FILE" ] && chmod 600 "$ENV_FILE"
    print_success "API Keys 已配置"
  else
    print_warning "未检测到 API Keys 环境变量"
    echo ""
    echo "  可通过以下方式配置 API Keys:"
    echo ""
    echo "    IMA_OPENAPI_CLIENTID=xxx IMA_OPENAPI_APIKEY=xxx ./install.sh"
    echo ""
    echo "  或在安装后编辑对应的 .env 文件"
  fi
}

write_env_key() {
  local env_file="$1"
  local key_name="$2"
  local key_value="$3"

  mkdir -p "$(dirname "$env_file")"
  touch "$env_file"

  if grep -q "^${key_name}=" "$env_file" 2>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|^${key_name}=.*|${key_name}=${key_value}|" "$env_file"
    else
      sed -i "s|^${key_name}=.*|${key_name}=${key_value}|" "$env_file"
    fi
  else
    echo "${key_name}=${key_value}" >> "$env_file"
  fi

  chmod 600 "$env_file"
}

configure_api_keys

# ── Step 7: 创建必要的目录结构 ───────────────────────────────────
create_project_dirs() {
  print_info "创建项目目录结构..."

  mkdir -p "$OC_HOME/logs"
  mkdir -p "$OC_HOME/novels"
  mkdir -p "$OC_HOME/knowledge/techniques"
  mkdir -p "$OC_HOME/knowledge/analysis"
  mkdir -p "$OC_HOME/references"

  print_success "项目目录创建完成"
}

create_project_dirs

# ── 完成 ────────────────────────────────────────────────────────
echo ""
print_success "安装完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "📚 AI网文写作智能体已成功安装 (11 个 Agent)"
echo ""
echo "📦 Content Package: workspace-ai-novel-content"
echo ""
echo "📁 工作空间目录: $WORKSPACE_BASE"
echo "   - workspace-main             (入口/Supervisor)"
echo "   - workspace-planner          (策划/大纲师)"
echo "   - workspace-writer           (写作/作者)"
echo "   - workspace-editor           (编辑/审核)"
echo "   - workspace-reviser          (修订者)"
echo "   - workspace-chapter-analyzer (章节分析器)"
echo "   - workspace-style-analyzer   (文风分析器)"
echo "   - workspace-detector         (AI痕迹检测器)"
echo "   - workspace-analyst          (网文分析)"
echo "   - workspace-operator         (运营/分析)"
echo "   - workspace-learner          (写作技巧学习)"
echo ""
echo "📁 Agent状态目录: $HOME/.openclaw/agents/"
echo "📁 Skills目录: $OC_HOME/skills/"
echo "📁 配置文件: $OC_CFG"
echo ""
print_success "开始使用你的AI网文写作智能体吧!"
echo ""
echo "快速开始:"
echo "  1. 配置IMA API（可选，用于印象笔记同步）"
echo "     编辑: $OC_HOME/skills/ima-skill/.env"
echo ""
echo "  2. 启动系统"
echo "     openclaw start"
echo ""
echo "  3. 开始创作"
echo "     > 帮我写一本修仙小说"
echo ""
