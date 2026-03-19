#!/usr/bin/env bash
# ai_done.sh — 将当前 doing 任务标记为 done，下一个 todo 变 doing
#
# 用法：
#   ai_done.sh [project_dir]
#
# 等价于手动把 progress.md 里 doing → done，但更快

set -euo pipefail

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "目录不存在：$1" >&2; exit 1
}

PROGRESS_FILE="$PROJECT_DIR/.ai/progress.md"

if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "❌ 未找到 $PROGRESS_FILE" >&2; exit 1
fi

# 找到当前 doing 行
DOING_LINE=$(grep -nE "^\[[0-9]+\].*doing" "$PROGRESS_FILE" | head -n 1 || true)

if [[ -z "$DOING_LINE" ]]; then
  echo "⚠️  没有进行中的任务（doing）"
  exit 0
fi

DOING_NUM=$(echo "$DOING_LINE" | cut -d: -f1)
DOING_TASK=$(echo "$DOING_LINE" | sed 's/^[0-9]*://' | sed 's/doing$//' | xargs)
echo "✅ 完成：$DOING_TASK"

# doing → done
if sed --version &>/dev/null 2>&1; then
  sed -i "${DOING_NUM}s/doing/done/" "$PROGRESS_FILE"
else
  sed -i '' "${DOING_NUM}s/doing/done/" "$PROGRESS_FILE"
fi

# 找下一个 todo，改为 doing
TODO_LINE=$(grep -nE "^\[[0-9]+\].*todo" "$PROGRESS_FILE" | head -n 1 || true)

if [[ -n "$TODO_LINE" ]]; then
  TODO_NUM=$(echo "$TODO_LINE" | cut -d: -f1)
  TODO_TASK=$(echo "$TODO_LINE" | sed 's/^[0-9]*://' | sed 's/todo$//' | xargs)
  if sed --version &>/dev/null 2>&1; then
    sed -i "${TODO_NUM}s/todo/doing/" "$PROGRESS_FILE"
  else
    sed -i '' "${TODO_NUM}s/todo/doing/" "$PROGRESS_FILE"
  fi
  echo "👉 开始：$TODO_TASK"
else
  echo "🎉 所有任务已完成！"
fi

# 重新生成 current / next
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_prog="${SCRIPT_DIR}/ai_progress.sh"
[[ -f "$_prog" ]] || _prog="${SCRIPT_DIR}/ai_progress"
bash "$_prog" "$PROJECT_DIR" 2>/dev/null || true
