#!/usr/bin/env bash
# =============================================================================
# Distilled Minds — Uninstall Script
# Remove all installed persona skills from Claude Code, Copilot CLI, or Gemini CLI
# Requires: bash 3.2+ (macOS default), standard Unix tools
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONAS_DIR="$REPO_DIR/personas"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

print_header() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║       🧠  Distilled Minds · Uninstaller          ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo ""
}

print_step() { echo -e "\n${CYAN}▶ $1${RESET}"; }
print_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
print_err()  { echo -e "  ${RED}✗${RESET} $1"; }

# ── Read available personas from the repo ────────────────────────────────────
get_personas() {
  for dir in "$PERSONAS_DIR"/*/; do
    local name
    name=$(basename "$dir")
    if [[ -f "$dir/SKILL.md" ]]; then
      echo "$name"
    fi
  done
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  print_header
  echo -e "  ${DIM}Remove all Distilled Minds personas from a platform.${RESET}"
  echo -e "  ${DIM}Only removes what was installed by install.sh — no other files touched.${RESET}"

  print_step "Select platform to uninstall from:"
  echo ""
  echo -e "  ${BOLD}[1]${RESET} Claude Code        ${DIM}(~/.claude/skills/)${RESET}"
  echo -e "  ${BOLD}[2]${RESET} GitHub Copilot CLI  ${DIM}(~/.copilot/skills/)${RESET}"
  echo -e "  ${BOLD}[3]${RESET} Gemini CLI          ${DIM}(~/.gemini/personas/ + GEMINI.md @imports)${RESET}"
  echo -e "  ${BOLD}[4]${RESET} All platforms"
  echo ""

  read -rp "$(echo -e "${YELLOW}Select platform [1-4]: ${RESET}")" platform_choice

  local platforms_to_remove=()
  case "$platform_choice" in
    1) platforms_to_remove=("claude") ;;
    2) platforms_to_remove=("copilot") ;;
    3) platforms_to_remove=("gemini") ;;
    4) platforms_to_remove=("claude" "copilot" "gemini") ;;
    *) print_err "Invalid choice."; exit 1 ;;
  esac

  # Load all persona slugs from the repo
  local personas=()
  while IFS= read -r line; do
    personas+=("$line")
  done < <(get_personas)

  echo ""
  print_step "Removing installed personas..."

  local p dir pfile gemini_md import_line remaining
  for platform in "${platforms_to_remove[@]}"; do
    echo ""
    case "$platform" in
      claude)
        echo -e "  ${CYAN}Claude Code:${RESET}"
        local removed=0
        for p in "${personas[@]}"; do
          dir="$HOME/.claude/skills/$p"
          if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_ok "Removed: $dir"
            ((removed++)) || true
          fi
        done
        [[ "$removed" -eq 0 ]] && print_warn "Nothing found to remove"
        ;;
      copilot)
        echo -e "  ${CYAN}GitHub Copilot CLI:${RESET}"
        local removed=0
        for p in "${personas[@]}"; do
          dir="$HOME/.copilot/skills/$p"
          if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_ok "Removed: $dir"
            ((removed++)) || true
          fi
        done
        [[ "$removed" -eq 0 ]] && print_warn "Nothing found to remove"
        ;;
      gemini)
        echo -e "  ${CYAN}Gemini CLI:${RESET}"
        gemini_md="$HOME/.gemini/GEMINI.md"
        local removed=0
        for p in "${personas[@]}"; do
          pfile="$HOME/.gemini/personas/$p.md"
          if [[ -f "$pfile" ]]; then
            rm -f "$pfile"
            print_ok "Removed persona file: $pfile"
            ((removed++)) || true
          fi
          # Remove @import line from GEMINI.md
          if [[ -f "$gemini_md" ]]; then
            import_line="@./personas/$p.md"
            if grep -qF "$import_line" "$gemini_md"; then
              sed -i '' -e "\|$import_line|d" "$gemini_md"
            fi
          fi
        done
        # Clean up empty personas dir
        if [[ -d "$HOME/.gemini/personas" ]]; then
          rmdir "$HOME/.gemini/personas" 2>/dev/null || true
        fi
        # Remove GEMINI.md if we created it and it's now empty
        if [[ -f "$gemini_md" ]]; then
          remaining=$(grep -c '^@\.' "$gemini_md" 2>/dev/null || echo "0")
          if [[ "$remaining" -eq 0 ]] && grep -q "Distilled Minds" "$gemini_md" 2>/dev/null; then
            rm -f "$gemini_md"
            print_ok "Removed GEMINI.md (was only Distilled Minds content)"
          else
            print_ok "Cleaned @import lines from GEMINI.md (user content preserved)"
          fi
        fi
        [[ "$removed" -eq 0 ]] && print_warn "Nothing found to remove"
        ;;
    esac
  done

  echo ""
  echo -e "${GREEN}${BOLD}✓ Uninstall complete!${RESET}"
  echo ""
}

main "$@"
