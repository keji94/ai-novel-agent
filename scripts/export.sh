#!/bin/bash
# 小说导出工具 - 支持 TXT、Markdown、EPUB 格式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 用法
usage() {
    echo "用法: $0 <command> <project_name> [options]"
    echo ""
    echo "命令:"
    echo "  txt <project>           导出为 TXT 格式"
    echo "  md <project>            导出为 Markdown 格式"
    echo "  epub <project>          导出为 EPUB 格式"
    echo ""
    echo "选项:"
    echo "  --output <path>         输出路径（默认: ./exports/）"
    echo "  --approved-only         只导出已审核的章节"
    echo "  --start <n>             从第 n 章开始"
    echo "  --end <n>               到第 n 章结束"
    echo ""
    echo "示例:"
    echo "  $0 epub 仙道长生"
    echo "  $0 txt 仙道长生 --approved-only"
    exit 1
}

# 检查依赖
check_dependencies() {
    if ! command -v pandoc &> /dev/null; then
        print_error "EPUB 导出需要安装 pandoc"
        print_info "安装方法:"
        echo "  Ubuntu/Debian: sudo apt install pandoc"
        echo "  macOS: brew install pandoc"
        echo "  Windows: choco install pandoc"
        exit 1
    fi
}

# 获取章节列表
get_chapters() {
    local project_dir=$1
    local approved_only=$2
    local start_chapter=$3
    local end_chapter=$4
    
    chapters=()
    
    for file in "$project_dir"/chapters/chapter_*.md; do
        if [[ -f "$file" ]]; then
            # 提取章节号
            filename=$(basename "$file")
            chapter_num=$(echo "$filename" | sed 's/chapter_//' | sed 's/.md//')
            
            # 范围过滤
            if [[ -n "$start_chapter" ]] && [[ "$chapter_num" -lt "$start_chapter" ]]; then
                continue
            fi
            if [[ -n "$end_chapter" ]] && [[ "$chapter_num" -gt "$end_chapter" ]]; then
                continue
            fi
            
            # 审核状态过滤
            if [[ "$approved_only" == "true" ]]; then
                if grep -q "status: approved" "$file" 2>/dev/null; then
                    chapters+=("$file")
                fi
            else
                chapters+=("$file")
            fi
        fi
    done
    
    # 排序
    IFS=$'\n' sorted=($(sort -V <<<"${chapters[*]}")); unset IFS
    chapters=("${sorted[@]}")
}

# 读取项目信息
read_project_info() {
    local project_dir=$1
    project_json="$project_dir/project.json"
    
    if [[ -f "$project_json" ]]; then
        project_name=$(jq -r '.name // .display_name' "$project_json")
        project_author=$(jq -r '.author // "AI Novel Agent"' "$project_json")
        project_description=$(jq -r '.description // ""' "$project_json")
    else
        project_name=$(basename "$project_dir")
        project_author="AI Novel Agent"
        project_description=""
    fi
}

# 导出 TXT
export_txt() {
    local project_dir=$1
    local output_file=$2
    
    print_info "导出为 TXT 格式..."
    
    > "$output_file"
    
    # 写入书名
    echo "$project_name" >> "$output_file"
    echo "作者: $project_author" >> "$output_file"
    echo "" >> "$output_file"
    
    # 写入章节
    for chapter in "${chapters[@]}"; do
        print_info "处理: $(basename "$chapter")"
        echo "" >> "$output_file"
        cat "$chapter" >> "$output_file"
        echo "" >> "$output_file"
    done
    
    print_success "TXT 导出完成: $output_file"
}

