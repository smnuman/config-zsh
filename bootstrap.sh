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
  while IFS= read -r line; do
    case "$line" in
      'alias usage='*)
        echo "alias usage='ip -s link'"
        ;;
      'alias localip='*)
        echo "alias localip='hostname -I 2>/dev/null'"
        ;;
      'alias flushdns='*)
        echo "# alias flushdns removed — not applicable on Linux"
        ;;
      'alias connections='*)
        echo "# [disabled on Linux] $line"
        ;;
      'alias ports='*)
        echo "# [disabled on Linux] $line"
        ;;
      'alias myip='*)
        echo "alias myip='curl -s ifconfig.me'"
        ;;
      *)
        [[ -n "$line" ]] && echo "$line"
        ;;
    esac
  done
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
    while IFS= read -r line; do
      case "$line" in
        *'fzf_prefix='*)
          echo '  local fzf_prefix="/usr/share/doc/fzf"'
          echo '  [[ -d "$fzf_prefix" ]] || fzf_prefix="/usr/share/fzf"'
          ;;
        *'fzf --zsh'*)
          echo '  command -v fzf &>/dev/null && fzf --zsh 2>/dev/null && eval "$(fzf --zsh 2>/dev/null)" || true'
          ;;
        *)
          echo "$line"
          ;;
      esac
    done
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

# ─── Generate machine-local overrides (.zshrc.local, gitignored) ──
# Re-created per-OS at deployment. macOS keeps bun globals under
# ~/.cache/.bun/bin; Linux/WSL default to ~/.bun/bin.
generate_zshrc_local() {
  local dest_path="$ZDOTDIR/.zshrc.local"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[dry-run] would generate machine-local .zshrc.local ($PLATFORM) → $dest_path"
    return 0
  fi

  if [[ -f "$dest_path" ]]; then
    local pre_path="${dest_path}.pre-bootstrap"
    [[ ! -f "$pre_path" ]] && cp "$dest_path" "$pre_path"
    ok "Backed up .zshrc.local → .zshrc.local.pre-bootstrap"
  fi

  {
    echo "# ~/.config/zsh/.zshrc.local — machine-specific overrides (gitignored)"
    echo "# Sourced last by .zshrc (Phase 11). Auto-generated by bootstrap.sh per-OS."
    echo "# Platform: $PLATFORM"
    echo "# -----------------------------------------------------------------------------"
    echo ""
  } > "$dest_path"

  case "$PLATFORM" in
    mac)
      cat >> "$dest_path" <<'LOCAL_EOF'
# --- bun global tools (macOS: globals live under ~/.cache/.bun/bin) ---
[[ -d "$HOME/.cache/.bun/bin" ]] && export PATH="$HOME/.cache/.bun/bin:$PATH"

# --- bun completions ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- openclaw aliases ---
alias clawstart='pkill -f openclaw-gateway; sleep 2; openclaw gateway start'
alias og='source $HOME/.zshrc && openclaw'
LOCAL_EOF
      ;;
    wsl)
      cat >> "$dest_path" <<'LOCAL_EOF'
# --- bun global tools (WSL: probe both common locations) ---
for _d in "$HOME/.bun/bin" "$HOME/.cache/.bun/bin"; do
  [[ -d "$_d" ]] && export PATH="$_d:$PATH"
done
unset _d

# --- bun completions ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- open URLs/files via the Windows host when available ---
command -v wslview >/dev/null 2>&1 && export BROWSER=wslview

# --- openclaw aliases ---
alias clawstart='pkill -f openclaw-gateway; sleep 2; openclaw gateway start'
alias og='source $HOME/.zshrc && openclaw'
LOCAL_EOF
      ;;
    *)  # linux (and any other)
      cat >> "$dest_path" <<'LOCAL_EOF'
# --- bun global tools (Linux: globals typically under ~/.bun/bin) ---
[[ -d "$HOME/.bun/bin" ]] && export PATH="$HOME/.bun/bin:$PATH"

