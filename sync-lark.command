#!/bin/bash

# ─── CONFIG ───────────────────────────────────────────────────────────────────
# This script assumes it lives in the same folder as sync.js
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync.js"
LOG_FILE="$SCRIPT_DIR/sync.log"

# ─── COLORS ──────────────────────────────────────────────────────────────────
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
DIM="\033[2m"
RESET="\033[0m"

clear

echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║      ProjectOps — Lark Sync        ║${RESET}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════╝${RESET}"
echo ""
echo -e "${DIM}  Project folder: $SCRIPT_DIR${RESET}"
echo ""

# ─── CHECK NODE ───────────────────────────────────────────────────────────────
if ! command -v node &> /dev/null; then
  echo -e "${RED}  ✕ Node.js not found.${RESET}"
  echo ""
  echo -e "  Install it from: ${CYAN}https://nodejs.org${RESET}"
  echo ""
  read -p "  Press Enter to close..."
  exit 1
fi

NODE_VER=$(node --version)
echo -e "${DIM}  Node.js $NODE_VER${RESET}"

# ─── CHECK SYNC SCRIPT ────────────────────────────────────────────────────────
if [ ! -f "$SYNC_SCRIPT" ]; then
  echo ""
  echo -e "${RED}  ✕ sync.js not found at:${RESET}"
  echo -e "    $SYNC_SCRIPT"
  echo ""
  echo -e "  Make sure this script is in the same folder as sync.js"
  echo ""
  read -p "  Press Enter to close..."
  exit 1
fi

# ─── CHECK .ENV ───────────────────────────────────────────────────────────────
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo ""
  echo -e "${YELLOW}  ⚠  .env file not found${RESET}"
  echo -e "${DIM}     Expected at: $SCRIPT_DIR/.env${RESET}"
  echo ""
  echo -e "  Create a .env file with:"
  echo -e "${DIM}  LARK_APP_ID=your_app_id"
  echo -e "  LARK_APP_SECRET=your_app_secret"
  echo -e "  LARK_APP_TOKEN=your_app_token"
  echo -e "  LARK_TABLE_ID=your_table_id${RESET}"
  echo ""
  read -p "  Press Enter to close..."
  exit 1
fi

# ─── CHECK NODE MODULES ───────────────────────────────────────────────────────
if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
  echo ""
  echo -e "${YELLOW}  ⚠  node_modules not found — installing dependencies...${RESET}"
  echo ""
  cd "$SCRIPT_DIR"
  npm install axios dotenv --save 2>&1
  echo ""
fi

# ─── RUN SYNC ────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  ⟳  Running sync...${RESET}"
echo -e "${DIM}  $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo ""
echo -e "${DIM}────────────────────────────────────────${RESET}"
echo ""

cd "$SCRIPT_DIR"
node sync.js 2>&1 | tee -a "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo -e "${DIM}────────────────────────────────────────${RESET}"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  ✓ Sync complete!${RESET}"
  echo -e "${DIM}  Log saved to: sync.log${RESET}"
  # Mac notification
  osascript -e 'display notification "projects.json updated successfully" with title "ProjectOps Sync" subtitle "✓ Done"' 2>/dev/null
else
  echo -e "${RED}${BOLD}  ✕ Sync failed — check output above${RESET}"
  echo -e "${DIM}  Log saved to: sync.log${RESET}"
  osascript -e 'display notification "Sync failed — check sync.log" with title "ProjectOps Sync" subtitle "✕ Error"' 2>/dev/null
fi

echo ""
read -p "  Press Enter to close..."
