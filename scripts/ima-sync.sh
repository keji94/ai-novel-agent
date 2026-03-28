#!/bin/bash
# IMA同步工具 - 双写双读支持
# 用法: ./ima-sync.sh <action> [options]

set -e

# 加载凭证
IMA_CLIENT_ID="${IMA_OPENAPI_CLIENTID:-$(cat ~/.config/ima/client_id 2>/dev/null)}"
IMA_API_KEY="${IMA_OPENAPI_APIKEY:-$(cat ~/.config/ima/api_key 2>/dev/null)}"

if [ -z "$IMA_CLIENT_ID" ] || [ -z "$IMA_API_KEY" ]; then
    echo "错误: 缺少IMA凭证，请配置环境变量或配置文件"
    echo "  环境变量: IMA_OPENAPI_CLIENTID, IMA_OPENAPI_APIKEY"
    echo "  配置文件: ~/.config/ima/client_id, ~/.config/ima/api_key"
    exit 1
fi

# API调用函数
ima_api() {
    local path="$1" body="$2"
    curl -s -X POST "https://ima.qq.com/$path" \
        -H "ima-openapi-clientid: $IMA_CLIENT_ID" \
        -H "ima-openapi-apikey: $IMA_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$body"
}

# 搜索笔记本
search_notebook() {
    local name="$1"
    ima_api "openapi/note/v1/search_note_book" "{
        \"search_type\": 0,
        \"query_info\": {\"title\": \"$name\"},
        \"start\": 0,
        \"end\": 20
    }"
}

# 创建笔记
create_note() {
    local title="$1"
    local content="$2"
    local folder_id="$3"

    local body="{\"content_format\": 1, \"content\": \"$content\""
    if [ -n "$folder_id" ]; then
        body="$body, \"folder_id\": \"$folder_id\""
    fi
    body="$body}"

    ima_api "openapi/note/v1/import_doc" "$body"
}

# 读取笔记
read_note() {
    local doc_id="$1"
    ima_api "openapi/note/v1/get_doc_content" "{
        \"doc_id\": \"$doc_id\",
        \"target_content_format\": 0
    }"
}

# 从路径提取项目名
get_project_name() {
    local file_path="$1"
    # 从 ./novels/项目名/... 提取项目名
    echo "$file_path" | sed 's|./novels/||' | cut -d'/' -f1
}

# 从路径提取内容类型
get_content_type() {
    local file_path="$1"
    if [[ "$file_path" == *"/settings/"* ]]; then
        echo "settings"
    elif [[ "$file_path" == *"/characters/"* ]]; then
        echo "characters"
    elif [[ "$file_path" == *"/outline/"* ]]; then
        echo "outline"
    elif [[ "$file_path" == *"/chapters/"* ]]; then
        echo "chapters"
    elif [[ "$file_path" == *"/techniques/"* ]]; then
        echo "technique"
    else
        echo "unknown"
    fi
}

# 同步单个文件到IMA
sync_file() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "文件不存在: $file_path"
        return 1
    fi

    local project_name=$(get_project_name "$file_path")
    local content_type=$(get_content_type "$file_path")
    local notebook_name="小说：《$project_name》"

    # 读取文件内容并转JSON
    local content
    content=$(cat "$file_path" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

    # 从文件路径提取标题
    local title
    title=$(basename "$file_path" .md)

    echo "同步: $file_path → IMA"
    echo "  项目: $project_name"
    echo "  类型: $content_type"
    echo "  标题: $title"

    # 创建笔记
    create_note "$title" "$content"
}

# 同步多个文件
sync_files() {
    local files="$@"
    local count=0

    for file in $files; do
        if sync_file "$file"; then
            ((count++))
        fi
    done

    echo ""
    echo "同步完成: $count 个文件"
}

# 从IMA搜索
search_ima() {
    local query="$1"
    echo "搜索: $query"
    ima_api "openapi/note/v1/search_note_book" "{
        \"search_type\": 1,
        \"query_info\": {\"content\": \"$query\"},
        \"start\": 0,
        \"end\": 20
    }"
}

# 主命令
case "$1" in
    sync)
        # 同步文件（支持多个文件）
        shift
        if [ $# -eq 0 ]; then
            echo "用法: $0 sync <file1> [file2] ..."
            exit 1
        fi
        sync_files "$@"
        ;;
    sync-settings)
        # 兼容旧接口
        sync_file "$4"
        ;;
    sync-chapter)
        # 兼容旧接口
        sync_file "$4"
        ;;
    search)
        search_ima "$2"
        ;;
    read)
        read_note "$2"
        ;;
    *)
        echo "用法: $0 <action> [args]"
        echo ""
        echo "动作:"
        echo "  sync <file1> [file2] ...    同步文件到IMA（推荐）"
        echo "  search <query>              搜索IMA内容"
        echo "  read <doc_id>               读取笔记内容"
        echo ""
        echo "示例:"
        echo "  $0 sync ./novels/仙道长生/chapters/chapter_1.md"
        echo "  $0 sync ./novels/仙道长生/settings/world.md ./novels/仙道长生/characters/main.md"
        ;;
esac