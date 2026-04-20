#!/bin/bash
# rocky-know-how 搜索 v2.1
# Hybrid 搜索：向量 + BM25
# 用法: search.sh [选项] <关键词...>

VERSION="2.1"

# 默认值
MAX_RESULTS=10
SHOW_ALL=false
PREVIEW_MODE=false
FILTER_TAG=""
FILTER_AREA=""
KEYWORDS=()
CACHE_INFO=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)         SHOW_ALL=true; shift ;;
    --preview)     PREVIEW_MODE=true; shift ;;
    --since)       shift 2 ;;
    --max-results) MAX_RESULTS="$2"; shift 2 ;;
    --tag)         FILTER_TAG="$2"; shift 2 ;;
    --area)        FILTER_AREA="$2"; shift 2 ;;
    --cache-info)  CACHE_INFO=true; shift ;;
    --global)      shift ;;
    -h|--help)
      echo "rocky-know-how 搜索 v${VERSION}"
      echo ""
      echo "用法: search.sh [选项] <关键词...>"
      echo "  --all              显示所有"
      echo "  --preview          只显示摘要"
      echo "  --tag \"t1,t2\"      按标签搜索（AND）"
      echo "  --area infra       按领域搜索"
      echo "  --max-results N    最多显示N条（默认10）"
      echo "  --cache-info       显示缓存状态"
      exit 0 ;;
    -*)  echo "未知选项: $1"; exit 1 ;;
    *)   KEYWORDS+=("$1"); shift ;;
  esac
done

# 动态获取状态目录
get_state_dir() {
  if [ -n "$OPENCLAW_STATE_DIR" ]; then
    echo "$OPENCLAW_STATE_DIR"
  else
    echo "$HOME/.openclaw"
  fi
}

STATE_DIR=$(get_state_dir)
EXPERIENCES_FILE="$STATE_DIR/.learnings/experiences.md"
CACHE_FILE="$STATE_DIR/.learnings/experiences.json"

# 显示缓存状态
if $CACHE_INFO; then
  python3 - "$CACHE_FILE" << 'PYEOF'
import json
import sys

cache_file = sys.argv[1]
try:
    with open(cache_file, 'r') as f:
        cache = json.load(f)
except:
    print("缓存文件不存在或无效")
    sys.exit(1)

entries = cache.get('entries', {})
count = len(entries)
max_entries = cache.get('maxEntries', 1000)
last_update = cache.get('lastUpdate', 'N/A')

areas = {}
tags_count = {}
for entry in entries.values():
    area = entry.get('area', 'unknown')
    areas[area] = areas.get(area, 0) + 1
    for tag in entry.get('tags', '').split(','):
        if tag:
            tags_count[tag] = tags_count.get(tag, 0) + 1

print("=== 缓存状态 ===")
print(f"经验数量: {count} / {max_entries}")
print(f"最后更新: {last_update}")
print()
print("按领域分布:")
for area, num in sorted(areas.items(), key=lambda x: x[1], reverse=True):
    print(f"  {area}: {num}")
print()
print("热门标签:")
for tag, num in sorted(tags_count.items(), key=lambda x: x[1], reverse=True)[:10]:
    print(f"  {tag}: {num}")
PYEOF
  exit 0
fi

# 验证参数
if [ ${#KEYWORDS[@]} -eq 0 ] && ! $SHOW_ALL && [ -z "$FILTER_TAG" ] && [ -z "$FILTER_AREA" ]; then
  echo "请提供关键词，或使用 --all / --tag / --area"
  echo "用法: search.sh --help"
  exit 1
fi

# 准备搜索关键词
KEYWORD_ARG="${KEYWORDS[0]}"

# 显示模式
if $PREVIEW_MODE; then
  # 摘要模式
  python3 "$STATE_DIR/skills/rocky-know-how/scripts/_hybrid_search.py" "$CACHE_FILE" "$KEYWORD_ARG" "$MAX_RESULTS" 2>/dev/null | grep "^===" | head -20
else
  # 详细模式 - 使用 _hybrid_search.py
  python3 "$STATE_DIR/skills/rocky-know-how/scripts/_hybrid_search.py" "$CACHE_FILE" "$KEYWORD_ARG" "$MAX_RESULTS"
fi
