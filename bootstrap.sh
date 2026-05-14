#!/usr/bin/env bash
# ===============================================================
#  config-zsh Bootstrap Installer
#  https://github.com/smnuman/config-zsh
# ===============================================================
#  Converts macOS-oriented config to any platform.
#  Merge-safe: preserves existing customizations as .pre-bootstrap.
#  Brew is only used on macOS; skipped on Linux/WSL.
#
#  Default mapping:
#    config-zsh (repo)  →  ~/.config/zsh
#    zsh-prompt (submod) →  ~/.config/zsh/prompt
#    zsh-git-utils (sub) →  ~/.config/zsh/git-utils
#    config-brew (repo)  →  ~/.config/brew         [not managed here]
#    dotconfig (repo)    →  ~/.config               [not managed here]
#
#  Usage:
#    git clone git@github.com:smnuman/config-zsh.git ~/.config/zsh
#    cd ~/.config/zsh && ./bootstrap.sh
#
#    # Or pipe directly (curl | bash):
#    bash <(curl -fsSL https://raw.githubusercontent.com/smnuman/config-zsh/main/bootstrap.sh)
# ===============================================================

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
BACKUP_DIR="${ZDOTDIR}.pre-bootstrap.$(date +%Y%m%d_%H%M%S)"
FORCE=false
DRY_RUN=false
SKIP_DEPS=false
SKIP_PLUGINS=false

# ─── Platform Detection ───────────────────────────────────────
detect_platform() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}

detect_pkg_manager() {
  if command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apt &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v yum &>/dev/null; then
    echo "yum"
  elif command -v zypper &>/dev/null; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

PLATFORM=$(detect_platform)
PKG_MANAGER=$(detect_pkg_manager)

# ─── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}▸${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }

# ─── Help ─────────────────────────────────────────────────────
usage() {
  cat <<'HELP'
Usage: ./bootstrap.sh [options]

Options:
  --dry-run        Show what would be done without making changes
  --force          Overwrite existing files (backup still made)
  --skip-deps      Skip dependency installation
  --skip-plugins   Skip plugin cloning
  --zdotdir PATH   Use custom ZDOTDIR (default: ~/.config/zsh)
  --help           Show this help
HELP
  exit 0
}

# ─── Args ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --force)      FORCE=true; shift ;;
    --skip-deps)  SKIP_DEPS=true; shift ;;
    --skip-plugins) SKIP_PLUGINS=true; shift ;;
    --zdotdir)    ZDOTDIR="$2"; shift 2 ;;
    --help|-h)    usage ;;
    *)            error "Unknown option: $1"; usage ;;
  esac
done

# ─── Safety Checks ────────────────────────────────────────────
if [[ "$DRY_RUN" == "false" ]]; then
  if [[ ! -d "$REPO_DIR" ]]; then
    error "Cannot find repo directory: $REPO_DIR"
    exit 1
  fi

  if [[ -d "$ZDOTDIR" && "$FORCE" == "false" ]]; then
    info "Backing up existing $ZDOTDIR → $BACKUP_DIR"
    cp -a "$ZDOTDIR" "$BACKUP_DIR"
    ok "Backup created at $BACKUP_DIR"
  elif [[ -d "$ZDOTDIR" && "$FORCE" == "true" ]]; then
    warn "Force mode: backing up anyway → $BACKUP_DIR"
    cp -a "$ZDOTDIR" "$BACKUP_DIR"
  fi

  mkdir -p "$ZDOTDIR"
fi

info "Platform: ${PLATFORM}"
info "Package manager: ${PKG_MANAGER}"
info "Repo: ${REPO_DIR}"
info "Destination: ${ZDOTDIR}"
echo ""

# ─── File Transform Functions ─────────────────────────────────
# Each *_transform reads from stdin, writes platform-adapted version to stdout.

# Helper: strip brew-specific lines on non-macos
strip_brew() {
  if [[ "$PLATFORM" != "macos" ]]; then
    grep -v -E '(^HOMEBREW_| HOMEBREW_|BREWDOTS|BREWLOGS|BRUTILS|brew --prefix)' || cat
  else
    cat
  fi
}

