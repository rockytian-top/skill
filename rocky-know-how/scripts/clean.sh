#!/bin/bash
# rocky-know-how 清理工具 v2.0.0
# 用法: clean.sh [--test] [--old] [--reindex]

get_state_dir() { [ -n "$OPENCLAW_STATE_DIR" ] && echo "$OPENCLAW_STATE_DIR" || echo "$HOME/.openclaw"; }
STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"
CORRECTIONS_FILE="$SHARED_DIR/corrections.md"
DOMAINS_DIR="$SHARED_DIR/domains"
PROJECTS_DIR="$SHARED_DIR/projects"

[ ! -f "$ERRORS_FILE" ] && echo "文件不存在" && exit 0

MODE="${1:-info}"

case "$MODE" in
  --test*)
    CLEAN_DRY_RUN=false
    if [ "$1" = "--test-dry-run" ]; then
      CLEAN_DRY_RUN=true
    fi
    echo "=== 清理测试条目 $( $CLEAN_DRY_RUN && echo '(模拟)' ) ==="
    TEMP_FILE="/tmp/rocky-know-how-clean-$$.md"
    TEST_IDS_FILE="/tmp/rocky-know-how-test-ids-$$.txt"
    removed=0
    current_block=""
    is_test=false
    test_ids=""

    {
      echo "# 经验诀窍"
      echo ""
      echo "---"
    } > "$TEMP_FILE"

    while IFS= read -r line; do
      if echo "$line" | grep -q '^## \[EXP-'; then
        if [ -n "$current_block" ] && [ "$is_test" = false ]; then
          echo "$current_block" >> "$TEMP_FILE"
        fi
        if [ "$is_test" = true ]; then
          entry_id=$(echo "$current_block" | grep "^## \[EXP-" | sed 1q)
          $CLEAN_DRY_RUN && echo "  将删除: $entry_id"
          echo "$entry_id" >> "$TEST_IDS_FILE"
          removed=$((removed+1))
        fi
        current_block="$line"
        is_test=false
      elif echo "$line" | grep -q '^\*\*Tags'; then
        # 精确匹配 tag 列表中完全是 "test" 的条目（排除 retest、final-test 等）
        tags_val=$(echo "$line" | sed 's/^\*\*Tags[:*]* *: *//')
        if echo ",${tags_val}," | tr ',' '\n' | grep -qx 'test' 2>/dev/null; then
          is_test=true
        fi
        current_block="$current_block"$'\n'"$line"
      else
        current_block="$current_block"$'\n'"$line"
      fi
    done < "$ERRORS_FILE"

    if [ -n "$current_block" ] && [ "$is_test" = false ]; then
      echo "$current_block" >> "$TEMP_FILE"
    elif [ "$is_test" = true ]; then
      entry_id=$(echo "$current_block" | grep "^## \[EXP-" | sed 1q)
      $CLEAN_DRY_RUN && echo "  将删除: $entry_id"
      echo "$entry_id" >> "$TEST_IDS_FILE"
      removed=$((removed+1))
    fi

    if $CLEAN_DRY_RUN; then
      echo "模拟完成: 将清理 $removed 条测试条目"
      rm -f "$TEMP_FILE" "$TEST_IDS_FILE"
    else
      if [ "$removed" -eq 0 ]; then
        echo "没有找到 tag 为 'test' 的条目，无需清理。"
        rm -f "$TEMP_FILE" "$TEST_IDS_FILE"
      else
        echo ""
        echo "以下 $removed 条测试条目将被删除："
        cat "$TEST_IDS_FILE" | sed 's/^/  /'
        echo ""
        read -p "确认删除？(y/n) " -r reply; echo
        if [[ ! $reply =~ ^[Yy]$ ]]; then
          echo "已取消。"
          rm -f "$TEMP_FILE" "$TEST_IDS_FILE"
          exit 0
        fi
        mv "$TEMP_FILE" "$ERRORS_FILE"

        # 清理 corrections.md / domains/ / projects/ 中的孤立 EXP 引用
        echo ""
        echo "--- 清理 corrections.md / domains/ / projects/ 中的孤立引用 ---"
        cleaned_refs=0

        # 从 corrections.md 中删除引用了已删 EXP ID 的行
        if [ -f "$CORRECTIONS_FILE" ]; then
          if [ -s "$TEST_IDS_FILE" ]; then
            # 提取 EXP ID 模式 (e.g. EXP-20250101-001)
            grep -h -oE 'EXP-[0-9]{8}-[0-9]+' "$TEST_IDS_FILE" 2>/dev/null | sort -u | while read -r expid; do
              # 删除包含此 EXP ID 的行
              if grep -q "$expid" "$CORRECTIONS_FILE" 2>/dev/null; then
                grep -v "$expid" "$CORRECTIONS_FILE" > "$CORRECTIONS_FILE.tmp" && mv "$CORRECTIONS_FILE.tmp" "$CORRECTIONS_FILE"
                echo "  清理: corrections.md 中引用 $expid 的行"
                cleaned_refs=$((cleaned_refs+1))
              fi
            done
          fi
        fi

        # 从 domains/ 和 projects/ 中删除引用了已删 EXP ID 的行
        for dir in "$DOMAINS_DIR" "$PROJECTS_DIR"; do
          [ -d "$dir" ] || continue
          find "$dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort | while read -r f; do
            if [ -s "$TEST_IDS_FILE" ]; then
              grep -h -oE 'EXP-[0-9]{8}-[0-9]+' "$TEST_IDS_FILE" 2>/dev/null | sort -u | while read -r expid; do
                if grep -q "$expid" "$f" 2>/dev/null; then
                  grep -v "$expid" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
                  echo "  清理: $(basename "$f") 中引用 $expid 的行"
                  cleaned_refs=$((cleaned_refs+1))
                fi
              done
            fi
          done
        done

        [ "$cleaned_refs" -eq 0 ] && echo "  (无孤立引用需清理)"
        echo "✅ 已清理 $removed 条测试条目$( [ "$cleaned_refs" -gt 0 ] && echo "及 $cleaned_refs 处孤立引用" || true)"
        rm -f "$TEST_IDS_FILE"
      fi
    fi
    ;;

  --reindex)
    echo "=== 重新编号 v2.0.0 ==="
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
      # 跳过旧文件头和分隔符
      echo "$line" | grep -qE '^(# 经验诀窍|---+|# Domain|# Project|# 纠正|# 热门|# HOT|# 记忆|Inherits:)' && continue
      if echo "$line" | grep -q '^## \[EXP-'; then
        if [ -n "$current_block" ]; then
          echo "$current_block" >> "$TEMP_FILE"
        fi
        seq=$((seq+1))
        orig_date=$(echo "$line" | sed 's/.*\[EXP-\([0-9]\{8\}\)-.*/\1/')
        title=$(echo "$line" | sed 's/^## \[EXP-[0-9]*-[0-9]*\] //')
        current_block="## [EXP-${orig_date}-$(printf '%03d' $seq)] ${title}"
      else
        current_block="$current_block"$'\n'"$line"
      fi
    done < "$ERRORS_FILE"

    if [ -n "$current_block" ]; then
      echo "$current_block" >> "$TEMP_FILE"
    fi

    mv "$TEMP_FILE" "$ERRORS_FILE"
    echo "✅ 已重新编号为 EXP-${TODAY}-001 ~ EXP-${TODAY}-$(printf '%03d' $seq)"
    ;;

  --old)
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
      if [ -f "$d/ERRORS.md" ] && [ ! -f "$d/experiences.md" ]; then
        mv "$d/ERRORS.md" "$d/experiences.md"
        echo "  重命名: $d/ERRORS.md → experiences.md"
      fi
    done
    echo "✅ 清理了 $cleaned 个旧文件"
    ;;

  --v2-init)
    echo "=== 初始化 v2.0 分层结构 ==="
    mkdir -p "$SHARED_DIR/domains" "$SHARED_DIR/projects" "$SHARED_DIR/archive"
    [ ! -f "$SHARED_DIR/memory.md" ] && printf "# HOT Memory\n\n## 已确认偏好\n\n## 活跃模式\n\n## 最近（最近7天）\n\n" > "$SHARED_DIR/memory.md" && echo "  ✅ memory.md"
    [ ! -f "$SHARED_DIR/corrections.md" ] && printf "# 纠正日志\n\n" > "$SHARED_DIR/corrections.md" && echo "  ✅ corrections.md"
    [ ! -f "$SHARED_DIR/index.md" ] && printf "# 记忆索引\n\n## HOT\n- memory.md: 0 行\n\n## WARM\n- (尚无)\n\n## COLD\n- (尚无)\n\nLast compaction: never\n" > "$SHARED_DIR/index.md" && echo "  ✅ index.md"
    echo "✅ v2.0 分层结构已初始化"
    ;;

  *)
    echo "用法: clean.sh [--test|--test-dry-run|--old|--reindex|--v2-init]"
    echo "  --test           清理 Tags 为 test 的条目（含确认提示）"
    echo "  --test-dry-run   模拟清理测试条目"
    echo "  --old            清理旧版残留文件（LEARNINGS.md等）"
    echo "  --reindex        重新编号让ID连续"
    echo "  --v2-init        初始化 v2.0 分层目录结构"
    ;;
esac
