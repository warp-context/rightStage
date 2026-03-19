#!/usr/bin/env bash
# ai_progress.sh — 从 git commit 自动推导 progress.md 任务状态
#
# 用法：
#   ai_progress.sh [project_dir]
#
# progress.md 格式（每行一个任务）：
#   [1] 任务名称  done|doing|todo
#
# 推导规则：
#   1. commit message 包含 [编号] 或任务名 → done
#   2. 第一个未完成任务 → doing
#   3. 其余 → todo
#
# 支持：macOS / Linux / Windows (Git Bash)

set -euo pipefail

# ── 颜色输出（不支持颜色时降级）────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput &>/dev/null && tput colors &>/dev/null; then
  RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6); RESET=$(tput sgr0)
else
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

info()  { echo "${CYAN}ℹ${RESET}  $*"; }
ok()    { echo "${GREEN}✅${RESET} $*"; }
warn()  { echo "${YELLOW}⚠️${RESET}  $*"; }
error() { echo "${RED}❌${RESET} $*" >&2; }

# ── 参数 ────────────────────────────────────────────────────────────────────
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  error "目录不存在：$1"; exit 1
}

PROGRESS_FILE="$PROJECT_DIR/.ai/progress.md"
CTX_DIR="$PROJECT_DIR/.ai/ctx"

# ── 检查 progress.md ────────────────────────────────────────────────────────
if [[ ! -f "$PROGRESS_FILE" ]]; then
  error "未找到 $PROGRESS_FILE"
  echo ""
  echo "  请在项目根目录创建 .ai/progress.md，格式示例："
  echo ""
  echo "    [1] 登录UI     todo"
  echo "    [2] API接入    todo"
  echo "    [3] 错误处理   todo"
  echo ""
  exit 1
fi

# ── 跨平台 sed -i ────────────────────────────────────────────────────────────
_sed_inplace() {
  if sed --version &>/dev/null 2>&1; then
    # GNU sed (Linux)
    sed -i "$@"
  else
    # BSD sed (macOS)
    sed -i '' "$@"
  fi
}

# ── 从 git 推导状态 ──────────────────────────────────────────────────────────
if ! git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
  warn "当前目录无 git，跳过自动推导，使用现有 progress.md"
else
  GIT_LOG=$(git -C "$PROJECT_DIR" log --oneline 2>/dev/null || true)

  if [[ -z "$GIT_LOG" ]]; then
    warn "git 历史为空，跳过推导"
  else
    TMPFILE=$(mktemp)
    FIRST_TODO_FOUND=false

    while IFS= read -r line; do
      # 匹配任务行（容忍多余空格）
      if [[ "$line" =~ ^\[([0-9]+)\][[:space:]]+(.+)[[:space:]]+(done|doing|todo)[[:space:]]*$ ]]; then
        NUM="${BASH_REMATCH[1]}"
        TASK="${BASH_REMATCH[2]}"
        # 去除任务名尾部空格
        TASK="${TASK%"${TASK##*[![:space:]]}"}"
        STATUS="${BASH_REMATCH[3]}"

        if [[ "$STATUS" == "done" ]]; then
          printf "[%s] %s  done\n" "$NUM" "$TASK" >> "$TMPFILE"
          continue
        fi

        # git log 中匹配 [编号] 或任务名（大小写不敏感）
        if echo "$GIT_LOG" | grep -qiE "\[$NUM\]|$(echo "$TASK" | sed 's/[^^]/[&]/g; s/\^/\\^/g')"; then
          printf "[%s] %s  done\n" "$NUM" "$TASK" >> "$TMPFILE"
        elif [[ "$FIRST_TODO_FOUND" == false ]]; then
          printf "[%s] %s  doing\n" "$NUM" "$TASK" >> "$TMPFILE"
          FIRST_TODO_FOUND=true
        else
          printf "[%s] %s  todo\n" "$NUM" "$TASK" >> "$TMPFILE"
        fi
      else
        # 注释行、空行、标题行原样保留
        echo "$line" >> "$TMPFILE"
      fi
    done < "$PROGRESS_FILE"

    mv "$TMPFILE" "$PROGRESS_FILE"
    ok "progress.md 已根据 git 历史更新"
  fi
fi

# ── 生成 current / next ──────────────────────────────────────────────────────
mkdir -p "$CTX_DIR"

CURRENT=$(grep -E "^\[[0-9]+\].*doing" "$PROGRESS_FILE" 2>/dev/null | head -n 1 || true)
NEXT=$(grep -E "^\[[0-9]+\].*todo" "$PROGRESS_FILE" 2>/dev/null | head -n 1 || true)

if [[ -n "$CURRENT" ]]; then
  printf "# Current\n%s\n" "$CURRENT" > "$CTX_DIR/02_current.md"
else
  printf "# Current\n（无进行中任务）\n" > "$CTX_DIR/02_current.md"
fi

if [[ -n "$NEXT" ]]; then
  printf "# Next\n%s\n" "$NEXT" > "$CTX_DIR/03_next.md"
else
  printf "# Next\n（所有任务已完成 🎉）\n" > "$CTX_DIR/03_next.md"
fi

echo ""
info "Project: $PROJECT_DIR"
echo "  📍 Current: ${CURRENT:-（无）}"
echo "  👉 Next:    ${NEXT:-（无）}"