# zsh-aliases: convert mac commands to linux/wsl equivalents
zsh_aliases_transform() {
  if [[ "$PLATFORM" == "macos" ]]; then
    cat
    return
  fi
  sed \
    -e '/^alias usage=/s/ifconfig wlan0 | grep .bytes./ip -s link/' \
    -e '/^alias localip=/s|ipconfig getifaddr en0|hostname -I 2>/dev/null | awk '"'"'{print \$1}'"'"'|' \
    -e '/^alias flushdns=/s/.*/# alias flushdns removed — not applicable on Linux/' \
    -e '/^alias connections=/s/^/# [disabled on Linux] /' \
    -e '/^alias ports=/s/^/# [disabled on Linux] /' \
    -e '/^alias myip=/!b;c\alias myip='"'"'curl -s ifconfig.me'"'" \
    | sed '/^[[:space:]]*$/d'
}

# zsh-exports: remove brew paths, adapt LSCOLORS
zsh_exports_transform() {
  sed \
    -e '/^export LDFLAGS=/s/^/# [disabled on Linux] /' \
    -e '/^export CPPFLAGS=/s/^/# [disabled on Linux] /' \
    -e '/^export HOMEBREW_/s/^/# [disabled on Linux] /' \
    -e '/^export_path.*BREW/s/^/# [disabled on Linux] /' \
    | strip_brew
}

# zsh-functions: strip brew-specific
zsh_functions_transform() {
  if [[ "$PLATFORM" != "macos" ]]; then
    grep -v -E '(brew_log_summary|clear_brew_logs)' || true
  else
    cat
  fi
}

# env.zsh: adapt PATH for non-macos
env_zsh_transform() {
  if [[ "$PLATFORM" == "macos" ]]; then
    cat
  else
    # Replace brew PATH with standard Linux PATH
    sed \
      -e 's|export PATH="\$HOMEBREW_PREFIX/bin:\$HOMEBREW_PREFIX/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"|export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"|' \
      -e 's|//usr/local/bin|/usr/local/bin|g' \
      | strip_brew
  fi
}

# zsh-fuzzy: adapt fzf path for non-macos
zsh_fuzzy_transform() {
  if [[ "$PLATFORM" == "macos" ]]; then
    cat
  else
    # Replace brew-based fzf path with linux paths
    # Try /usr/share/doc/fzf (Debian/Ubuntu) then /usr/share/fzf (Arch)
    sed \
      -e '/fzf_prefix=/s|.*|  local fzf_prefix="/usr/share/doc/fzf"\
  [[ -d "$fzf_prefix" ]] || fzf_prefix="/usr/share/fzf"|'
  fi
}

# zsh-vim-mode: ensure terminal compatibility
zsh_vim_mode_transform() {
  if [[ "$PLATFORM" == "wsl" ]]; then
    # WSL terminals often behave like xterm
    sed -e 's|$TERM == "iterm"\*|$TERM == "xterm"*|' | cat
  else
    cat
  fi
}

