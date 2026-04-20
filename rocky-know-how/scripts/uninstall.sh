#!/bin/bash
# rocky-know-how 卸载脚本
# 用法: bash uninstall.sh

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  rocky-know-how 卸载脚本                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

read -p "确定要卸载 rocky-know-how 吗？(y/N) " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "取消卸载"; exit 0; }

OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

# 1. 移除 Hook 配置
echo "⚙️  移除 Hook 配置..."
if [ -f "$OPENCLAW_CONFIG" ] && grep -q "rocky-know-how" "$OPENCLAW_CONFIG" 2>/dev/null; then
  echo "⚠️  请手动从 $OPENCLAW_CONFIG 移除 rocky-know-how 相关配置"
else
  echo "✅ 无 Hook 配置"
fi

# 2. 询问是否删除数据
echo ""
read -p "是否删除经验诀窍数据？(y/N) " confirm_data
if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
  echo "🗑️  删除经验诀窍数据..."
  SHARED_DIR="$HOME/.openclaw/.learnings"
  if [ -d "$SHARED_DIR" ]; then
    rm -rf "$SHARED_DIR"
    echo "✅ 已删除 $SHARED_DIR"
  fi
else
  echo "ℹ️  保留数据（~/.openclaw/.learnings/）"
fi

# 3. 重启
echo ""
echo "🔄 重启 Gateway..."
openclaw gateway restart 2>/dev/null && echo "✅ 已重启" || echo "⚠️  请手动重启"

echo ""
echo "🎉 卸载完成"
