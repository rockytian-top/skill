#!/bin/bash
# rocky-know-how 自动安装脚本 v1.3.0
# 用法: bash install.sh [--skip-config] [--force]

set -e

VERSION="1.3.0"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
SKIP_CONFIG=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-config) SKIP_CONFIG=true; shift ;;
    --force)       FORCE=true; shift ;;
    -h|--help)
      echo "用法: install.sh [--skip-config] [--force]"
      exit 0 ;;
  esac
done

echo "╔══════════════════════════════════════════╗"
echo "║  rocky-know-how 安装脚本 v${VERSION}       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. 检查 OpenClaw
echo "📦 检查 OpenClaw..."
command -v openclaw &>/dev/null || { echo "❌ 未找到 OpenClaw"; exit 1; }
echo "✅ OpenClaw 已安装"

# 2. 检查配置文件
[ ! -f "$OPENCLAW_CONFIG" ] && { echo "❌ 配置文件不存在"; exit 1; }

# 3. 配置 Hook
if [ "$SKIP_CONFIG" = false ]; then
  echo "⚙️  配置 Hook..."
  if grep -q "rocky-know-how" "$OPENCLAW_CONFIG" 2>/dev/null; then
    [ "$FORCE" = false ] && echo "✅ Hook 已配置" || echo "⚠️  使用 --force 重新配置"
  else
    # 使用 python3 安全修改 JSON，通过命令行参数传路径（避免 heredoc 变量注入）
    HOOK_PATH="$SKILL_DIR/hooks"
    python3 - "$OPENCLAW_CONFIG" "$HOOK_PATH" << 'PYEOF'
import json, sys
try:
    cfg = sys.argv[1]
    hook_path = sys.argv[2]
    with open(cfg) as f:
        d = json.load(f)
    hooks = d.get("hooks", {}).get("internal", {}).get("load", {})
    dirs = hooks.get("extraDirs", [])
    if hook_path not in dirs:
        dirs.append(hook_path)
        hooks["extraDirs"] = dirs
        d["hooks"]["internal"]["load"] = hooks
        with open(cfg, "w") as f:
            json.dump(d, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print("✅ 已添加 Hook 目录到 extraDirs")
    else:
        print("✅ Hook 已配置")
except Exception as e:
    print(f"⚠️  配置失败: {e}")
    hook_path = sys.argv[2] if len(sys.argv) > 2 else "SKILL_DIR/hooks"
    print(f"请手动在 openclaw.json 的 hooks.internal.load.extraDirs 中添加: {hook_path}")
    sys.exit(1)
PYEOF
  fi
fi

# 4. 创建共享 .learnings 目录
echo ""
echo "📂 创建共享经验诀窍目录..."
SHARED_DIR="$HOME/.openclaw/.learnings"
mkdir -p "$SHARED_DIR/archive"
if [ ! -f "$SHARED_DIR/experiences.md" ]; then
  printf "# 经验诀窍\n\n---\n" > "$SHARED_DIR/experiences.md"
  echo "✅ 已初始化 $SHARED_DIR/experiences.md"
else
  echo "✅ 已存在 $SHARED_DIR/experiences.md"
fi

# 5. 重启 Gateway
echo ""
echo "🔄 重启 Gateway..."
if openclaw gateway restart 2>/dev/null; then
  echo "✅ Gateway 已重启"
else
  echo "⚠️  请手动重启: openclaw gateway restart"
fi

# 6. 验证
echo ""
echo "🔍 验证安装..."
sleep 2
if openclaw hooks list 2>/dev/null | grep -q "rocky-know-how"; then
  echo "✅ Hook 加载成功！"
else
  echo "⚠️  Hook 未显示，请检查配置"
fi

echo ""
echo "🎉 安装完成！"
echo "  搜索: bash $SKILL_DIR/scripts/search.sh \"关键词\""
echo "  写入: bash $SKILL_DIR/scripts/record.sh ..."
echo "  统计: bash $SKILL_DIR/scripts/stats.sh"