# 导出 Markdown
export_md() {
    local project_dir=$1
    local output_file=$2
    
    print_info "导出为 Markdown 格式..."
    
    > "$output_file"
    
    # 写入书名
    echo "# $project_name" >> "$output_file"
    echo "" >> "$output_file"
    echo "> 作者: $project_author" >> "$output_file"
    echo ">" >> "$output_file"
    echo "> $project_description" >> "$output_file"
    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
    
    # 目录
    echo "## 目录" >> "$output_file"
    echo "" >> "$output_file"
    for chapter in "${chapters[@]}"; do
        chapter_title=$(grep "^# " "$chapter" | head -1 | sed 's/^# //')
        if [[ -n "$chapter_title" ]]; then
            echo "- $chapter_title" >> "$output_file"
        fi
    done
    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
    
    # 写入章节
    for chapter in "${chapters[@]}"; do
        print_info "处理: $(basename "$chapter")"
        cat "$chapter" >> "$output_file"
        echo "" >> "$output_file"
        echo "---" >> "$output_file"
        echo "" >> "$output_file"
    done
    
    print_success "Markdown 导出完成: $output_file"
}

# 导出 EPUB
export_epub() {
    local project_dir=$1
    local output_file=$2
    
    check_dependencies
    
    print_info "导出为 EPUB 格式..."
    
    # 创建临时目录
    temp_dir=$(mktemp -d)
    content_file="$temp_dir/content.md"
    metadata_file="$temp_dir/metadata.xml"
    
    # 写入元数据
    cat > "$metadata_file" << EOF
<dc:title>$project_name</dc:title>
<dc:creator>$project_author</dc:creator>
<dc:description>$project_description</dc:description>
<dc:language>zh-CN</dc:language>
EOF
    
    # 写入内容
    > "$content_file"
    
    # 书名
    echo "# $project_name" >> "$content_file"
    echo "" >> "$content_file"
    
    # 写入章节
    for chapter in "${chapters[@]}"; do
        print_info "处理: $(basename "$chapter")"
        cat "$chapter" >> "$content_file"
        echo "" >> "$content_file"
    done
    
    # 使用 pandoc 转换
    pandoc "$content_file" \
        -o "$output_file" \
        --epub-metadata="$metadata_file" \
        --toc \
        --toc-depth=2 \
        --epub-chapter-level=2
    
    # 清理
    rm -rf "$temp_dir"
    
    print_success "EPUB 导出完成: $output_file"
}

# 主函数
main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi
    
    command=$1
    project=$2
    shift 2
    
    # 解析选项
    output_dir="./exports"
    approved_only=false
    start_chapter=""
    end_chapter=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output)
                output_dir=$2
                shift 2
                ;;
            --approved-only)
                approved_only=true
                shift
                ;;
            --start)
                start_chapter=$2
                shift 2
                ;;
            --end)
                end_chapter=$2
                shift 2
                ;;
            *)
                print_error "未知选项: $1"
                usage
                ;;
        esac
    done
    
    # 查找项目目录
    project_dir=""
    for dir in ./novels/*/; do
        if [[ $(basename "$dir") == "$project" ]]; then
            project_dir="$dir"
            break
        fi
    done
    
    if [[ -z "$project_dir" ]]; then
        print_error "项目不存在: $project"
        exit 1
    fi
    
    # 读取项目信息
    read_project_info "$project_dir"
    
    # 获取章节列表
    get_chapters "$project_dir" "$approved_only" "$start_chapter" "$end_chapter"
    
    if [[ ${#chapters[@]} -eq 0 ]]; then
        print_error "没有找到符合条件的章节"
        exit 1
    fi
    
    print_info "找到 ${#chapters[@]} 个章节"
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 执行导出
    case $command in
        txt)
            output_file="$output_dir/${project}.txt"
            export_txt "$project_dir" "$output_file"
            ;;
        md)
            output_file="$output_dir/${project}.md"
            export_md "$project_dir" "$output_file"
            ;;
        epub)
            output_file="$output_dir/${project}.epub"
            export_epub "$project_dir" "$output_file"
            ;;
        *)
            print_error "未知命令: $command"
            usage
            ;;
    esac
    
    echo ""
    print_success "导出完成!"
    echo "输出文件: $output_file"
}

main "$@"