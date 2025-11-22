         1 +  #!/usr/bin/env zsh
         2 +  # Optimized plugin manager for ZSH - Performance focused version
         3 +  # Based on plugin_manager.zsh but with major optimizations
         4 +  # Usage: Source this instead of plugin_manager.zsh for faster boot times
         5 +
         6 +  # Performance mode flag - set to true for minimal logging
         7 +  ZSH_PERF_MODE="${ZSH_PERF_MODE:-false}"
         8 +
         9 +  # Clean start - delete previous session logs (same as original)
        10 +  [[ -f "$ZLOGDIR/plugin-manager.zlog" ]] && rm -f "$ZLOGDIR/plugin-manager.zlog"
        11 +
        12 +  # Simplified logging function for performance mode
        13 +  perf_log() {
        14 +      [[ "$ZSH_PERF_MODE" == "true" ]] && return 0
        15 +      [[ -n "$ZUTILS" && -x "$ZUTILS/zshlog" ]] && "$ZUTILS/zshlog" -f "plugin-manager.zlog" "$@"
        16 +  }
        17 +
        18 +  # Optimized git clone with minimal logging and better error handling
        19 +  git_clone_fast() {
        20 +      [[ $# -lt 2 ]] && { echo "Usage: git_clone_fast <repo> <dest>"; return 1; }
        21 +
        22 +      local repo="$1" dest="$2"
        23 +
        24 +      perf_log -n "Cloning $repo → $dest"
        25 +
        26 +      # Use GitHub's faster SSH protocol and minimal clone options
        27 +      if git clone --depth=1 --single-branch --quiet "git@github.com:${repo}.git" "$dest" 2>/dev/null; then
        28 +          return 0
        29 +      else
        30 +          perf_log --error "Failed to clone $repo"
        31 +          return 1
        32 +      fi
        33 +  }
        34 +
        35 +  # Highly optimized file sourcing - removes ALL formatting overhead
        36 +  zsh_add_file_fast() {
        37 +      # Simple existence check and source - no logging overhead
        38 +      [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1" && {
        39 +          perf_log --log "File $1 sourced"
        40 +          return 0
        41 +      }
        42 +      return 1
        43 +  }
        44 +
        45 +  # Optimized plugin loading with better logic and caching
        46 +  zsh_add_plugin_fast() {
        47 +      local repo="$1"
        48 +      local plugin_name="${repo##*/}"
        49 +      local plugin_path="$ZDOTDIR/plugins/$plugin_name"
        50 +
        51 +      # Clone if needed (only once)
        52 +      [[ ! -d "$plugin_path" ]] && git_clone_fast "$repo" "$plugin_path"
        53 +
        54 +      # Try to source plugin files - check most common patterns first
        55 +      local plugin_files=(
        56 +          "plugins/$plugin_name/$plugin_name.plugin.zsh"
        57 +          "plugins/$plugin_name/$plugin_name.zsh"
        58 +          "plugins/$plugin_name/init.zsh"
        59 +          "plugins/$plugin_name/${plugin_name}.plugin.zsh"
        60 +      )
        61 +
        62 +      for file in "${plugin_files[@]}"; do
        63 +          if zsh_add_file_fast "$file"; then
        64 +              return 0
        65 +          fi
        66 +      done
        67 +
        68 +      perf_log --error "Couldn't source plugin: $plugin_name"
        69 +      return 1
        70 +  }
        71 +
        72 +  # Optimized completion loading with smart batching
        73 +  zsh_add_completion_fast() {
        74 +      local repo="$1"
        75 +      local do_compinit="${2:-false}"
        76 +      local plugin_name="${repo##*/}"
        77 +      local plugin_path="$ZDOTDIR/plugins/$plugin_name"
        78 +
        79 +      # Clone if needed
        80 +      [[ ! -d "$plugin_path" ]] && git_clone_fast "$repo" "$plugin_path"
        81 +
        82 +      # Add completion files to fpath efficiently - batch operation
        83 +      if [[ -d "$plugin_path" ]]; then
        84 +          local completion_files=("$plugin_path"/_*)
        85 +          [[ ${#completion_files[@]} -gt 0 && -e "${completion_files[1]}" ]] && {
        86 +              fpath=("$plugin_path" $fpath)
        87 +              perf_log --log "Added $plugin_name completions"
        88 +          }
        89 +      fi
        90 +
        91 +      # Source main plugin file
        92 +      zsh_add_file_fast "plugins/$plugin_name/$plugin_name.plugin.zsh"
        93 +
        94 +      # Smart compinit - only run once per session
        95 +      if [[ "$do_compinit" == "true" && ! -f "$ZDOTDIR/.compinit_done" ]]; then
        96 +          zsh_compinit_once
        97 +          touch "$ZDOTDIR/.compinit_done"
        98 +      fi
        99 +  }
       100 +
       101 +  # Optimized compinit with caching
       102 +  zsh_compinit_once() {
       103 +      # Skip security checks for speed (-C flag)
       104 +      autoload -Uz compinit && compinit -C
       105 +      perf_log --log "Fast completion init completed"
       106 +  }
       107 +
       108 +  # Batch plugin loading function - load multiple plugins efficiently
       109 +  batch_load_plugins() {
       110 +      local plugins=("$@")
       111 +
       112 +      perf_log -n "Batch loading ${#plugins[@]} plugins"
       113 +
       114 +      local failed_plugins=()
       115 +      local loaded_count=0
       116 +
       117 +      for plugin in "${plugins[@]}"; do
       118 +          if zsh_add_plugin_fast "$plugin"; then
       119 +              ((loaded_count++))
       120 +          else
       121 +              failed_plugins+=("$plugin")
       122 +          fi
       123 +      done
       124 +
       125 +      if [[ ${#failed_plugins[@]} -gt 0 ]]; then
       126 +          perf_log --error "Failed plugins: ${failed_plugins[*]}"
       127 +      fi
       128 +
       129 +      perf_log --log "Loaded $loaded_count/${#plugins[@]} plugins"
       130 +  }
       131 +
       132 +  # Optimized PATH export function with deduplication and batching
       133 +  export_path_batch() {
       134 +      local new_paths=()
       135 +      local path_count=0
       136 +
       137 +      # Collect all valid new paths
       138 +      for path in "$@"; do
       139 +          # Expand tilde and remove trailing slash
       140 +          path="${path/#\~/$HOME}"
       141 +          path="${path%/}"
       142 +
       143 +          # Only add if directory exists and not already in PATH
       144 +          if [[ -d "$path" && ":$PATH:" != *":$path:"* ]]; then
       145 +              new_paths+=("$path")
       146 +              ((path_count++))
       147 +          fi
       148 +      done
       149 +
       150 +      # Batch export if we have new paths
       151 +      if [[ $path_count -gt 0 ]]; then
       152 +          local IFS=':'
       153 +          PATH="${new_paths[*]}:$PATH"
       154 +          perf_log --log "Batch added $path_count paths to PATH"
       155 +      fi
       156 +  }
       157 +
       158 +  # Performance monitoring functions
       159 +  perf_start_timer() {
       160 +      PERF_START_TIME=$EPOCHREALTIME
       161 +  }
       162 +
       163 +  perf_stop_timer() {
       164 +      local end_time=$EPOCHREALTIME
       165 +      local duration=$((end_time - PERF_START_TIME))
       166 +      printf "%.3f" $duration
       167 +  }
       168 +
       169 +  # Async plugin loading for non-critical plugins
       170 +  load_plugins_async() {
       171 +      local plugins=("$@")
       172 +      {
       173 +          for plugin in "${plugins[@]}"; do
       174 +              zsh_add_plugin_fast "$plugin" &>/dev/null
       175 +          done
       176 +          perf_log --log "Async loaded ${#plugins[@]} plugins"
       177 +      } &!
       178 +  }
       179 +
       180 +  # Critical plugins that must load synchronously
       181 +  load_critical_plugins() {
       182 +      local critical_plugins=(
       183 +          "zsh-users/zsh-syntax-highlighting"
       184 +          "zsh-users/zsh-autosuggestions"
       185 +          "zsh-users/zsh-history-substring-search"
       186 +      )
       187 +
       188 +      perf_log -n "Loading critical plugins"
       189 +      batch_load_plugins "${critical_plugins[@]}"
       190 +  }
       191 +
       192 +  # Optional plugins that can load asynchronously
       193 +  load_optional_plugins_async() {
       194 +      local optional_plugins=(
       195 +          "zsh-users/zsh-completions"
       196 +          "Aloxaf/fzf-tab"
       197 +          "smnuman/zsh-history-search-end-match"
       198 +          "supercrabtree/k"
       199 +      )
       200 +
       201 +      perf_log -n "Loading optional plugins async"
       202 +      load_plugins_async "${optional_plugins[@]}"
       203 +  }
       204 +
       205 +  # Quick performance test for this optimized version
       206 +  test_optimized_performance() {
       207 +      echo "🚀 Testing optimized plugin manager performance..."
       208 +
       209 +      # Test optimized file loading
       210 +      perf_start_timer
       211 +      zsh_add_file_fast "zsh-aliases" >/dev/null 2>&1
       212 +      local file_time=$(perf_stop_timer)
       213 +
       214 +      # Test batch PATH exports
       215 +      perf_start_timer
       216 +      export_path_batch "$ZDOTDIR/test1" "$ZDOTDIR/test2" "$ZDOTDIR/test3"
       217 +      local path_time=$(perf_stop_timer)
       218 +
       219 +      printf "Optimized file loading: %.3fs\n" $file_time
       220 +      printf "Optimized PATH exports: %.3fs\n" $path_time
       221 +  }
       222 +
       223 +  # Enable optimized mode - replaces original functions
       224 +  enable_optimized_mode() {
       225 +      echo "🚀 Enabling optimized plugin manager..."
       226 +
       227 +      # Create backup of current functions if they exist
       228 +      [[ $(type zsh_add_file 2>/dev/null) ]] && eval "zsh_add_file_backup() { $(declare -f zsh_add_file | tail -n +2) }"
       229 +      [[ $(type zsh_add_plugin 2>/dev/null) ]] && eval "zsh_add_plugin_backup() { $(declare -f zsh_add_plugin | tail -n +2) }"
       230 +      [[ $(type git_clone 2>/dev/null) ]] && eval "git_clone_backup() { $(declare -f git_clone | tail -n +2) }"
       231 +
       232 +      # Replace with optimized versions
       233 +      eval "zsh_add_file() { zsh_add_file_fast \"\$@\"; }"
       234 +      eval "zsh_add_plugin() { zsh_add_plugin_fast \"\$@\"; }"
       235 +      eval "zsh_add_completion() { zsh_add_completion_fast \"\$@\"; }"
       236 +      eval "git_clone() { git_clone_fast \"\$@\"; }"
       237 +
       238 +      # Set performance mode
       239 +      export ZSH_PERF_MODE=true
       240 +
       241 +      echo "✅ Optimized mode enabled"
       242 +      echo "📊 Run 'test_optimized_performance' to test performance"
       243 +  }
       244 +
       245 +  # Disable optimized mode and restore originals
       246 +  disable_optimized_mode() {
       247 +      echo "🔄 Disabling optimized mode..."
       248 +
       249 +      # Restore original functions if available
       250 +      [[ $(type zsh_add_file_backup 2>/dev/null) ]] && eval "zsh_add_file() { $(declare -f zsh_add_file_backup | tail -n +2) }"
       251 +      [[ $(type zsh_add_plugin_backup 2>/dev/null) ]] && eval "zsh_add_plugin() { $(declare -f zsh_add_plugin_backup | tail -n +2) }"
       252 +      [[ $(type git_clone_backup 2>/dev/null) ]] && eval "git_clone() { $(declare -f git_clone_backup | tail -n +2) }"
       253 +
       254 +      export ZSH_PERF_MODE=false
       255 +      echo "✅ Optimized mode disabled"
       256 +  }
       257 +
       258 +  # Initialize optimized mode by default when this file is sourced
       259 +  perf_log --log "Plugin manager optimized version loaded"
       260 +  echo "💡 Use 'enable_optimized_mode' to activate performance optimizations"
