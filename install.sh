#!/usr/bin/env bash
# =============================================================================
# Distilled Minds — Install Script
# Install distilled persona skills into Claude Code, GitHub Copilot CLI, or Gemini CLI
# Requires: bash 3.2+ (macOS default), standard Unix tools
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONAS_DIR="$REPO_DIR/personas"

# Meta-skills live in personas/ alongside everything else but are hidden from
# the selection menu and always auto-installed when the user picks anything.
META_SKILLS=("ask-more")

is_meta_skill() {
  local name="$1" meta
  for meta in "${META_SKILLS[@]}"; do
    [[ "$name" == "$meta" ]] && return 0
  done
  return 1
}

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

# ── Read available personas (excludes meta-skills) ──────────────────────────
get_personas() {
  local result=()
  for dir in "$PERSONAS_DIR"/*/; do
    local name
    name=$(basename "$dir")
    if [[ -f "$dir/SKILL.md" ]] && ! is_meta_skill "$name"; then
      result+=("$name")
    fi
  done
  printf '%s\n' "${result[@]}"
}

# ── Get display name from directory name ─────────────────────────────────────
# Title-cases the directory (e.g. richard-feynman → Richard Feynman).
get_display_name() {
  echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}'
}

# ── Get tagline (domain + frameworks) for a persona ──────────────────────────
# Single source of truth = README.md tables. Parses rows like
#   | **<...display name...>** | <domain> | <frameworks> | <...> |
# (case-insensitive substring match on the bolded persona cell).
# Outputs two lines: domain on stdout line 1, frameworks on line 2.
# Empty output if no match.
get_tagline() {
  local slug="$1"
  local display
  display=$(get_display_name "$slug")
  awk -F'|' -v name="$display" '
    BEGIN { needle = tolower(name) }
    /^\| \*\*/ {
      if (index(tolower($0), needle)) {
        # $2 is the bolded name cell, $3 = domain, $4 = frameworks
        domain = $3; frameworks = $4
        gsub(/^[ \t]+|[ \t]+$/, "", domain)
        gsub(/^[ \t]+|[ \t]+$/, "", frameworks)
        print domain
        print frameworks
        exit
      }
    }
  ' "$REPO_DIR/README.md"
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
    local research_dir="$PERSONAS_DIR/$persona/references"
    local research_count=0
    if [[ -d "$research_dir" ]]; then
      research_count=$(find "$research_dir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Header line: number + name + research count
    if [[ "$research_count" -gt 0 ]]; then
      echo -e "  ${BOLD}[$i]${RESET} $display ${DIM}($research_count research files)${RESET}"
    else
      echo -e "  ${BOLD}[$i]${RESET} $display"
    fi

    # Tagline lines: domain + frameworks (parsed from README tables)
    local tagline
    tagline=$(get_tagline "$persona")
    if [[ -n "$tagline" ]]; then
      local domain frameworks
      domain=$(printf '%s\n' "$tagline" | sed -n '1p')
      frameworks=$(printf '%s\n' "$tagline" | sed -n '2p')
      [[ -n "$domain"     ]] && echo -e "       ${CYAN}領域:${RESET} $domain"
      [[ -n "$frameworks" ]] && echo -e "       ${CYAN}框架:${RESET} ${DIM}$frameworks${RESET}"
    fi

    i=$((i + 1))
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
  echo -e "  ${BOLD}[3]${RESET} Gemini CLI          ${DIM}(~/.gemini/skills/<name>/)${RESET}"
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
# Gemini CLI auto-discovers skills in ~/.gemini/skills/<name>/SKILL.md
install_gemini() {
  local persona="$1"
  local display="$2"
  local dest_dir="$HOME/.gemini/skills/$persona"

  mkdir -p "$dest_dir"
  cp "$PERSONAS_DIR/$persona/SKILL.md" "$dest_dir/SKILL.md"
  print_ok "Gemini CLI: $display → $dest_dir/SKILL.md"
}

# ── Uninstall ────────────────────────────────────────────────────────────────
# Delegates to uninstall.sh to keep removal logic in a single place.
uninstall() {
  exec "$REPO_DIR/uninstall.sh" "$@"
}

# ── Parse non-interactive flags ──────────────────────────────────────────────
# Sets SELECTED_PERSONAS and PLATFORMS based on --personas / --platform flags.
# Returns 0 if non-interactive args were consumed, 1 if no relevant flags.
parse_noninteractive_args() {
  local personas_arg="" platform_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --personas)
        shift
        # Collect persona slugs until next flag or end
        local collected=()
        while [[ $# -gt 0 && "$1" != --* ]]; do
          collected+=("$1")
          shift
        done
        personas_arg="${collected[*]}"
        ;;
      --platform)
        shift
        platform_arg="${1:-}"
        shift || true
        ;;
      *)
        print_err "Unknown argument: $1"
        exit 1
        ;;
    esac
  done

  if [[ -z "$personas_arg" && -z "$platform_arg" ]]; then
    return 1
  fi
  if [[ -z "$personas_arg" || -z "$platform_arg" ]]; then
    print_err "Non-interactive mode requires both --personas and --platform"
    exit 1
  fi

  # Resolve personas
  local all_personas=()
  while IFS= read -r line; do
    all_personas+=("$line")
  done < <(get_personas)

  SELECTED_PERSONAS=()
  if [[ "$personas_arg" == "all" ]]; then
    SELECTED_PERSONAS=("${all_personas[@]}")
  else
    for p in $personas_arg; do
      local found=0
      for known in "${all_personas[@]}"; do
        if [[ "$p" == "$known" ]]; then
          SELECTED_PERSONAS+=("$p")
          found=1
          break
        fi
      done
      if [[ $found -eq 0 ]]; then
        print_err "Unknown persona: $p (use --list to see available)"
        exit 1
      fi
    done
  fi

  # Resolve platform
  case "$platform_arg" in
    claude)  PLATFORMS=("claude") ;;
    copilot) PLATFORMS=("copilot") ;;
    gemini)  PLATFORMS=("gemini") ;;
    all)     PLATFORMS=("claude" "copilot" "gemini") ;;
    *)
      print_err "Unknown platform: $platform_arg (expected: claude|copilot|gemini|all)"
      exit 1
      ;;
  esac

  return 0
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  # Initialize so `set -u` doesn't trip on later length checks
  SELECTED_PERSONAS=()
  PLATFORMS=()

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
          local tagline d f
          tagline=$(get_tagline "$p")
          if [[ -n "$tagline" ]]; then
            d=$(printf '%s\n' "$tagline" | sed -n '1p')
            f=$(printf '%s\n' "$tagline" | sed -n '2p')
            [[ -n "$d" ]] && echo "      領域: $d"
            [[ -n "$f" ]] && echo "      框架: $f"
          fi
        done
        exit 0
        ;;
      --help|-h)
        cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Interactive:
  (no args)                                 Interactive install

