#!/bin/bash
# rocky-know-how 搜经验诀窍 v1.3.0
# 用法: search.sh [选项] <关键词1> [关键词2]...
#       search.sh --all              显示所有
#       search.sh --preview "关键词"  只显示摘要
#       search.sh --tag "tag1,tag2"   按标签搜索
#       search.sh --area infra       按领域搜索
#       search.sh --global "关键词"   搜所有workspace
#       search.sh --since YYYY-MM-DD  按日期过滤

MAX_RESULTS=10
SINCE_DATE=""
SHOW_ALL=false
PREVIEW=false
GLOBAL=false
FILTER_TAG=""
FILTER_AREA=""
KEYWORDS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)         SHOW_ALL=true; shift ;;
    --preview)     PREVIEW=true; shift ;;
    --global)      GLOBAL=true; shift ;;
    --since)       SINCE_DATE="$2"; shift 2 ;;
    --max-results) MAX_RESULTS="$2"; shift 2 ;;
    --tag)         FILTER_TAG="$2"; shift 2 ;;
    --area)        FILTER_AREA="$2"; shift 2 ;;
    -h|--help)
      echo "用法: search.sh [选项] <关键词...>"
      echo "  --all              显示所有"
      echo "  --preview          只显示摘要"
      echo "  --tag \"t1,t2\"      按标签搜索（AND）"
      echo "  --area infra       按领域搜索"
      echo "  --global           搜所有workspace"
      echo "  --since YYYY-MM-DD 按日期过滤"
      echo "  --max-results N    最多显示N条（默认10）"
      exit 0 ;;
    -*)  echo "未知选项: $1"; exit 1 ;;
    *)   KEYWORDS+=("$1"); shift ;;
  esac
done

SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

# --global: 收集各 agent workspace 的文件
EXTRA_FILES=()
if $GLOBAL; then
  for d in "$HOME"/.openclaw/workspace-*/.learnings/experiences.md; do
    [ -f "$d" ] && EXTRA_FILES+=("$d")
  done
fi

# 提取条目块（返回0=有数据，1=无）
# 用临时文件存放块，按相关度排序输出
TMPDIR_KH=$(mktemp -d /tmp/rocky-know-how-XXXXXX)
trap 'rm -rf "$TMPDIR_KH"' EXIT

extract_blocks() {
  local file="$1"
  [ ! -f "$file" ] && return 1

  local lines=$(grep -n "^## \[EXP-" "$file" 2>/dev/null | cut -d: -f1)
  [ -z "$lines" ] && return 1

  local block_idx=0
  local prev=""
  for line in $lines; do
    if [ -z "$prev" ]; then
      prev=$line
      continue
    fi
    sed -n "${prev},$((line-1))p" "$file" > "$TMPDIR_KH/block_${block_idx}.md"
    block_idx=$((block_idx+1))
    prev=$line
  done
  # 最后一个块
  local total=$(wc -l < "$file" | tr -d ' ')
  sed -n "${prev},${total}p" "$file" > "$TMPDIR_KH/block_${block_idx}.md"
  block_idx=$((block_idx+1))

  echo $block_idx
}

