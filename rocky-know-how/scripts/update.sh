#!/bin/bash
# rocky-know-how 经验更新脚本 v1.4.1
# 根据上下文更新/优化现有经验
# 用法: bash update.sh "经验ID" "补充内容" [area]

set -e

VERSION="1.4.1"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

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
BACKUP_DIR="$STATE_DIR/.learnings/backups"

# 参数检查
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "用法: bash update.sh \"经验ID\" \"补充内容\" [area]"
  echo "示例: bash update.sh \"EXP-20260420-001\" \"新增：VPS5也适用此方案\" \"infra\""
  exit 1
fi

EXP_ID="$1"
SUPPLEMENT="$2"
AREA="${3:-}"

echo "=== rocky-know-how 经验更新 v${VERSION} ==="
echo "经验ID: $EXP_ID"
echo "补充内容: $SUPPLEMENT"
echo ""

# 创建备份
mkdir -p "$BACKUP_DIR"
backup_file="$BACKUP_DIR/experiences_$(date +%Y%m%d_%H%M%S).md"
cp "$EXPERIENCES_FILE" "$backup_file"
echo "已备份到: $backup_file"

# 检查经验是否存在
if ! grep -q "## \[$EXP_ID\]" "$EXPERIENCES_FILE"; then
  echo "错误：找不到经验 $EXP_ID"
  echo "可用的经验ID："
  grep "^## \[" "$EXPERIENCES_FILE" | sed 's/## //' | sed 's/\]//'
  exit 1
fi

# 提取当前经验的版本信息
CURRENT_BLOCK=$(awk "/## \[$EXP_ID\]/,/^---/" "$EXPERIENCES_FILE")
CURRENT_VERSION=$(echo "$CURRENT_BLOCK" | grep -oE "v[0-9]+" | head -1 || echo "v1")
VERSION_NUM=$(echo "$CURRENT_VERSION" | sed 's/v//')
NEW_VERSION_NUM=$((VERSION_NUM + 1))
NEW_VERSION="v${NEW_VERSION_NUM}"

# 提取原经验的Area和Tags
ORIGINAL_AREA=$(echo "$CURRENT_BLOCK" | grep -i "^\\*\\*Area\\*\\*:" | sed 's/.*://' | sed 's/^ *//' || echo "${AREA}")
ORIGINAL_TAGS=$(echo "$CURRENT_BLOCK" | grep -i "^\\*\\*Tags\\*\\*:" | sed 's/.*://' | sed 's/^ *//' || echo "")

# 如果提供了新的area，使用新的；否则使用原area
FINAL_AREA="${AREA:-$ORIGINAL_AREA}"

# 提取原经验内容
ORIGINAL_PROBLEM=$(echo "$CURRENT_BLOCK" | sed -n '/### 问题/,/###/p' | head -1 | sed 's/### 问题//')
ORIGINAL_SOLUTION=$(echo "$CURRENT_BLOCK" | sed -n '/### 解决/,/###/p' | head -1 | sed 's/### 解决//')
ORIGINAL_PREVENTION=$(echo "$CURRENT_BLOCK" | sed -n '/### 预防/,/###/p' | head -1 | sed 's/### 预防//')

echo "原版本: $CURRENT_VERSION"
echo "新版本: $NEW_VERSION"
echo ""

# 构建新的经验块
cat >> "$EXPERIENCES_FILE" << NEW_EXP

---

## [$EXP_ID-$NEW_VERSION] $(echo "$CURRENT_BLOCK" | grep "## \[" | sed 's/## \[.*\] //' | sed 's/(.*//')

**Area**: ${FINAL_AREA}
**Tags**: ${ORIGINAL_TAGS}
**Source**: auto-update
**Created**: $(date -u +%Y-%m-%dT%H:%M:%S.000Z)
**Version**: $NEW_VERSION (优化版本)
**Replaces**: $EXP_ID-$CURRENT_VERSION

### 问题
$(echo "$CURRENT_BLOCK" | sed -n '/### 问题/,/### 解决/p' | sed '1d' | sed '$d')

### 踩坑过程
$(echo "$CURRENT_BLOCK" | sed -n '/### 踩坑过程/,/### 正确方案/p' | sed '1d' | sed '$d')

### 正确方案
$(echo "$CURRENT_BLOCK" | sed -n '/### 正确方案/,/### 预防/p' | sed '1d' | sed '$d')

### 预防
$(echo "$CURRENT_BLOCK" | sed -n '/### 预防/,/^---/p' | sed '1d' | sed '$d')

### 📝 用户补充
$SUPPLEMENT

NEW_EXP

echo "✅ 经验已更新为 $EXP_ID-$NEW_VERSION"
echo ""
echo "更新内容："
echo "$SUPPLEMENT"
