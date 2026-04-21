#!/bin/bash
# rocky-know-how 从 memory/*.md 导入历史经验 v2.0.0
# 用法: import.sh [--dir /path/to/memory] [--dry-run] [--keywords "kw1,kw2"]

MEMORY_DIR=""
DRY_RUN=false
EXTRA_KEYWORDS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)       MEMORY_DIR="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --keywords)  EXTRA_KEYWORDS="$2"; shift 2 ;;
    -h|--help)
      echo "用法: import.sh [--dir /path/to/memory] [--dry-run] [--keywords \"kw1,kw2\"]"
      echo "  --dir       memory 目录路径（默认自动检测）"
      echo "  --dry-run   只预览不写入"
      echo "  --keywords  额外识别关键词（逗号分隔）"
      exit 0 ;;
    *) shift ;;
  esac
done

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
get_state_dir() { [ -n "$OPENCLAW_STATE_DIR" ] && echo "$OPENCLAW_STATE_DIR" || echo "$HOME/.openclaw"; }
STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"
CORRECTIONS_FILE="$SHARED_DIR/corrections.md"

KEYWORDS_PATTERN="踩坑|教训|经验|注意|切记|避免|不要|必须|坑|Bug|bug|错误|失败|解决|排查|修复"
[ -n "$EXTRA_KEYWORDS" ] && KEYWORDS_PATTERN="${KEYWORDS_PATTERN}|$(echo "$EXTRA_KEYWORDS" | tr ',' '|')"

if [ -n "$OPENCLAW_WORKSPACE" ]; then
  WORKSPACE="$OPENCLAW_WORKSPACE"
elif [ -n "$OPENCLAW_SESSION_KEY" ]; then
  agentId=$(echo "$OPENCLAW_SESSION_KEY" | cut -d: -f2)
  WORKSPACE="$STATE_DIR/workspace-${agentId}"
else
  WORKSPACE="$STATE_DIR/workspace"
fi

[ -z "$MEMORY_DIR" ] && MEMORY_DIR="$WORKSPACE/memory"

[ ! -d "$MEMORY_DIR" ] && echo "❌ memory 目录不存在: $MEMORY_DIR" && exit 1

echo "=== 导入经验诀窍 v2.0.0 ==="
echo "扫描目录: $MEMORY_DIR"
$DRY_RUN && echo "模式: 预览（dry-run）"
echo ""

mkdir -p "$SHARED_DIR/archive"
[ ! -f "$ERRORS_FILE" ] && printf "# 经验诀窍\n\n---\n" > "$ERRORS_FILE"

imported=0
skipped=0

TODAY=$(date +%Y%m%d)
BASE_COUNT=$(grep -c --color=never "\[EXP-${TODAY}-" "$ERRORS_FILE" 2>/dev/null)
BASE_COUNT=${BASE_COUNT:-0}
case "$BASE_COUNT" in
  ''|*[!0-9]*) BASE_COUNT=0 ;;
esac

TMPDIR_IMPORT=$(mktemp -d /tmp/rocky-know-how-import-XXXXXX)
trap 'rm -rf "$TMPDIR_IMPORT"' EXIT

for md_file in "$MEMORY_DIR"/*.md; do
  [ ! -f "$md_file" ] && continue
  basename_file=$(basename "$md_file")
  echo "📄 扫描: $basename_file"

  para_idx=0
  current_para=""
  while IFS= read -r line; do
    if [ -z "$line" ]; then
      if [ -n "$current_para" ]; then
        echo "$current_para" > "$TMPDIR_IMPORT/para_${para_idx}.txt"
        echo "$basename_file" > "$TMPDIR_IMPORT/para_${para_idx}_src.txt"
        para_idx=$((para_idx+1))
        current_para=""
      fi
    else
      if [ -n "$current_para" ]; then
        current_para="${current_para}"$'\n'"${line}"
      else
        current_para="$line"
      fi
    fi
  done < "$md_file"

  if [ -n "$current_para" ]; then
    echo "$current_para" > "$TMPDIR_IMPORT/para_${para_idx}.txt"
    echo "$basename_file" > "$TMPDIR_IMPORT/para_${para_idx}_src.txt"
    para_idx=$((para_idx+1))
  fi
done

for para_file in "$TMPDIR_IMPORT"/para_*.txt; do
  [ ! -f "$para_file" ] && continue
  echo "$para_file" | grep -q "_src\." && continue

  para=$(cat "$para_file")
  para_idx=$(echo "$para_file" | sed 's/.*para_\([0-9]*\)\.txt/\1/')
  source_file="$TMPDIR_IMPORT/para_${para_idx}_src.txt"
  source_name=$(cat "$source_file" 2>/dev/null || echo "unknown")

  if ! echo "$para" | grep -qiE --color=never "$KEYWORDS_PATTERN"; then
    continue
  fi

  para_len=${#para}
  [ "$para_len" -lt 20 ] && continue
  [ "$para_len" -gt 500 ] && continue

  first_line=$(echo "$para" | head -1 | head -c 50)
  if grep -qF --color=never "$first_line" "$ERRORS_FILE" 2>/dev/null; then
    skipped=$((skipped+1))
    continue
  fi

  imported=$((imported+1))
  BASE_COUNT=$((BASE_COUNT+1))
  SEQ=$(printf "%03d" "$BASE_COUNT")
  ID="EXP-${TODAY}-${SEQ}"
  NOW=$(date '+%Y-%m-%d %H:%M:%S')

  area="infra"
  echo "$para" | grep -qiE --color=never "前端|html|css|js|react|vue" && area="frontend"
  echo "$para" | grep -qiE --color=never "php|后端|api|数据库|sql" && area="backend"
  echo "$para" | grep -qiE --color=never "测试|test|审核" && area="tests"
  echo "$para" | grep -qiE --color=never "配置|config|环境" && area="config"

  tags="imported"
  echo "$para" | grep -qi "vps" && tags="$tags,vps"
  echo "$para" | grep -qi "docker" && tags="$tags,docker"
  echo "$para" | grep -qi "nginx" && tags="$tags,nginx"
  echo "$para" | grep -qi "ssh" && tags="$tags,ssh"
  echo "$para" | grep -qi "redis" && tags="$tags,redis"
  echo "$para" | grep -qi "git" && tags="$tags,git"
  echo "$para" | grep -qi "mac" && tags="$tags,macOS"
  echo "$para" | grep -qi "plugin\|插件" && tags="$tags,plugin"

  title=$(echo "$para" | head -1 | sed 's/^#+ *//' | head -c 60)
  [ -z "$title" ] && title="从 $source_name 导入"

  if $DRY_RUN; then
    echo "  📌 将导入: $ID - $title (${para_len}字)"
  else
    cat >> "$ERRORS_FILE" << ENTRY

## [${ID}] ${title}

**Area**: ${area}
**Failed-Count**: ≥2
**Tags**: ${tags}
**Created**: ${NOW}
**Source**: import from ${source_name}
**Namespace**: global

### 问题
${title}

### 踩坑过程
（从历史记录导入）

### 正确方案
${para}

### 预防
（待补充）

---
ENTRY
    echo "  ✅ 已导入: $ID - $title (${para_len}字)"
  fi
done

echo ""
echo "=== 导入完成 ==="
echo "  导入: $imported 条"
echo "  跳过（重复）: $skipped 条"
$DRY_RUN && echo "  （dry-run 模式，未实际写入）"