# 检查单个块是否匹配，返回相关度分数（0=不匹配）
score_block() {
  local block_file="$1"
  local score=0

  # 日期过滤
  if [ -n "$SINCE_DATE" ]; then
    local entry_date=$(grep "^## \[EXP-" "$block_file" | head -1 | sed 's/.*\[EXP-\([0-9]\{8\}\)-.*/\1/')
    local since_num=$(echo "$SINCE_DATE" | sed 's/-//g')
    [ "${entry_date:-0}" -lt "${since_num:-0}" ] 2>/dev/null && echo "0" && return
  fi

  # Area 过滤
  if [ -n "$FILTER_AREA" ]; then
    local entry_area=$(grep "^\*\*Area\*\*:" "$block_file" | head -1 | sed 's/\*\*Area\*\*: //')
    [ "$entry_area" != "$FILTER_AREA" ] && echo "0" && return
  fi

  # Tag 过滤（AND：所有指定 tag 都要命中）
  if [ -n "$FILTER_TAG" ]; then
    local entry_tags=$(grep "^\*\*Tags\*\*:" "$block_file" | head -1 | sed 's/\*\*Tags\*\*: //')
    local tag_miss=false
    for t in $(echo "$FILTER_TAG" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$'); do
      if ! echo ",${entry_tags}," | grep -qi --color=never ",${t}," 2>/dev/null; then
        tag_miss=true
        break
      fi
    done
    if $tag_miss; then
      echo "0" && return
    fi
  fi

  # 关键词匹配 + 计分
  local kw_len=${#KEYWORDS[@]:-0}
  if [ "$kw_len" -gt 0 ]; then
    local total_kw=$kw_len
    local hit=0
    for kw in "${KEYWORDS[@]}"; do
      grep -qi --color=never "$kw" "$block_file" && hit=$((hit+1))
    done
    [ $hit -eq 0 ] && echo "0" && return
    score=$hit
  else
    # 无关键词 = 匹配所有（--all / --tag / --area 场景）
    score=1
  fi

  echo "$score"
}

# 打印条目（预览或完整）
print_block() {
  local block_file="$1"
  local score="$2"
  local total_kw="${3:-1}"

  local id=$(grep "^## \[EXP-" "$block_file" | head -1 | sed 's/## //')
  local problem=$(sed -n '/^### 问题$/{n;p;}' "$block_file")
  local prevent=$(sed -n '/^### 预防$/{n;p;}' "$block_file")
  local solution=$(sed -n '/^### 正确方案$/{n;p;}' "$block_file")
  local tags=$(grep "^\*\*Tags\*\*:" "$block_file" | head -1 | sed 's/\*\*Tags\*\*: //')
  local area=$(grep "^\*\*Area\*\*:" "$block_file" | head -1 | sed 's/\*\*Area\*\*: //')

  if $PREVIEW; then
    echo "📌 $id [匹配度: ${score}/${total_kw}]"
    echo "   问题: $problem"
    echo "   方案: $solution"
    echo "   Tags: $tags | Area: $area"
    echo ""
  else
    echo "$id [匹配度: ${score}/${total_kw}]"
    echo "───────────────────────────────────"
    cat "$block_file"
    echo ""
  fi
}

# 搜索单个文件
search_file() {
  local file="$1"
  local count=$(extract_blocks "$file")
  [ -z "$count" ] && return 1
  [ "$count" -eq 0 ] && return 1

  local found=0
  local total_kw=${#KEYWORDS[@]:-0}
  [ "$total_kw" -eq 0 ] && total_kw=1

  # 评分 + 排序
  for i in $(seq 0 $((count-1))); do
    local block_file="$TMPDIR_KH/block_${i}.md"
    [ ! -f "$block_file" ] && continue
    local s=$(score_block "$block_file")
    [ "$s" = "0" ] && continue
    # 按分数存入排序文件
    echo "${s} ${i}" >> "$TMPDIR_KH/scores.txt"
  done

  [ ! -f "$TMPDIR_KH/scores.txt" ] && return 1

  # 按分数降序排序输出
  sort -rn -k1,1 "$TMPDIR_KH/scores.txt" | head -$MAX_RESULTS | while read -r s idx; do
    print_block "$TMPDIR_KH/block_${idx}.md" "$s" "$total_kw"
    found=$((found+1))
  done

  return 0
}

# 格式化全部条目（供 --all 使用）
format_all() {
  local file="$1"
  [ ! -f "$file" ] && return

  awk '
    /^## \[EXP-/ { id=$0; area=""; tags=""; created=""; problem="" }
    /^\*\*Area\*\*:/ { sub(/^\*\*Area\*\*: /,""); area=$0 }
    /^\*\*Tags\*\*:/ { sub(/^\*\*Tags\*\*: /,""); tags=$0 }
    /^\*\*Created\*\*:/ { sub(/^\*\*Created\*\*: /,""); created=$0 }
    /^### 问题$/ { getline; problem=$0 }
    /^---$/ && id!="" {
      printf "%s\n  Area: %s | Tags: %s | 创建: %s\n  问题: %s\n---\n\n", id, area, tags, created, problem
      id=""
    }
  ' "$file"
}

# --all 模式（不过滤/排序）
if $SHOW_ALL; then
  echo "=== 全部经验诀窍 ==="
  [ -f "$ERRORS_FILE" ] && format_all "$ERRORS_FILE"
  for f in "${EXTRA_FILES[@]:-}"; do
    [ "$f" = "$ERRORS_FILE" ] && continue
    [ -z "$f" ] && continue
    echo "--- $(basename "$(dirname "$f")") ---"
    format_all "$f"
  done
  exit 0
fi

# 需要关键词或过滤条件
if [ ${#KEYWORDS[@]} -eq 0 ] && [ -z "$FILTER_TAG" ] && [ -z "$FILTER_AREA" ]; then
  echo "用法: search.sh [选项] <关键词...>"
  echo "提示: 用 --tag / --area 过滤，或输入关键词搜索"
  exit 1
fi

# 搜索
total_found=0
for f in "$ERRORS_FILE" "${EXTRA_FILES[@]:-}"; do
  [ -z "$f" ] && continue
  rm -f "$TMPDIR_KH/scores.txt"
  search_file "$f" && total_found=1
done

[ $total_found -eq 0 ] && echo "经验诀窍未找到相关记录" && exit 1
exit 0
