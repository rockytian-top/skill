#!/bin/bash
# build_bm25.sh - 编译BM25核心（跨平台）
# 用法: ./build_bm25.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/_bm25.c"
OUT="$SCRIPT_DIR/_bm25"

# 检测系统
OS="$(uname -s)"
CC=""
CFLAGS="-O3 -lm"

case "$OS" in
    Darwin*)
        echo "检测到 macOS"
        CC="gcc"
        ;;
    Linux*)
        echo "检测到 Linux"
        CC="gcc"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "检测到 Windows (Git Bash/MSYS)"
        OUT="$SCRIPT_DIR/_bm25.exe"
        CC="gcc"
        ;;
    *)
        echo "未知系统: $OS"
        echo "尝试使用 gcc..."
        CC="${CC:-gcc}"
        ;;
esac

# 检查编译器
if ! command -v $CC &> /dev/null; then
    echo "错误: 未找到 $CC 编译器"
    echo "安装方法:"
    echo "  macOS: brew install gcc"
    echo "  Linux: sudo apt install build-essential 或 sudo yum groupinstall Development Tools"
    echo "  Windows: 安装 MinGW 或使用 WSL"
    exit 1
fi

echo "编译BM25核心..."
$CC $CFLAGS -o "$OUT" "$SRC" 2>&1 | grep -v "warning" || true

if [ -f "$OUT" ]; then
    echo "编译成功: $OUT"
    # 设置执行权限
    chmod +x "$OUT"
else
    echo "编译失败"
    exit 1
fi
