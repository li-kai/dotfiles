# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Additional PATH entries (before tools that depend on them)
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Use emacs keybindings
bindkey -e

# Load completion system
autoload -Uz compinit

if [[ -n $(print ~/.zcompdump(Nmh+24)) ]] {
  # Regenerate completions because the dump file hasn't been modified within the last 24 hours
  compinit
} else {
  # Reuse the existing completions file
  compinit -C
}

# Completion settings
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'  # Case/hyphen insensitive
zstyle ':completion:*' menu select                      # Tab through completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completions
zstyle ':completion:*' special-dirs true                # Complete . and ..
zstyle ':completion:*' squeeze-slashes true             # Treat // as /
zstyle ':completion:*' group-name ''                    # Group completions by category
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'  # Category headers
LISTMAX=0                                               # Show all completions without asking

# Enhanced completions
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 2 numeric
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

setopt AUTO_CD              # Type directory name to cd into it
setopt AUTO_PUSHD           # cd pushes onto directory stack
setopt PUSHD_IGNORE_DUPS    # No duplicates in directory stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming history
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate when new one is added
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_VERIFY               # Show command before executing from history
setopt INC_APPEND_HISTORY        # Append immediately to file
setopt HIST_FCNTL_LOCK           # Better locking for concurrent access
setopt HIST_FIND_NO_DUPS         # Don't show dupes when searching history
setopt HIST_REDUCE_BLANKS        # Remove extra whitespace from history entries

setopt globdots                  # Include hidden files when globbing
setopt EXTENDED_GLOB             # Extended globbing: ^ ~ # operators
setopt CORRECT                   # Suggest corrections for typos
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f? [n]o [y]es [a]bort [e]dit: '

# Word handling - Ctrl+W stops at path separators
WORDCHARS='*?[]~&;!#$%^(){}<>'
autoload -Uz select-word-style && select-word-style bash

# Load plugins from ~/.config/zsh/plugins/
source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History substring search - standard mode only
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Direnv integration
eval "$(direnv hook zsh)"

# FNM (Fast Node Manager) configuration
# Skip fnm initialization inside nix-shell (nix sets TMPDIR to a path containing "nix-shell")
if [[ "$TMPDIR" != *nix-shell* ]]; then
  eval "$(fnm env --shell zsh)"
fi

# Auto-switch Node.js versions based on .nvmrc or .node-version files
autoload -U add-zsh-hook
load-nvmrc() {
  # Skip if direnv is active or will handle the environment (via .envrc or flake.nix)
  if [[ -n "$DIRENV_DIR" ]] || [[ -f .envrc ]] || [[ -f flake.nix ]]; then
    return
  fi

  if [[ -f .nvmrc || -f .node-version ]]; then
    fnm use
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Auto-activate Python venv
auto_venv() {
  if [[ -n "$VIRTUAL_ENV" ]] && [[ ! "$PWD" == "${VIRTUAL_ENV%/*}"* ]]; then
    deactivate 2>/dev/null
  fi
  if [[ -z "$VIRTUAL_ENV" ]]; then
    if [[ -f .venv/bin/activate ]]; then
      source .venv/bin/activate
    elif [[ -f venv/bin/activate ]]; then
      source venv/bin/activate
    fi
  fi
}
add-zsh-hook chpwd auto_venv

# Background git fetch on cd into repo (smart throttling)
auto_git_fetch() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local fetch_head=".git/FETCH_HEAD"
    # Only fetch if FETCH_HEAD doesn't exist or is older than 60 minutes
    if [[ ! -f "$fetch_head" ]] || [[ -n $(find "$fetch_head" -mmin +60 2>/dev/null) ]]; then
      (git fetch --quiet &)
    fi
  fi
}
add-zsh-hook chpwd auto_git_fetch

# Use minimal prompt in vscode/cursor integrated terminal
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-minimal.toml"
fi
eval "$(starship init zsh)"
function set_win_title(){
    echo -ne "\033]0; ${PWD:t} \007"
}
starship_precmd_user_func="set_win_title"

eval "$(zoxide init zsh)"                 # enable zoxide
export FZF_DEFAULT_COMMAND="rg"
export FZF_DEFAULT_OPTS="--height 40% --tmux bottom,40% --layout=reverse"
FZF_ALT_C_COMMAND= source <(fzf --zsh)    # enable fzf

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don't want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Load secrets (API keys etc.) — not committed to git
[ -f ~/.secrets ] && source ~/.secrets

# Load Nix environment if available
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

if command -v uv &> /dev/null; then
	# License: CC0
	# https://github.com/astral-sh/uv/issues/8432#issuecomment-2453494736
	_uv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/uv_completions.zsh"
	if [[ ! -f "$_uv_cache" || "$(command -v uv)" -nt "$_uv_cache" ]]; then
		uv generate-shell-completion zsh > "$_uv_cache"
	fi
	source "$_uv_cache"

	_uv_run_mod() {
			if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
					_arguments '*:filename:_files'
			else
					_uv "$@"
			fi
	}
	compdef _uv_run_mod uv
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kai/.lmstudio/bin"
# End of LM Studio CLI section

