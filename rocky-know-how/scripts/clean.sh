#!/bin/bash
# rocky-know-how 清理工具
# 用法: clean.sh [--test] [--old] [--reindex]

SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

[ ! -f "$ERRORS_FILE" ] && echo "文件不存在" && exit 0

MODE="${1:-info}"

case "$MODE" in
  --test*)
    # 解析是否带 dry-run
    CLEAN_DRY_RUN=false
    if [ "$1" = "--test-dry-run" ]; then
      CLEAN_DRY_RUN=true
    fi
    # 清理测试条目（Tags 包含 test）
    echo "=== 清理测试条目 $( $CLEAN_DRY_RUN && echo '(模拟)' ) ==="
    TEMP_FILE="/tmp/rocky-know-how-clean-$$.md"
    removed=0
    current_block=""
    is_test=false

    {
      echo "# 经验诀窍"
      echo ""
      echo "---"
    } > "$TEMP_FILE"

    while IFS= read -r line; do
      if echo "$line" | grep -q '^## \[EXP-'; then
        # 输出上一个块
        if [ -n "$current_block" ] && [ "$is_test" = false ]; then
          echo "$current_block" >> "$TEMP_FILE"
        fi
        if [ "$is_test" = true ]; then
          $CLEAN_DRY_RUN && echo "  将删除: $(echo "$current_block" | head -1)"
          removed=$((removed+1))
        fi
        current_block="$line"
        is_test=false
      elif echo "$line" | grep -q '^\*\*Tags\*\*:'; then
        if echo "$line" | grep -qi 'test'; then
          is_test=true
        fi
        current_block="$current_block"$'\n'"$line"
      else
        current_block="$current_block"$'\n'"$line"
      fi
    done < "$ERRORS_FILE"

    # 最后一个块
    if [ -n "$current_block" ] && [ "$is_test" = false ]; then
      echo "$current_block" >> "$TEMP_FILE"
    elif [ "$is_test" = true ]; then
      $CLEAN_DRY_RUN && echo "  将删除: $(echo "$current_block" | head -1)"
      removed=$((removed+1))
    fi

    if $CLEAN_DRY_RUN; then
      echo "模拟完成: 将清理 $removed 条测试条目"
      rm -f "$TEMP_FILE"
    else
      mv "$TEMP_FILE" "$ERRORS_FILE"
      echo "✅ 已清理 $removed 条测试条目"
    fi
    ;;

  --reindex)
    # 重新编号（让ID连续）
    echo "=== 重新编号 ==="
    TEMP_FILE="/tmp/rocky-know-how-reindex-$$.md"
    TODAY=$(date +%Y%m%d)
    seq=0

    {
      echo "# 经验诀窍"
      echo ""
      echo "---"
    } > "$TEMP_FILE"

    current_block=""
    while IFS= read -r line; do
      if echo "$line" | grep -q '^## \[EXP-'; then
        # 输出上一个块
        if [ -n "$current_block" ]; then
          echo "$current_block" >> "$TEMP_FILE"
        fi
        seq=$((seq+1))
        new_id="EXP-${TODAY}-$(printf '%03d' $seq)"
        # 提取标题
        title=$(echo "$line" | sed 's/^## \[EXP-[0-9]*-[0-9]*\] //')
        current_block="## [${new_id}] ${title}"
      else
        current_block="$current_block"$'\n'"$line"
      fi
    done < "$ERRORS_FILE"

    # 最后一个块
    if [ -n "$current_block" ]; then
      echo "$current_block" >> "$TEMP_FILE"
    fi

    mv "$TEMP_FILE" "$ERRORS_FILE"
    echo "✅ 已重新编号为 EXP-${TODAY}-001 ~ EXP-${TODAY}-$(printf '%03d' $seq)"
    ;;

  --old)
    # 清理旧版残留文件
    echo "=== 清理旧版残留 ==="
    cleaned=0
    for d in "$HOME"/.openclaw/workspace-*/.learnings; do
      [ ! -d "$d" ] && continue
      for f in LEARNINGS.md FEATURE_REQUESTS.md; do
        if [ -f "$d/$f" ]; then
          rm "$d/$f"
          echo "  删除: $d/$f"
          cleaned=$((cleaned+1))
        fi
      done
      # 重命名 ERRORS.md → experiences.md
      if [ -f "$d/ERRORS.md" ] && [ ! -f "$d/experiences.md" ]; then
        mv "$d/ERRORS.md" "$d/experiences.md"
        echo "  重命名: $d/ERRORS.md → experiences.md"
      fi
    done
    echo "✅ 清理了 $cleaned 个旧文件"
    ;;

  *)
    echo "用法: clean.sh [--test|--test-dry-run|--old|--reindex]"
    echo "  --test           清理 Tags 包含 test 的条目"
    echo "  --test-dry-run   模拟清理测试条目"
    echo "  --old            清理旧版残留文件（LEARNINGS.md等）"
    echo "  --reindex        重新编号让ID连续"
    ;;
esac
