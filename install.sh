#!/usr/bin/env bash
# =============================================================================
# Distilled Minds — Install Script
# Install distilled persona skills into Claude Code, GitHub Copilot, or Gemini
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONAS_DIR="$REPO_DIR/personas"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║       🧠  Distilled Minds · Installer            ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo ""
}

print_step() { echo -e "\n${CYAN}▶ $1${RESET}"; }
print_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
print_err()  { echo -e "  ${RED}✗${RESET} $1"; }

# ── Read available personas ───────────────────────────────────────────────────
get_personas() {
  local result=()
  for dir in "$PERSONAS_DIR"/*/; do
    local name
    name=$(basename "$dir")
    if [[ -f "$dir/SKILL.md" ]]; then
      result+=("$name")
    fi
  done
  printf '%s\n' "${result[@]}"
}

# ── Get display name from SKILL.md ────────────────────────────────────────────
get_display_name() {
  local skill_file="$PERSONAS_DIR/$1/SKILL.md"
  # Try to extract name from YAML front matter
  local name
  name=$(grep -m1 '^name:' "$skill_file" 2>/dev/null | sed 's/name: *//' | tr -d '"' | sed 's/-perspective//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')
  echo "${name:-$1}"
}

# ── Select personas (multi-select) ───────────────────────────────────────────
select_personas() {
  local personas
  mapfile -t personas < <(get_personas)

  if [[ ${#personas[@]} -eq 0 ]]; then
    print_err "No personas found in $PERSONAS_DIR"
    exit 1
  fi

  print_step "Available personas:"
  echo ""
  local i=1
  for persona in "${personas[@]}"; do
    local display
    display=$(get_display_name "$persona")
    # Check if research data is available
    local research_count
    research_count=$(find "$PERSONAS_DIR/$persona/references/research" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$research_count" -gt 0 ]]; then
      echo -e "  ${BOLD}[$i]${RESET} $display ${DIM}($research_count research files)${RESET}"
    else
      echo -e "  ${BOLD}[$i]${RESET} $display"
    fi
    ((i++))
  done
  echo -e "  ${BOLD}[a]${RESET} Install ALL personas"
  echo ""

  read -rp "$(echo -e "${YELLOW}Select personas (e.g. 1 3 or a for all): ${RESET}")" selection

  SELECTED_PERSONAS=()
  if [[ "$selection" == "a" || "$selection" == "A" ]]; then
    SELECTED_PERSONAS=("${personas[@]}")
  else
    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#personas[@]} )); then
        SELECTED_PERSONAS+=("${personas[$((num-1))]}")
      else
        print_warn "Invalid selection: $num (skipped)"
      fi
    done
  fi

  if [[ ${#SELECTED_PERSONAS[@]} -eq 0 ]]; then
    print_err "No valid personas selected."
    exit 1
  fi
}

# ── Select platform ───────────────────────────────────────────────────────────
select_platform() {
  print_step "Select target platform:"
  echo ""
  echo -e "  ${BOLD}[1]${RESET} Claude Code   ${DIM}(~/.claude/skills/)${RESET}"
  echo -e "  ${BOLD}[2]${RESET} GitHub Copilot CLI  ${DIM}(project skills/ or custom path)${RESET}"
  echo -e "  ${BOLD}[3]${RESET} Gemini CLI  ${DIM}(~/.gemini/personas/ + activate via GEMINI.md)${RESET}"
  echo -e "  ${BOLD}[4]${RESET} All platforms"
  echo ""

  read -rp "$(echo -e "${YELLOW}Select platform [1-4]: ${RESET}")" platform_choice

  case "$platform_choice" in
    1) PLATFORMS=("claude") ;;
    2) PLATFORMS=("copilot") ;;
    3) PLATFORMS=("gemini") ;;
    4) PLATFORMS=("claude" "copilot" "gemini") ;;
    *) print_err "Invalid choice."; exit 1 ;;
  esac
}

# ── Install: Claude Code ──────────────────────────────────────────────────────
install_claude() {
  local persona="$1"
  local display="$2"
  local dest_dir="$HOME/.claude/skills/$persona"

  mkdir -p "$dest_dir"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest_dir/SKILL.md"
  print_ok "Claude Code: $display → $dest_dir/SKILL.md"
}

# ── Install: GitHub Copilot CLI ───────────────────────────────────────────────
install_copilot() {
  local persona="$1"
  local display="$2"

  # Ask for project path if not already set
  if [[ -z "${COPILOT_PROJECT_PATH:-}" ]]; then
    echo ""
    read -rp "$(echo -e "${YELLOW}  Copilot: Enter project path (or press Enter for current dir): ${RESET}")" project_path
    COPILOT_PROJECT_PATH="${project_path:-$(pwd)}"
  fi

  local dest_dir="$COPILOT_PROJECT_PATH/skills/$persona"
  mkdir -p "$dest_dir"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest_dir/SKILL.md"
  print_ok "Copilot: $display → $dest_dir/SKILL.md"
}

# ── Install: Gemini CLI ───────────────────────────────────────────────────────
# Gemini CLI loads ~/.gemini/GEMINI.md as global context on every session.
# We store each persona under ~/.gemini/personas/<slug>.md and let the user
# choose which one to activate (copy to ~/.gemini/GEMINI.md).
install_gemini() {
  local persona="$1"
  local display="$2"
  local personas_store="$HOME/.gemini/personas"
  local dest="$personas_store/$persona.md"

  mkdir -p "$personas_store"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest"
  print_ok "Gemini CLI: $display → $dest"
}

# Ask which persona to activate globally after all installs
activate_gemini_persona() {
  local installed=("$@")
  if [[ ${#installed[@]} -eq 0 ]]; then return; fi

  echo ""
  echo -e "  ${CYAN}Activate a Gemini persona globally (writes to ~/.gemini/GEMINI.md)?${RESET}"
  local i=1
  for p in "${installed[@]}"; do
    local d; d=$(get_display_name "$p")
    echo -e "    ${BOLD}[$i]${RESET} $d"
    ((i++))
  done
  echo -e "    ${BOLD}[s]${RESET} Skip (activate manually later)"
  echo ""

  read -rp "$(echo -e "${YELLOW}  Select [1-${#installed[@]}/s]: ${RESET}")" act_choice

  if [[ "$act_choice" =~ ^[0-9]+$ ]] && (( act_choice >= 1 && act_choice <= ${#installed[@]} )); then
    local chosen="${installed[$((act_choice-1))]}"
    cp "$HOME/.gemini/personas/$chosen.md" "$HOME/.gemini/GEMINI.md"
    print_ok "Activated: $(get_display_name "$chosen") → ~/.gemini/GEMINI.md"
    echo -e "    ${DIM}Start Gemini CLI and the persona is loaded automatically.${RESET}"
    echo -e "    ${DIM}Switch later: cp ~/.gemini/personas/<slug>.md ~/.gemini/GEMINI.md${RESET}"
  else
    echo -e "    ${DIM}Skipped. To activate manually:${RESET}"
    echo -e "    ${DIM}  cp ~/.gemini/personas/<slug>.md ~/.gemini/GEMINI.md${RESET}"
  fi
}

# ── Also install research data (optional) ────────────────────────────────────
offer_research_install() {
  local persona="$1"
  local research_dir="$PERSONAS_DIR/$persona/references/research"
  local count
  count=$(find "$research_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$count" -gt 0 ]]; then
    echo ""
    read -rp "$(echo -e "${DIM}  Also copy $count research files for $persona? [y/N]: ${RESET}")" copy_research
    if [[ "$copy_research" =~ ^[Yy]$ ]]; then
      local dest_research="$HOME/.distilled-minds/$persona/references/research"
      mkdir -p "$dest_research"
      cp "$research_dir"/*.md "$dest_research/" 2>/dev/null || true
      print_ok "Research data → $dest_research/"
    fi
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  print_header

  # If args provided, use non-interactive mode
  if [[ $# -gt 0 ]]; then
    case "$1" in
      --list)
        echo "Available personas:"
        get_personas | while read -r p; do
          echo "  • $(get_display_name "$p") ($p)"
        done
        exit 0
        ;;
      --help|-h)
        echo "Usage: ./install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --list          List available personas"
        echo "  --help          Show this help"
        echo ""
        echo "Interactive mode: just run ./install.sh"
        exit 0
        ;;
    esac
  fi

  # Interactive mode
  select_personas
  select_platform

  echo ""
  print_step "Installing..."
  echo ""

  COPILOT_PROJECT_PATH=""
  GEMINI_INSTALLED=()

  for persona in "${SELECTED_PERSONAS[@]}"; do
    local display
    display=$(get_display_name "$persona")
    echo -e "  ${BOLD}$display${RESET}"

    for platform in "${PLATFORMS[@]}"; do
      case "$platform" in
        claude)  install_claude  "$persona" "$display" ;;
        copilot) install_copilot "$persona" "$display" ;;
        gemini)  install_gemini  "$persona" "$display"; GEMINI_INSTALLED+=("$persona") ;;
      esac
    done

    offer_research_install "$persona"
    echo ""
  done

  # If Gemini was selected, ask which persona to activate
  if [[ ${#GEMINI_INSTALLED[@]} -gt 0 ]]; then
    activate_gemini_persona "${GEMINI_INSTALLED[@]}"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}✓ Installation complete!${RESET}"
  echo ""

  # Print usage hints per platform
  for platform in "${PLATFORMS[@]}"; do
    case "$platform" in
      claude)
        echo -e "${CYAN}Claude Code:${RESET}"
        echo -e "  Restart Claude Code, then say: ${BOLD}「用 [persona名] 的視角」${RESET}"
        ;;
      copilot)
        echo -e "${CYAN}GitHub Copilot CLI:${RESET}"
        echo -e "  In your project, say: ${BOLD}「用 [persona名] 的視角」${RESET}"
        ;;
      gemini)
        echo -e "${CYAN}Gemini CLI:${RESET}"
        echo -e "  Persona stored in: ${BOLD}~/.gemini/personas/${RESET}"
        echo -e "  Active persona:    ${BOLD}~/.gemini/GEMINI.md${RESET} (loaded automatically)"
        echo -e "  Switch persona:    ${BOLD}cp ~/.gemini/personas/<slug>.md ~/.gemini/GEMINI.md${RESET}"
        echo -e "  Then just run:     ${BOLD}gemini${RESET}"
        ;;
    esac
  done
  echo ""
}

main "$@"