# ─── File Processing ──────────────────────────────────────────
# process_file <src_rel> <dest_rel> [transform_fn]
# Copies from repo to ZDOTDIR, applies optional transform, handles merge.
process_file() {
  local src_rel="$1"
  local dest_rel="$2"
  local transform_fn="${3:-}"
  local src_path="$REPO_DIR/$src_rel"
  local dest_path="$ZDOTDIR/$dest_rel"
  local dest_dir

  dest_dir=$(dirname "$dest_path")
  mkdir -p "$dest_dir"

  if [[ ! -f "$src_path" ]]; then
    warn "Source not found: $src_rel — skipping"
    return 0
  fi

  if [[ -f "$dest_path" ]]; then
    local pre_path="${dest_path}.pre-bootstrap"
    if [[ ! -f "$pre_path" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        info "[dry-run] backup $dest_rel → ${dest_rel}.pre-bootstrap + install (transformed)"
      else
        cp "$dest_path" "$pre_path"
        ok "Backed up $dest_rel → ${dest_rel}.pre-bootstrap"
      fi
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  if [[ -n "$transform_fn" ]]; then
    $transform_fn < "$src_path" > "$dest_path" 2>/dev/null || cp "$src_path" "$dest_path"
    ok "Installed (transformed): $dest_rel"
  else
    cp "$src_path" "$dest_path"
    ok "Installed: $dest_rel"
  fi
}

# ─── Generate unified .zshrc ──────────────────────────────────
generate_zshrc() {
  local dest_path="$ZDOTDIR/.zshrc"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[dry-run] would generate unified .zshrc → $dest_path"
    return 0
  fi

  if [[ -f "$dest_path" ]]; then
    local pre_path="${dest_path}.pre-bootstrap"
    [[ ! -f "$pre_path" ]] && cp "$dest_path" "$pre_path"
    ok "Backed up .zshrc → .zshrc.pre-bootstrap"
  fi

  cat > "$dest_path" <<'ZSHRC_EOF'
#!/usr/bin/env zsh
# ============================================================
#  Unified .zshrc — generated by config-zsh bootstrap.sh
#  Repo: https://github.com/smnuman/config-zsh
# ============================================================
#  Platform-adaptive: same file works on macOS, Linux, WSL.
#  Brew sections are active only when brew is installed.
# ============================================================

autoload -Uz add-zsh-hook

# === Init Profiler (optional, lightweight) ===
if [[ -f "$ZSHLIB/init-profiler.zsh" ]]; then
  source "$ZSHLIB/init-profiler.zsh"
  zprof_start "TOTAL"
fi

zprof_start "env.zsh"
[[ -f "$ZDOTDIR/env.zsh" ]] && source "$ZDOTDIR/env.zsh"
zprof_end "env.zsh"

# === Bootlog Handler ===
[[ -f "$ZUTILS/zsh-bootlog-handler" ]] && source "$ZUTILS/zsh-bootlog-handler"

zsh_bootlog "Phase 1: env.zsh loaded"

# === Platform Detection ===
export ZSH_PLATFORM=""
if [[ "$(uname)" == "Darwin" ]]; then
  export ZSH_PLATFORM="macos"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  export ZSH_PLATFORM="wsl"
else
  export ZSH_PLATFORM="linux"
fi

# === Platform: macOS Early Setup (brew) ===
if [[ "$ZSH_PLATFORM" == "macos" ]]; then
  zsh_bootlog "Phase 2: loading brew environment"
  [[ -f "$BREWDOTS/.env" ]] && source "$BREWDOTS/.env"
fi

# === Platform: WSL Early Setup ===
if [[ "$ZSH_PLATFORM" == "wsl" ]]; then
  zsh_bootlog "Phase 2: loading WSL environment"
  for f in "$ZDOTDIR"/env/[0-9][0-9]-*.zsh(N); do
    source "$f"
  done
  [[ -f "$ZUTILS/wsl.zsh" ]] && source "$ZUTILS/wsl.zsh"
fi

zsh_bootlog "Phase 3: loading zsh options"

# === Zsh Options ===
[[ -f "$ZDOTDIR/zsh-optionrc" ]] && source "$ZDOTDIR/zsh-optionrc"

zsh_bootlog "Phase 4: loading key bindings"

# === Key Bindings ===
[[ -f "$ZDOTDIR/lib/keybinds.zsh" ]] && source "$ZDOTDIR/lib/keybinds.zsh"

zsh_bootlog "Phase 5: loading git environment"

# === Git Init ===
[[ -f "$ZDOTDIR/lib/zsh-initgit.zsh" ]] && source "$ZDOTDIR/lib/zsh-initgit.zsh"

zsh_bootlog "Phase 6: loading plugin manager"

# === Plugin Manager ===
[[ -f "$ZDOTDIR/lib/plugin_manager.zsh" ]] && source "$ZDOTDIR/lib/plugin_manager.zsh"

zsh_bootlog "Phase 7: loading modules"

# === Module Loader (aliases, exports, functions, completions) ===
[[ -f "$ZDOTDIR/lib/zsh-init.zsh" ]] && source "$ZDOTDIR/lib/zsh-init.zsh"

zsh_bootlog "Phase 8: loading fuzzy tools"

# === Fuzzy Tools (fzf + zoxide) ===
[[ -f "$ZDOTDIR/lib/zsh-fuzzy.zsh" ]] && source "$ZDOTDIR/lib/zsh-fuzzy.zsh"

zsh_bootlog "Phase 9: loading prompt"

# === Prompt ===
fpath=("$ZDOTDIR/lib/prompts" "$ZDOTDIR/prompt" $fpath)
autoload -Uz promptinit && promptinit 2>/dev/null
[[ -f "$ZDOTDIR/zsh-prompt" ]] && source "$ZDOTDIR/zsh-prompt"

zsh_bootlog "Phase 10: loading completions"

# === Completions ===
[[ -f "$ZDOTDIR/completions.zsh" ]] && source "$ZDOTDIR/completions.zsh"

# === Platform: macOS Late Setup ===
if [[ "$ZSH_PLATFORM" == "macos" ]]; then
  :
fi

# === Platform: WSL Late Setup ===
if [[ "$ZSH_PLATFORM" == "wsl" ]]; then
  [[ -f "$ZDOTDIR/env/40-livekit.zsh" ]] && source "$ZDOTDIR/env/40-livekit.zsh"
  [[ -f "$ZDOTDIR/env/999-alias.zsh" ]] && source "$ZDOTDIR/env/999-alias.zsh"
fi

# === Local overrides (gitignored) ===
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

zsh_bootlog "Phase 11: .zshrc complete."

zprof_end "TOTAL"
zprof_report
ZSHRC_EOF

  ok "Generated unified .zshrc"
}

# ─── Install Plugins ──────────────────────────────────────────
install_plugins() {
  info "Installing zsh plugins..."

  local plugins_dir="$ZDOTDIR/plugins"
  mkdir -p "$plugins_dir"

  # Plugin list from zsh-init.zsh
  declare -A PLUGINS
  PLUGINS["zsh-users/zsh-autosuggestions"]="zsh-autosuggestions"
  PLUGINS["zsh-users/zsh-syntax-highlighting"]="zsh-syntax-highlighting"
  PLUGINS["zsh-users/zsh-history-substring-search"]="zsh-history-substring-search"
  PLUGINS["Aloxaf/fzf-tab"]="fzf-tab"
  PLUGINS["smnuman/zsh-history-search-end-match"]="zsh-history-search-end-match"
  PLUGINS["supercrabtree/k"]="k"

  for repo in "${!PLUGINS[@]}"; do
    local dir_name="${PLUGINS[$repo]}"
    local plugin_dir="$plugins_dir/$dir_name"

    if [[ -d "$plugin_dir/.git" ]]; then
      ok "Plugin already exists: $dir_name"
    else
      if [[ "$DRY_RUN" == "true" ]]; then
        info "[dry-run] would clone $repo → plugins/$dir_name"
      else
        info "Cloning $repo ..."
        git clone --depth=1 --single-branch "https://github.com/$repo.git" "$plugin_dir" 2>/dev/null && \
          ok "Cloned: $dir_name" || \
          warn "Failed to clone $repo (network issue?)"
      fi
    fi
  done
}

# ─── Init Submodules ──────────────────────────────────────────
init_submodules() {
  if [[ ! -f "$REPO_DIR/.gitmodules" ]]; then
    return 0
  fi

  info "Initializing git submodules (prompt, git-utils)..."

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[dry-run] would run: git submodule update --init --recursive"
    return 0
  fi

  # If repo is cloned to ZDOTDIR, submodules live inside ZDOTDIR
  if [[ -d "$REPO_DIR/.git" ]]; then
    (cd "$REPO_DIR" && git submodule update --init --recursive 2>/dev/null) && \
      ok "Submodules initialized" || \
      warn "Submodule init failed (check network or SSH keys)"
  fi
}

# ─── Install Dependencies ─────────────────────────────────────
install_deps() {
  local -a DEPS=()

  if ! command -v git &>/dev/null; then
    DEPS+=("git")
  fi

  if ! command -v fzf &>/dev/null; then
    DEPS+=("fzf")
  fi

  if ! command -v zoxide &>/dev/null; then
    DEPS+=("zoxide")
  fi

  if ! command -v bat &>/dev/null; then
    DEPS+=("bat")
  fi

  if ! command -v eza &>/dev/null; then
    DEPS+=("eza")
  fi

  if ! command -v gh &>/dev/null; then
    [[ "$PLATFORM" == "macos" ]] && DEPS+=("gh")
  fi

  if [[ ${#DEPS[@]} -eq 0 ]]; then
    ok "All dependencies already installed"
    return 0
  fi

  info "Missing dependencies: ${DEPS[*]}"
  info "Install using your package manager:"

  case "$PKG_MANAGER" in
    brew)
      echo "  brew install ${DEPS[*]}"
      if [[ "$DRY_RUN" == "false" ]]; then
        info "Attempting brew install..."
        brew install "${DEPS[@]}" 2>/dev/null && ok "Dependencies installed" || warn "brew install had issues (may need manual install)"
      fi
      ;;
    apt)
      echo "  sudo apt install ${DEPS[*]}"
      if [[ "$DRY_RUN" == "false" ]]; then
        info "You can run: sudo apt install ${DEPS[*]}"
      fi
      ;;
    dnf)
      echo "  sudo dnf install ${DEPS[*]}"
      ;;
    pacman)
      echo "  sudo pacman -S ${DEPS[*]}"
      ;;
    *)
      echo "  Install manually: ${DEPS[*]}"
      ;;
  esac
  echo ""
}