Non-interactive:
  --platform <claude|copilot|gemini|all> --personas <slug...|all>
                                            Install without prompts
  Examples:
    ./install.sh --platform gemini --personas all
    ./install.sh --platform claude --personas warren-buffett charlie-munger
    ./install.sh --platform all --personas all

Other:
  --uninstall                               Remove personas (delegates to uninstall.sh)
  --list                                    List available personas
  --help, -h                                Show this help
EOF
        exit 0
        ;;
      --personas|--platform)
        # Non-interactive install path
        if ! parse_noninteractive_args "$@"; then
          print_err "Failed to parse non-interactive args."
          exit 1
        fi
        ;;
      *)
        print_err "Unknown argument: $1 (use --help)"
        exit 1
        ;;
    esac
  fi

  print_header

  # Interactive mode (only if not already populated by non-interactive args)
  if [[ ${#SELECTED_PERSONAS[@]} -eq 0 ]]; then
    select_personas
  fi
  if [[ ${#PLATFORMS[@]} -eq 0 ]]; then
    select_platform
  fi

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

  # Meta-skills (ask-more etc) are hidden from the selection menu but always
  # auto-installed alongside whatever persona(s) the user picked. Reuses the
  # same install_claude/copilot/gemini functions because they live in personas/.
  for skill in "${META_SKILLS[@]}"; do
    local display
    display=$(get_display_name "$skill")
    echo -e "  ${BOLD}$display${RESET} ${DIM}(meta)${RESET}"
    for platform in "${PLATFORMS[@]}"; do
      case "$platform" in
        claude)  install_claude  "$skill" "$display" ;;
        copilot) install_copilot "$skill" "$display" ;;
        gemini)  install_gemini  "$skill" "$display" ;;
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
        echo -e "  Skills auto-discovered at: ${BOLD}~/.gemini/skills/<name>/SKILL.md${RESET}"
        echo -e "  Available in all projects. Check with: ${BOLD}/skills list${RESET}"
        echo -e "  Trigger: ${BOLD}「用 [persona名] 的視角」${RESET}"
        echo ""
        ;;
    esac
  done
}

main "$@"
