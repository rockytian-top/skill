#!/bin/bash
# rocky-know-how 写入经验诀窍
# 用法: record.sh "<问题>" "<踩坑过程>" "<正确方案>" "<预防>" "<tags>" [area]
# 例: record.sh "排查网站只看进程" "第1次:只看进程→报正常" "curl验证" "必须curl" "troubleshooting" infra

SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

# 初始化
mkdir -p "$SHARED_DIR/archive"
if [ ! -f "$ERRORS_FILE" ]; then
  printf "# 经验诀窍\n\n---\n" > "$ERRORS_FILE"
fi

if [ $# -lt 5 ]; then
  echo "用法: record.sh \"<问题>\" \"<踩坑过程>\" \"<正确方案>\" \"<预防>\" \"<tags>\" [area]"
  echo "  area 可选: frontend|backend|infra|tests|docs|config (默认: infra)"
  exit 1
fi

PROBLEM="$1"
FAILURES="$2"
SOLUTION="$3"
PREVENT="$4"
TAGS="$5"
AREA="${6:-infra}"

# 精确重复检查：只在 "### 问题" 的下一行匹配问题文本
if grep -A1 '^### 问题$' "$ERRORS_FILE" 2>/dev/null | grep -qF "$PROBLEM"; then
  echo "⚠️  相同问题已存在，跳过写入"
  exit 0
fi

# 生成 ID
TODAY=$(date +%Y%m%d)
COUNT=$(grep -c "\[EXP-${TODAY}-" "$ERRORS_FILE" 2>/dev/null || echo "0")
COUNT=${COUNT:-0}
SEQ=$(printf "%03d" $((COUNT + 1)))
ID="EXP-${TODAY}-${SEQ}"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# 写入经验诀窍文件
cat >> "$ERRORS_FILE" << ENTRY

## [${ID}] ${PROBLEM}

**Area**: ${AREA}
**Failed-Count**: ≥2
**Tags**: ${TAGS}
**Created**: ${NOW}

### 问题
${PROBLEM}

### 踩坑过程
${FAILURES}

### 正确方案
${SOLUTION}

### 预防
${PREVENT}

---
ENTRY

echo "✅ 已写入经验诀窍: ${ID} [${AREA}]"

# P0: 同步写入 memory/*.md（让原生 memory_search 能搜到）
# 动态获取 workspace 路径
if [ -n "$OPENCLAW_WORKSPACE" ]; then
  MEMORY_DIR="$OPENCLAW_WORKSPACE/memory"
  MEMORY_FILE="$MEMORY_DIR/$(date +%Y-%m-%d).md"
elif [ -n "$OPENCLAW_SESSION_KEY" ]; then
  agentId=$(echo "$OPENCLAW_SESSION_KEY" | cut -d: -f2)
  MEMORY_DIR="$HOME/.openclaw/workspace-${agentId}/memory"
  MEMORY_FILE="$MEMORY_DIR/$(date +%Y-%m-%d).md"
else
  MEMORY_DIR="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/memory"
  MEMORY_FILE="$MEMORY_DIR/$(date +%Y-%m-%d).md"
fi

if [ -d "$MEMORY_DIR" ]; then
  cat >> "$MEMORY_FILE" << MEMEOF

## 📚 经验诀窍 ${ID}: ${PROBLEM}

- **踩坑**: ${FAILURES}
- **正确方案**: ${SOLUTION}
- **预防**: ${PREVENT}
- **Tags**: ${TAGS}

MEMEOF
  echo "✅ 已同步到 memory/$(date +%Y-%m-%d).md"
fi

# 异步晋升检查
(
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  "$SCRIPT_DIR/promote.sh" >> /dev/null 2>&1 &
)
