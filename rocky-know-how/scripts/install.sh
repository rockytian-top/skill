#!/bin/bash
# rocky-know-how 安装脚本 v2.7.0
# 用法: bash install.sh [--with-hook]
#   --with-hook   自动配置 Hook 到 openclaw.json（需手动重启 gateway）
# 本脚本创建目录和初始化文件。可选配置 Hook（需显式 --with-hook）。

set -e

VERSION="2.6.0"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 解析参数
WITH_HOOK=false
for arg in "$@"; do
  case "$arg" in
    --with-hook) WITH_HOOK=true ;;
    --help|-h)
      echo "用法: bash install.sh [--with-hook]"
      echo "  --with-hook   自动配置 Hook 到 openclaw.json"
      exit 0
      ;;
  esac
done

echo "╔════════════════════════════════════════════╗"
echo "║  rocky-know-how 安装脚本 v${VERSION}        ║"
echo "║  经验诀窍技能 - 完全对齐 self-improving    ║"
echo "╚════════════════════════════════════════════╝"
echo ""

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"
STATE_DIR=$(get_state_dir)
SHARED_DIR=$(get_shared_dir)

echo "📂 创建共享经验诀窍目录..."
mkdir -p "$SHARED_DIR"
mkdir -p "$SHARED_DIR/domains"
mkdir -p "$SHARED_DIR/projects"
mkdir -p "$SHARED_DIR/archive"
echo "✅ 已创建 $SHARED_DIR/"
echo "   ├── domains/"
echo "   ├── projects/"
echo "   └── archive/"
echo ""

# 初始化 v2 layered 存储
echo "📄 初始化 v2 分层存储文件..."

init_file() {
  local file="$1"
  local content="$2"
  if [ ! -f "$file" ]; then
    printf "%s" "$content" > "$file"
    echo "   ✅ $file"
  else
    echo "   ⏭️  已存在: $(basename "$file")"
  fi
}

init_file "$SHARED_DIR/memory.md" "# HOT Memory

## 已确认偏好

## 活跃模式

## 最近（最近7天）

"

init_file "$SHARED_DIR/index.md" "# 记忆索引

## HOT
- memory.md: 0 行

## WARM
- (尚无命名空间)

## COLD
- (尚无归档)

Last compaction: never
"

init_file "$SHARED_DIR/corrections.md" "# 纠正日志

## $(date '+%Y-%m-%d')

<!-- N5 fix: 使用日期块格式与 compact.sh 期望一致，便于压缩整理 -->
"

init_file "$SHARED_DIR/reflections.md" "# 自我反思日志

## (新条目在此)
"

init_file "$SHARED_DIR/heartbeat-state.md" "# Self-Improving Heartbeat State

last_heartbeat_started_at: never
last_reviewed_change_at: never
last_heartbeat_result: never

## Last actions
- none yet
"

# 初始化 v1 experiences.md（向后兼容）
if [ ! -f "$SHARED_DIR/experiences.md" ]; then
  printf "# 经验诀窍\n\n---\n" > "$SHARED_DIR/experiences.md"
  echo "   ✅ experiences.md (v1 向后兼容)"
else
  echo "   ⏭️  已存在: experiences.md (v1 向后兼容)"
fi

echo ""
echo "✅ v2.7.0 安装完成！"
echo ""
echo "📊 存储结构:"
echo "   $SHARED_DIR/"
echo "   ├── memory.md         (HOT: ≤100行，始终加载)"
echo "   ├── corrections.md    (纠正日志: 最近50条)"
echo "   ├── reflections.md   (自我反思)"
echo "   ├── index.md          (主题索引)"
echo "   ├── heartbeat-state.md"
echo "   ├── domains/          (WARM: 领域隔离)"
echo "   ├── projects/         (WARM: 项目隔离)"
echo "   ├── archive/          (COLD: 归档)"
echo "   └── experiences.md    (v1 向后兼容)"
echo ""

# 可选：配置 Hook
configure_hook() {
  local oc_json="$STATE_DIR/openclaw.json"
  local hook_path="$SKILL_DIR/hooks"

  if [ ! -f "$oc_json" ]; then
    echo ""
    echo "⚠️  未找到 openclaw.json ($oc_json)，跳过 Hook 配置"
    return 1
  fi

  # 用 Python 安全修改 JSON（保留注释和格式）
  python3 << PYEOF
import json, sys, os, shutil

f = '$oc_json'
bak = f + '.bak.install-$'
shutil.copy(f, bak)

try:
    with open(f, 'r') as fp:
        data = json.load(fp)
except Exception as e:
    print(f'⚠️  JSON 解析失败: {e}，跳过 Hook 配置')
    sys.exit(1)

hook_path = '$hook_path'
extra_dirs = data.get('hooks', {}).get('internal', {}).get('load', {}).get('extraDirs', [])

if hook_path in extra_dirs:
    print('')
    print('⏭️  Hook 路径已存在: ' + hook_path)
else:
    if 'hooks' not in data:
        data['hooks'] = {}
    if 'internal' not in data['hooks']:
        data['hooks']['internal'] = {}
    if 'load' not in data['hooks']['internal']:
        data['hooks']['internal']['load'] = {}
    if 'extraDirs' not in data['hooks']['internal']['load']:
        data['hooks']['internal']['load']['extraDirs'] = []
    
    data['hooks']['internal']['load']['extraDirs'].append(hook_path)
    
    with open(f, 'w') as fp:
        json.dump(data, fp, indent=2, ensure_ascii=False)
    
    print('')
    print('✅ Hook 已添加到 openclaw.json:')
    print('   ' + hook_path)
    print('   备份: ' + bak)
PYEOF
  return $?
}

if [ "$WITH_HOOK" = true ]; then
  echo "⚙️  配置 Hook..."
  configure_hook
  echo ""
  echo "⚠️  Hook 已配置，需重启 Gateway 生效："
  echo "   openclaw gateway restart"
else
  echo "⚙️  跳过 Hook 配置（如需自动提醒，运行：bash install.sh --with-hook）"
  echo ""
  echo "   手动配置 Hook："
  echo "   在 openclaw.json 的 hooks.internal.load.extraDirs 中添加："
  echo "   $SKILL_DIR/hooks"
fi

echo ""
echo "🎉 rocky-know-how v2.7.0 安装完成！"
echo ""
echo "  搜索: bash $SKILL_DIR/scripts/search.sh \"关键词\""
echo "  写入: bash $SKILL_DIR/scripts/record.sh ..."
echo "  统计: bash $SKILL_DIR/scripts/stats.sh"
echo "  晋升: bash $SKILL_DIR/scripts/promote.sh"
