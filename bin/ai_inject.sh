#!/usr/bin/env bash
# ai_inject.sh — 生成注入给 AI 的最小上下文
#
# 用法：
#   ai_inject.sh [options] [project_dir] [用户输入]
#
# 选项：
#   -c, --copy      输出后自动复制到剪贴板
#   -n, --no-update 跳过 ai_progress 自动更新
#   -h, --help      显示帮助
#
# 注入优先级：current > next > goal > constraint > issues > input
# 总输出控制在 ~100 行以内

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 颜色 ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput &>/dev/null && tput colors &>/dev/null; then
  BOLD=$(tput bold); RESET=$(tput sgr0); DIM=$(tput dim 2>/dev/null || echo "")
else
  BOLD=""; RESET=""; DIM=""
fi

# ── 参数解析 ──────────────────────────────────────────────────────────────────
OPT_COPY=false
OPT_NO_UPDATE=false
PROJECT_DIR="."
USER_INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--copy)       OPT_COPY=true; shift ;;
    -n|--no-update)  OPT_NO_UPDATE=true; shift ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "未知选项：$1" >&2; exit 1 ;;
    *)
      # 第一个非选项参数是目录（如果存在），第二个是用户输入
      if [[ -d "$1" ]]; then
        PROJECT_DIR="$1"
      else
        USER_INPUT="$1"
      fi
      shift
      ;;
  esac
done

PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "目录不存在：$PROJECT_DIR" >&2; exit 1
}

CTX_DIR="$PROJECT_DIR/.ai/ctx"
GLOBAL_CTX="$HOME/.ai/ctx"

# ── 自动更新 progress ─────────────────────────────────────────────────────────
if [[ "$OPT_NO_UPDATE" == false ]]; then
  if [[ -f "$PROJECT_DIR/.ai/progress.md" ]]; then
    _prog="${SCRIPT_DIR}/ai_progress.sh"
    [[ -f "$_prog" ]] || _prog="${SCRIPT_DIR}/ai_progress"
    bash "$_prog" "$PROJECT_DIR"
    echo ""
  fi
fi

# ── 工具函数 ──────────────────────────────────────────────────────────────────
# 读取文件，找项目级优先，fallback 到全局
_read_ctx() {
  local name="$1"
  local limit="${2:-999}"
  local file=""
  [[ -f "$CTX_DIR/$name" ]]    && file="$CTX_DIR/$name"
  [[ -z "$file" && -f "$GLOBAL_CTX/$name" ]] && file="$GLOBAL_CTX/$name"
  [[ -n "$file" ]] && head -n "$limit" "$file"
}

# 检查文件是否有实质内容（非空、非注释）
_has_content() {
  local name="$1"
  local file=""
  [[ -f "$CTX_DIR/$name" ]]    && file="$CTX_DIR/$name"
  [[ -z "$file" && -f "$GLOBAL_CTX/$name" ]] && file="$GLOBAL_CTX/$name"
  [[ -n "$file" ]] && grep -qv "^#\|^$\|^<!--\|^>" "$file" 2>/dev/null
}

# ── 构建输出 ──────────────────────────────────────────────────────────────────
OUTPUT=""
_append() { OUTPUT+="$1"$'\n'; }

_append "${BOLD}================================================${RESET}"
_append "${BOLD}🧠 AI CONTEXT — $(date '+%Y-%m-%d %H:%M')${RESET}"
_append "${BOLD}================================================${RESET}"

# [1] CURRENT（必须）
_append ""
_append "${BOLD}[CURRENT]${RESET}"
CURRENT_CONTENT=$(_read_ctx "02_current.md" 5)
if [[ -n "$CURRENT_CONTENT" ]]; then
  _append "$CURRENT_CONTENT"
else
  _append "（无 current，请先运行 ai_progress.sh）"
fi

# [2] NEXT（必须）
NEXT_CONTENT=$(_read_ctx "03_next.md" 5)
if [[ -n "$NEXT_CONTENT" ]]; then
  _append ""
  _append "${BOLD}[NEXT]${RESET}"
  _append "$NEXT_CONTENT"
fi

# [3] GOAL（前15行，有实质内容才显示）
if _has_content "00_goal.md"; then
  _append ""
  _append "${BOLD}[GOAL]${RESET}"
  _append "$(_read_ctx "00_goal.md" 15)"
fi

# [4] API（前10行）
if _has_content "05_api.md"; then
  _append ""
  _append "${BOLD}[API]${RESET}"
  _append "$(_read_ctx "05_api.md" 10)"
fi

# [5] CONSTRAINT（前10行）
if _has_content "04_constraint.md"; then
  _append ""
  _append "${BOLD}[CONSTRAINT]${RESET}"
  _append "$(_read_ctx "04_constraint.md" 10)"
fi

# [6] RECENT ISSUES（最近3条）
ISSUE_FILE=""
[[ -f "$CTX_DIR/07_issue.md" ]]    && ISSUE_FILE="$CTX_DIR/07_issue.md"
[[ -z "$ISSUE_FILE" && -f "$GLOBAL_CTX/07_issue.md" ]] && ISSUE_FILE="$GLOBAL_CTX/07_issue.md"
if [[ -n "$ISSUE_FILE" ]]; then
  RECENT=$(grep -v "^#\|^$\|^<!--" "$ISSUE_FILE" 2>/dev/null | tail -n 3 || true)
  if [[ -n "$RECENT" ]]; then
    _append ""
    _append "${BOLD}[RECENT ISSUES]${RESET}"
    _append "$RECENT"
  fi
fi

# [7] USER INPUT
if [[ -n "$USER_INPUT" ]]; then
  _append ""
  _append "${BOLD}[INPUT]${RESET}"
  _append "$USER_INPUT"
fi

_append ""
_append "${BOLD}================================================${RESET}"

# ── 输出 ─────────────────────────────────────────────────────────────────────
echo "$OUTPUT"

# ── 复制到剪贴板 ──────────────────────────────────────────────────────────────
if [[ "$OPT_COPY" == true ]]; then
  # 去掉 ANSI 颜色码再复制
  CLEAN=$(echo "$OUTPUT" | sed 's/\x1b\[[0-9;]*m//g')
  if command -v pbcopy &>/dev/null; then
    echo "$CLEAN" | pbcopy
    echo "📋 已复制到剪贴板（macOS）"
  elif command -v xclip &>/dev/null; then
    echo "$CLEAN" | xclip -selection clipboard
    echo "📋 已复制到剪贴板（xclip）"
  elif command -v xsel &>/dev/null; then
    echo "$CLEAN" | xsel --clipboard --input
    echo "📋 已复制到剪贴板（xsel）"
  elif command -v clip.exe &>/dev/null; then
    echo "$CLEAN" | clip.exe
    echo "📋 已复制到剪贴板（Windows）"
  else
    echo "⚠️  未找到剪贴板工具（pbcopy/xclip/xsel/clip.exe）" >&2
  fi
fi