# ─── Symlink Setup ────────────────────────────────────────────
setup_symlinks() {
  info "Setting up symlinks..."

  # ~/.zshenv → ~/.config/zsh/my.zshenv
  if [[ ! -L "$HOME/.zshenv" ]]; then
    if [[ -f "$HOME/.zshenv" && ! -L "$HOME/.zshenv" ]]; then
      local zshenv_bak="$HOME/.zshenv.pre-bootstrap"
      if [[ "$DRY_RUN" == "true" ]]; then
        info "[dry-run] would backup ~/.zshenv → $zshenv_bak"
        info "[dry-run] would link ~/.zshenv → $ZDOTDIR/my.zshenv"
      else
        mv "$HOME/.zshenv" "$zshenv_bak"
        ln -sf "$ZDOTDIR/my.zshenv" "$HOME/.zshenv"
        ok "Linked ~/.zshenv → my.zshenv (backed up old → .zshenv.pre-bootstrap)"
      fi
    elif [[ ! -e "$HOME/.zshenv" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        info "[dry-run] would link ~/.zshenv → $ZDOTDIR/my.zshenv"
      else
        ln -sf "$ZDOTDIR/my.zshenv" "$HOME/.zshenv"
        ok "Linked ~/.zshenv → my.zshenv"
      fi
    fi
  else
    ok "~/.zshenv already linked"
  fi

  # ~/.zshrc → ~/.config/zsh/.zshrc (only if not already symlinked)
  if [[ ! -L "$HOME/.zshrc" ]]; then
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
      local zshrc_bak="$HOME/.zshrc.pre-bootstrap"
      if [[ "$DRY_RUN" == "true" ]]; then
        info "[dry-run] would backup ~/.zshrc → $zshrc_bak"
        info "[dry-run] would link ~/.zshrc → $ZDOTDIR/.zshrc"
      else
        mv "$HOME/.zshrc" "$zshrc_bak"
        ln -sf "$ZDOTDIR/.zshrc" "$HOME/.zshrc"
        ok "Linked ~/.zshrc → .zshrc (backed up old → .zshrc.pre-bootstrap)"
      fi
    elif [[ ! -e "$HOME/.zshrc" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        info "[dry-run] would link ~/.zshrc → $ZDOTDIR/.zshrc"
      else
        ln -sf "$ZDOTDIR/.zshrc" "$HOME/.zshrc"
        ok "Linked ~/.zshrc → .zshrc"
      fi
    fi
  else
    ok "~/.zshrc already linked"
  fi
}

# ─── Post-Install Summary ─────────────────────────────────────
print_summary() {
  echo ""
  echo "================================================"
  echo -e "  ${GREEN}config-zsh bootstrap complete${NC}"
  echo "================================================"
  echo ""
  echo "  Platform:  $PLATFORM"
  echo "  Location:  $ZDOTDIR"
  echo ""

  if [[ -d "$BACKUP_DIR" ]]; then
    echo "  ${YELLOW}Backup:${NC}"
    echo "    Old config saved to: $BACKUP_DIR"
    echo "    Per-file .pre-bootstrap backups also exist alongside new files."
    echo ""
  fi

  echo "  ${CYAN}Manual steps:${NC}"
  echo ""

  if [[ "$PLATFORM" == "macos" ]] && ! command -v brew &>/dev/null; then
    echo "    ○ Install Homebrew: https://brew.sh"
    echo "    ○ Then run: brew shellenv > ~/.config/brew/.env"
    echo ""
  fi

  if [[ "$PLATFORM" == "wsl" ]]; then
    echo "    ○ Ensure Windows paths are correct in:"
    echo "        $ZDOTDIR/env/10-windows.zsh"
    echo "        $ZDOTDIR/env/20-workspace.zsh"
    echo ""
  fi

  if [[ "$PKG_MANAGER" == "unknown" ]]; then
    echo "    ○ Install a package manager (apt, dnf, pacman)"
    echo ""
  fi

  echo "  ${CYAN}To activate:${NC}"
  echo "    exec zsh"
  echo "    # or restart your terminal"
  echo ""
  echo "  ${CYAN}If something breaks:${NC}"
  echo "    Restore from backup:  cp -a $BACKUP_DIR/* $ZDOTDIR/"
  echo "    Or per-file: rename .pre-bootstrap back to original"
  echo ""
  echo "================================================"
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────
main() {
  echo ""
  echo "================================================"
  echo -e "  ${CYAN}config-zsh Bootstrap Installer${NC}"
  echo "================================================"
  echo ""

  # ── Process Files ──
  info "Installing config files..."

  # Files needing platform-specific transforms
  process_file "zsh-aliases"  "zsh-aliases"  zsh_aliases_transform
  process_file "zsh-exports"  "zsh-exports"  zsh_exports_transform
  process_file "zsh-functions" "zsh-functions" zsh_functions_transform
  process_file "env.zsh"      "env.zsh"      env_zsh_transform
  process_file "lib/zsh-fuzzy.zsh" "lib/zsh-fuzzy.zsh" zsh_fuzzy_transform
  process_file "zsh-vim-mode" "zsh-vim-mode" zsh_vim_mode_transform

  # Cross-platform files (no transform needed)
  process_file "my.zshenv"     "my.zshenv"
  process_file "zsh-optionrc"  "zsh-optionrc"
  process_file "zsh-complist"  "zsh-complist"
  process_file "zsh-prompt"    "zsh-prompt"
  process_file "lib/plugin_manager.zsh"  "lib/plugin_manager.zsh"
  process_file "lib/keybinds.zsh"        "lib/keybinds.zsh"
  process_file "lib/pathtools.zsh"       "lib/pathtools.zsh"
  process_file "lib/zsh-init.zsh"        "lib/zsh-init.zsh"
  process_file "lib/zsh-initgit.zsh"     "lib/zsh-initgit.zsh"

  # Utils directory (files only, skip subdirs)
  if [[ -d "$REPO_DIR/utils" ]]; then
    mkdir -p "$ZDOTDIR/utils"
    while IFS= read -r -d '' util; do
      local name
      name=$(basename "$util")
      process_file "utils/$name" "utils/$name"
    done < <(find "$REPO_DIR/utils" -maxdepth 1 -type f -print0)
  fi

  # Completions directory
  if [[ -d "$REPO_DIR/completions" ]]; then
    mkdir -p "$ZDOTDIR/completions"
    for comp in "$REPO_DIR/completions"/*; do
      [[ -f "$comp" ]] && process_file "completions/$(basename "$comp")" "completions/$(basename "$comp")"
    done
  fi

  # ── Generate Unified .zshrc ──
  echo ""
  generate_zshrc

  # ── Init Submodules ──
  echo ""
  init_submodules

  # ── Install Plugins ──
  if [[ "$SKIP_PLUGINS" == "false" ]]; then
    echo ""
    install_plugins
  fi

  # ── Install Dependencies ──
  if [[ "$SKIP_DEPS" == "false" ]]; then
    echo ""
    install_deps
  fi

  # ── Set up symlinks ──
  echo ""
  setup_symlinks

  # ── Print Summary ──
  print_summary
}

main "$@"
