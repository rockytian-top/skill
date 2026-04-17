#!/bin/bash
# rocky-know-how 自动安装脚本 v1.3.4
# 用法: bash install.sh
# 本脚本只创建目录和初始化文件，不修改任何配置文件。

set -e

VERSION="1.3.4"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════╗"
echo "║  rocky-know-how 安装脚本 v${VERSION}       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. 创建共享 .learnings 目录
echo "📂 创建共享经验诀窍目录..."
SHARED_DIR="$HOME/.openclaw/.learnings"
mkdir -p "$SHARED_DIR/archive"
if [ ! -f "$SHARED_DIR/experiences.md" ]; then
  printf "# 经验诀窍\n\n---\n" > "$SHARED_DIR/experiences.md"
  echo "✅ 已初始化 $SHARED_DIR/experiences.md"
else
  echo "✅ 已存在 $SHARED_DIR/experiences.md"
fi

echo ""
echo "⚙️  配置 Hook（需手动完成）"
echo ""
echo "请在 openclaw.json 的 hooks.internal.load.extraDirs 中添加："
echo ""
echo "  \"$SKILL_DIR/hooks\""
echo ""
echo "示例："
echo '{'
echo '  "hooks": {'
echo '    "internal": {'
echo '      "load": {'
echo "        \"extraDirs\": [\"$SKILL_DIR/hooks\"]"
echo '      }'
echo '    }'
echo '  }'
echo '}'
echo ""
echo "配置完成后重启 Gateway: openclaw gateway restart"
echo ""
echo "🎉 安装完成！"
echo "  搜索: bash $SKILL_DIR/scripts/search.sh \"关键词\""
echo "  写入: bash $SKILL_DIR/scripts/record.sh ..."
echo "  统计: bash $SKILL_DIR/scripts/stats.sh"
