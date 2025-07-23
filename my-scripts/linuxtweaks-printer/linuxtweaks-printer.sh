#!/usr/bin/env bash
# tolga erok
# 15/5/25
set -euo pipefail

sudo

# CONFIG - Colors for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

printer_name="FAST_HP_LaserJet_600_M601"
printer_ip="192.168.0.7"
printer_URI="ipp://${printer_ip}/ipp/print"
host_entry="$printer_ip   ${printer_name}.local   $printer_name"
log_file="$HOME/linuxtweaks-printer.log"
verbose=false
clear

# default printer options - BETA
printer_options=(
  "-o copies=1"
  "-o print-color-mode=monochrome"
)

usage() {
  cat <<EOF
Usage: $0 {install|remove} [--nogui] [--verbose]

Commands:
  install   Install and configure the printer
  remove    Remove the printer and host entry

Options:
  --nogui   Run in CLI mode only (default)
  --verbose Enable verbose logging and output

If no arguments provided, runs interactive menu.
EOF
}

log() {
  # log with timestamp print and append to log file
  local msg="$1"
  echo -e "$(date '+%F %T') $msg" | tee -a "$log_file"
}

debug() {
  # print debug messages only if verbose enabled  -  BETA
  if $verbose; then
    echo -e "${BLUE}[DEBUG]${NC} $1"
  fi
}

confirm() {
  read -rp "$1 [y/N]: " response
  case "$response" in
  [yY][eE][sS] | [yY]) return 0 ;;
  *) return 1 ;;
  esac
}

check_cups() {
  # is CUPS tools installed??
  if ! command -v lpadmin &>/dev/null; then
    log "${RED}❌ CUPS (lpadmin) not found. Please install 'cups' first.${NC}"
    exit 1
  fi
  debug "CUPS found."
}

remove_printer() {
  log "🧹 Removing printer '$printer_name' if exists..."
  if lpstat -p "$printer_name" &>/dev/null; then
    if confirm "Are you sure you want to remove printer '$printer_name'?"; then
      lpadmin -x "$printer_name"
      log "${GREEN}✅ Printer removed: $printer_name${NC}"
    else
      log "${YELLOW}⚠ Printer removal cancelled.${NC}"
    fi
  else
    log "ℹ️ Printer '$printer_name' not found, nothing to remove."
  fi

  # remove host entry safely - BETA
  if grep -Fq "$printer_name" /etc/hosts; then
    if confirm "Remove host entry for '$printer_name' from /etc/hosts?"; then
      sed -i.bak "/$printer_name/d" /etc/hosts
      log "${GREEN}✅ Host entry removed.${NC}"
    else
      log "${YELLOW}⚠ Host entry removal cancelled.${NC}"
    fi
  else
    log "ℹ️ No host entry found for '$printer_name'."
  fi
}

install_printer() {
  log "🔧 Installing printer: $printer_name ($printer_URI)..."

  if lpstat -p "$printer_name" &>/dev/null; then
    local existing_uri
    existing_uri=$(lpstat -v "$printer_name" | awk '{print $3}')
    debug "Existing printer URI: $existing_uri"
    if [[ "$existing_uri" != "$printer_URI" ]]; then
      log "⚠ Printer exists but URI mismatch, removing..."
      lpadmin -x "$printer_name"
    else
      log "ℹ️ Printer already installed with correct URI."
      return
    fi
  fi

  lpadmin -p "$printer_name" -E -v "$printer_URI" -m everywhere "${printer_options[@]}"

  if lpstat -p "$printer_name" &>/dev/null; then
    lpoptions -d "$printer_name"
    if $verbose; then
      lpstat -p "$printer_name"
    fi
    log "${GREEN}✅ Printer installed and set as default.${NC}"
  else
    log "${RED}❌ Failed to install printer.${NC}"
    exit 1
  fi

  # add host entry if not exists - BETA
  if ! grep -q "$printer_name" /etc/hosts; then
    echo "$host_entry" | sudo tee -a /etc/hosts >/dev/null
    log "${GREEN}✅ Host entry added.${NC}"
  else
    log "ℹ️ Host entry already exists."
  fi

  # send a test page
  log "🧪 Sending test page..."
  local testfile
  testfile=$(mktemp)
  echo "Test page from $(hostname) at $(date)" >"$testfile"
  lp -d "$printer_name" "$testfile"
  rm -f "$testfile"
}

menu() {
  while true; do
    echo
    echo -e "
\033[0;34m╭────────────────────────────────────────────────────────────╮
│          🖨️ LinuxTweaks HP Printer Setup                   │
╰────────────────────────────────────────────────────────────╯\033[0m"
    echo "  === Printer Setup Menu ==="
    echo
    echo "  1) Install printer"
    echo "  2) Remove printer"
    echo "  3) Exit"
    echo
    read -rp "  Select an option [1-3]: " choice
    case "$choice" in
    1) install_printer ;;
    2) remove_printer ;;
    3) exit 0 ;;
    *) echo "Invalid option." ;;
    esac
  done
}

main() {
  if [ $# -eq 0 ]; then
    menu
    exit 0
  fi

  local cmd=""
  while (("$#")); do
    case "$1" in
    install | remove)
      cmd="$1"
      shift
      ;;
    --nogui) shift ;; # no GUI support at the moment - BETA
    --verbose)
      verbose=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
    esac
  done

  check_cups

  case "$cmd" in
  install) install_printer ;;
  remove) remove_printer ;;
  *)
    usage
    exit 1
    ;;
  esac

  log "${YELLOW}\n──── DONE ──────────────────────────────────────────────────────${NC}"
}

main "$@"
