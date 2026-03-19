#!/usr/bin/env bash
# install.sh — aiflow installer
#
# Usage:
#   bash install.sh                        # install to ~/.local/bin
#   bash install.sh --prefix /usr/local    # custom install path
#
# Or via curl (no git clone needed):
#   curl -fsSL https://raw.githubusercontent.com/warp-context/rightStage/main/install.sh | bash

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
REPO="warp-context/rightStage"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH/bin"
SCRIPTS=(ai_progress ai_inject ai_done)

# ── Parse args ────────────────────────────────────────────────────────────────
INSTALL_DIR=""
_args=("$@")
for i in "${!_args[@]}"; do
  [[ "${_args[$i]}" == "--prefix" ]] && INSTALL_DIR="${_args[$((i+1))]:-}"
done
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
else
  GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

echo -e "${CYAN}Installing aiflow...${RESET}"

# ── Detect local vs remote ────────────────────────────────────────────────────
_SELF="${BASH_SOURCE[0]:-}"
if [[ -f "$_SELF" ]] && [[ -d "$(dirname "$_SELF")/bin" ]]; then
  LOCAL=true
  REPO_BIN="$(cd "$(dirname "$_SELF")/bin" && pwd)"
else
  LOCAL=false
  if ! command -v curl &>/dev/null; then
    echo "Error: curl is required for remote install." >&2; exit 1
  fi
fi

# ── Create dirs ───────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.ai/ctx"

# ── Install scripts ───────────────────────────────────────────────────────────
for name in "${SCRIPTS[@]}"; do
  target="$INSTALL_DIR/$name"
  if [[ "$LOCAL" == true ]]; then
    cp "$REPO_BIN/${name}.sh" "$target"
  else
    curl -fsSL "$RAW_BASE/${name}.sh" -o "$target"
  fi
  chmod +x "$target"
  echo -e "  ${GREEN}✓${RESET} $target"
done

# ── PATH check ────────────────────────────────────────────────────────────────
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH.${RESET}"
  echo "   Add this to your ~/.zshrc or ~/.bashrc:"
  echo ""
  echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
else
  echo ""
  echo -e "${GREEN}Done!${RESET} Run 'ai_inject .' in any project directory."
fi

echo ""
echo "Quick start:"
echo "  1. Create .ai/progress.md in your project"
echo "  2. Run: ai_inject ."
echo ""