# --- bun completions ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- openclaw aliases ---
alias clawstart='pkill -f openclaw-gateway; sleep 2; openclaw gateway start'
alias og='source $HOME/.zshrc && openclaw'
LOCAL_EOF
      ;;
  esac

  ok "Generated .zshrc.local for $PLATFORM"
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

  info "Initializing git submodules..."

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[dry-run] would init submodules and copy them to $ZDOTDIR"
    return 0
  fi

  if [[ ! -d "$REPO_DIR/.git" ]]; then
    warn "Not a git repo — skipping submodule init"
    return 0
  fi

  # Init and checkout submodules inside the repo (try SSH, fall back to HTTPS)
  if ! (cd "$REPO_DIR" && git submodule update --init --recursive 2>/dev/null); then
    # SSH might not be configured; try HTTPS as fallback
    local submod_url
    while IFS= read -r sub_url; do
      sub_url="${sub_url/#git@github.com:/https:\/\/github.com\/}"
      sub_url="${sub_url/%.git/}"
      local sub_name
      sub_name=$(basename "$sub_url")
      local sub_dst="$REPO_DIR/$(grep -B1 "$sub_name" "$REPO_DIR/.gitmodules" | grep path | awk '{print $3}')"
      if [[ -n "$sub_dst" && ! -d "$sub_dst" ]]; then
        git clone --depth=1 "$sub_url" "$sub_dst" 2>/dev/null
      fi
    done < <(grep url "$REPO_DIR/.gitmodules" | awk '{print $3}')
  fi

  # Copy submodule content to ZDOTDIR
  while IFS= read -r sub_path; do
    local src_sub="$REPO_DIR/$sub_path"
    local dst_sub="$ZDOTDIR/$sub_path"

    if [[ -d "$src_sub" && ! -d "$dst_sub" ]]; then
      mkdir -p "$(dirname "$dst_sub")"
      cp -a "$src_sub" "$dst_sub"
      ok "Installed submodule: $sub_path"
    elif [[ -d "$src_sub" && -d "$dst_sub" ]]; then
      info "Submodule already exists: $sub_path (skipping)"
    fi
  done < <(grep -E 'path = ' "$REPO_DIR/.gitmodules" | awk '{print $3}')
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

  # ~/.zprofile → ~/.config/zsh/lib/.zprofile  [macOS only — loads brew shellenv]
  if [[ "$PLATFORM" == "macos" ]]; then
    local zprofile_src="$ZDOTDIR/lib/.zprofile"
    if [[ ! -L "$HOME/.zprofile" ]]; then
      if [[ -f "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]]; then
        local zprofile_bak="$HOME/.zprofile.pre-bootstrap"
        if [[ "$DRY_RUN" == "true" ]]; then
          info "[dry-run] would backup ~/.zprofile → $zprofile_bak"
          info "[dry-run] would link ~/.zprofile → $zprofile_src"
        else
          mv "$HOME/.zprofile" "$zprofile_bak"
          ln -sf "$zprofile_src" "$HOME/.zprofile"
          ok "Linked ~/.zprofile → lib/.zprofile (backed up old → .zprofile.pre-bootstrap)"
        fi
      elif [[ ! -e "$HOME/.zprofile" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          info "[dry-run] would link ~/.zprofile → $zprofile_src"
        else
          ln -sf "$zprofile_src" "$HOME/.zprofile"
          ok "Linked ~/.zprofile → lib/.zprofile (brew shellenv on login)"
        fi
      fi
    else
      ok "~/.zprofile already linked"
    fi
  fi

  # ~/.config/.promptrc → $ZDOTDIR/prompt/prompt.rc  [user-editable prompt config]
  # Per-machine: dotconfig parent .gitignores .promptrc so the symlink target
  # can differ between hosts without dirtying the repo.
  local promptrc_dest="$(dirname "$ZDOTDIR")/.promptrc"
  local promptrc_src="$ZDOTDIR/prompt/prompt.rc"
  if [[ -f "$promptrc_src" ]]; then
    if [[ ! -L "$promptrc_dest" ]]; then
      if [[ -f "$promptrc_dest" && ! -L "$promptrc_dest" ]]; then
        local promptrc_bak="$promptrc_dest.pre-bootstrap"
        if [[ "$DRY_RUN" == "true" ]]; then
          info "[dry-run] would backup $promptrc_dest → $promptrc_bak"
          info "[dry-run] would link $promptrc_dest → $promptrc_src"
        else
          mv "$promptrc_dest" "$promptrc_bak"
          ln -sf "$promptrc_src" "$promptrc_dest"
          ok "Linked .promptrc → prompt/prompt.rc (backed up old → .promptrc.pre-bootstrap)"
        fi
      elif [[ ! -e "$promptrc_dest" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          info "[dry-run] would link $promptrc_dest → $promptrc_src"
        else
          ln -sf "$promptrc_src" "$promptrc_dest"
          ok "Linked .promptrc → prompt/prompt.rc"
        fi
      fi
    else
      ok ".promptrc already linked"
    fi
  fi
}

# ─── Sync submodule.<name>.update from .gitmodules → local .git/config ──
# Background: `git submodule init` only copies submodule URLs to .git/config.
# Other `.gitmodules` settings (notably `update = merge`) are NOT copied, so
# fresh clones fall back to `update = checkout` and detach every submodule on
# pull. This recurses from the parent of $ZDOTDIR (e.g. ~/.config) through
# every nested submodule and applies each `submodule.<name>.update` value
# from `.gitmodules` into the corresponding repo's `.git/config`.
_sync_update_recursive() {
  local repo="$1"
  local gitmodules="$repo/.gitmodules"
  [[ -f "$gitmodules" ]] || return 0
  local applied=false

  # Apply each submodule.<name>.update entry to repo's local .git/config
  while IFS=' ' read -r key value; do
    [[ -z "$key" ]] && continue
    if [[ "$DRY_RUN" == "true" ]]; then
      info "[dry-run] would set $key=$value in ${repo/$HOME/~}/.git/config"
    else
      git -C "$repo" config "$key" "$value"
    fi
    applied=true
  done < <(git -C "$repo" config -f .gitmodules --get-regexp 'submodule\..*\.update' 2>/dev/null || true)

  if [[ "$applied" == "true" ]]; then
    ok "Submodule update strategies applied in ${repo/$HOME/~}"
  fi

  # Recurse into each submodule that's been initialised
  while IFS=' ' read -r key sub_path; do
    [[ -z "$sub_path" ]] && continue
    local sub_repo="$repo/$sub_path"
    [[ -e "$sub_repo/.git" ]] || continue
    _sync_update_recursive "$sub_repo"
  done < <(git -C "$repo" config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null || true)
}

setup_submodule_update_strategy() {
  local parent
  parent="$(dirname "$ZDOTDIR")"
  if [[ ! -e "$parent/.git" ]]; then
    return 0  # not inside a parent git repo — nothing to sync
  fi
  info "Syncing submodule update strategies from .gitmodules..."
  _sync_update_recursive "$parent"
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

  if [[ "$PLATFORM" == "macos" ]]; then
    if ! command -v brew &>/dev/null && [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
      echo "    ○ Install Homebrew: https://brew.sh"
      echo "      (no further config needed — ~/.zprofile → lib/.zprofile will"
      echo "       pick it up automatically on next login shell)"
      echo ""
    else
      echo "    ○ Homebrew detected — loaded on login via ~/.zprofile symlink"
      echo "      (managed at: $ZDOTDIR/lib/.zprofile)"
      echo ""
    fi
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

  # ── Generate machine-local overrides (.zshrc.local) ──
  generate_zshrc_local

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

  # ── Sync submodule update strategy (.gitmodules → local .git/config) ──
  echo ""
  setup_submodule_update_strategy

  # ── Print Summary ──
  print_summary
}

main "$@"
