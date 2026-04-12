#!/usr/bin/env bash
# =============================================================================
# Distilled Minds — Install Script
# Install distilled persona skills into Claude Code, GitHub Copilot CLI, or Gemini CLI
# Requires: bash 3.2+ (macOS default), standard Unix tools
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
  local name
  name=$(grep -m1 '^name:' "$skill_file" 2>/dev/null | sed 's/name: *//' | tr -d '"' | sed 's/-perspective//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')
  echo "${name:-$1}"
}

# ── Select personas (multi-select) ───────────────────────────────────────────
select_personas() {
  local personas=()
  while IFS= read -r line; do
    personas+=("$line")
  done < <(get_personas)

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
  echo -e "  ${BOLD}[1]${RESET} Claude Code        ${DIM}(~/.claude/skills/<name>/)${RESET}"
  echo -e "  ${BOLD}[2]${RESET} GitHub Copilot CLI  ${DIM}(~/.copilot/skills/<name>/)${RESET}"
  echo -e "  ${BOLD}[3]${RESET} Gemini CLI          ${DIM}(~/.gemini/ with @import in GEMINI.md)${RESET}"
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
# Claude Code auto-discovers skills in ~/.claude/skills/<name>/SKILL.md
install_claude() {
  local persona="$1"
  local display="$2"
  local dest_dir="$HOME/.claude/skills/$persona"

  mkdir -p "$dest_dir"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest_dir/SKILL.md"
  print_ok "Claude Code: $display → $dest_dir/SKILL.md"
}

# ── Install: GitHub Copilot CLI ───────────────────────────────────────────────
# Copilot CLI auto-discovers personal skills in ~/.copilot/skills/<name>/SKILL.md
# (also supports ~/.claude/skills/ and ~/.agents/skills/ as personal skill dirs)
install_copilot() {
  local persona="$1"
  local display="$2"
  local dest_dir="$HOME/.copilot/skills/$persona"

  mkdir -p "$dest_dir"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest_dir/SKILL.md"
  print_ok "Copilot CLI: $display → $dest_dir/SKILL.md"
}

# ── Install: Gemini CLI ───────────────────────────────────────────────────────
# Gemini CLI loads ~/.gemini/GEMINI.md as global context every session.
# It supports @file.md imports to modularize context.
# Strategy: store each persona as ~/.gemini/personas/<slug>.md,
# then add @./personas/<slug>.md import lines to GEMINI.md.
install_gemini() {
  local persona="$1"
  local display="$2"
  local gemini_dir="$HOME/.gemini"
  local personas_store="$gemini_dir/personas"
  local dest="$personas_store/$persona.md"
  local gemini_md="$gemini_dir/GEMINI.md"

  mkdir -p "$personas_store"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest"

  # Add @import line to GEMINI.md if not already present
  local import_line="@./personas/$persona.md"
  if [[ -f "$gemini_md" ]]; then
    if ! grep -qF "$import_line" "$gemini_md"; then
      echo "" >> "$gemini_md"
      echo "$import_line" >> "$gemini_md"
    fi
  else
    # Create GEMINI.md with a header + import
    cat > "$gemini_md" <<EOF
# Distilled Minds — Active Personas
# Each @import loads a persona's cognitive framework.
# Remove a line to deactivate that persona.

$import_line
EOF
  fi

  print_ok "Gemini CLI: $display → $dest (imported in GEMINI.md)"
}

# ── Uninstall (use uninstall.sh directly) ─────────────────────────────────────
uninstall() {
  print_header
  echo -e "${RED}${BOLD}  Uninstall Mode${RESET}"
  echo -e "  ${DIM}Remove all Distilled Minds personas from a platform.${RESET}"

  print_step "Select platform to uninstall from:"
  echo ""
  echo -e "  ${BOLD}[1]${RESET} Claude Code        ${DIM}(~/.claude/skills/)${RESET}"
  echo -e "  ${BOLD}[2]${RESET} GitHub Copilot CLI  ${DIM}(~/.copilot/skills/)${RESET}"
  echo -e "  ${BOLD}[3]${RESET} Gemini CLI          ${DIM}(~/.gemini/personas/ + GEMINI.md imports)${RESET}"
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

  # Get all known persona slugs
  local personas=()
  while IFS= read -r line; do
    personas+=("$line")
  done < <(get_personas)

  echo ""
  print_step "Removing personas..."

  local p dir pfile gemini_md import_line remaining
  for platform in "${platforms_to_remove[@]}"; do
    case "$platform" in
      claude)
        for p in "${personas[@]}"; do
          dir="$HOME/.claude/skills/$p"
          if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_ok "Removed Claude: $dir"
          fi
        done
        ;;
      copilot)
        for p in "${personas[@]}"; do
          dir="$HOME/.copilot/skills/$p"
          if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_ok "Removed Copilot: $dir"
          fi
        done
        ;;
      gemini)
        gemini_md="$HOME/.gemini/GEMINI.md"
        for p in "${personas[@]}"; do
          pfile="$HOME/.gemini/personas/$p.md"
          if [[ -f "$pfile" ]]; then
            rm -f "$pfile"
            print_ok "Removed Gemini persona: $pfile"
          fi
          if [[ -f "$gemini_md" ]]; then
            import_line="@./personas/$p.md"
            if grep -qF "$import_line" "$gemini_md"; then
              sed -i '' -e "\|$import_line|d" "$gemini_md"
            fi
          fi
        done
        if [[ -d "$HOME/.gemini/personas" ]]; then
          rmdir "$HOME/.gemini/personas" 2>/dev/null || true
        fi
        if [[ -f "$gemini_md" ]]; then
          remaining=$(grep -c '^@\.' "$gemini_md" 2>/dev/null || echo "0")
          if [[ "$remaining" -eq 0 ]] && grep -q "Distilled Minds" "$gemini_md" 2>/dev/null; then
            rm -f "$gemini_md"
            print_ok "Removed empty GEMINI.md (was only Distilled Minds content)"
          fi
        fi
        print_ok "Cleaned Gemini GEMINI.md imports"
        ;;
    esac
  done

  echo ""
  echo -e "${GREEN}${BOLD}✓ Uninstall complete!${RESET}"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  # If args provided, use non-interactive mode
  if [[ $# -gt 0 ]]; then
    case "$1" in
      --uninstall)
        uninstall
        exit 0
        ;;
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
        echo "  (no args)       Interactive install"
        echo "  --uninstall     Remove all personas from a platform"
        echo "  --list          List available personas"
        echo "  --help          Show this help"
        exit 0
        ;;
    esac
  fi

  print_header

  # Interactive mode
  select_personas
  select_platform

  echo ""
  print_step "Installing..."
  echo ""

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

    echo ""
  done

  echo ""
  echo -e "${GREEN}${BOLD}✓ Installation complete!${RESET}"
  echo ""

  # Print usage hints per platform
  for platform in "${PLATFORMS[@]}"; do
    case "$platform" in
      claude)
        echo -e "${CYAN}Claude Code:${RESET}"
        echo -e "  Skills auto-discovered at: ${BOLD}~/.claude/skills/<name>/SKILL.md${RESET}"
        echo -e "  Trigger: ${BOLD}「用 [persona名] 的視角」${RESET}"
        echo ""
        ;;
      copilot)
        echo -e "${CYAN}GitHub Copilot CLI:${RESET}"
        echo -e "  Skills auto-discovered at: ${BOLD}~/.copilot/skills/<name>/SKILL.md${RESET}"
        echo -e "  Available in all projects. Check with: ${BOLD}/skills list${RESET}"
        echo -e "  Trigger: ${BOLD}「用 [persona名] 的視角」${RESET} or ${BOLD}/skills${RESET}"
        echo ""
        ;;
      gemini)
        echo -e "${CYAN}Gemini CLI:${RESET}"
        echo -e "  Personas stored in: ${BOLD}~/.gemini/personas/${RESET}"
        echo -e "  Auto-loaded via:    ${BOLD}~/.gemini/GEMINI.md${RESET} (@import)"
        echo -e "  All installed personas are active simultaneously."
        echo -e "  To deactivate one, remove its @import line from GEMINI.md."
        echo -e "  Check loaded context: ${BOLD}/memory show${RESET}"
        echo ""
        ;;
    esac
  done
}

main "$@"
