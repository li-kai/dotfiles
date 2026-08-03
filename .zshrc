# Homebrew's paths are static on Apple Silicon. Avoid spawning brew during
# interactive startup and normalize paths after macOS path_helper.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
typeset -U path PATH
_global_paths=(
	"$HOME/.local/bin"
	"/opt/homebrew/opt/grep/libexec/gnubin"
	"/opt/homebrew/opt/coreutils/libexec/gnubin"
	"/opt/homebrew/opt/curl/bin"
	"$HOMEBREW_PREFIX/bin"
	"$HOMEBREW_PREFIX/sbin"
)
if [[ -n "${IN_NIX_SHELL:-}" ]]; then
	path=($path $_global_paths)
else
	path=($_global_paths $path)
fi
unset _global_paths
export MANPATH="$HOMEBREW_PREFIX/share/man:${MANPATH#:}"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Load shell dotfiles early — EDITOR, LANG, etc. must be set before tool init
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don't want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Load secrets (API keys etc.) — not committed to git
[ -f ~/.secrets ] && source ~/.secrets

# Restore the inherited development environment ahead of global PATH additions.
if [[ -n "${_nix_shell_path:-}" ]]; then
	path=(${(s.:.)_nix_shell_path} $path)
	unset _nix_shell_path
fi

# Use emacs keybindings
bindkey -e

# Load completion system
autoload -Uz compinit
_zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

if (( $+commands[uv] )); then
	_uv_completion_dir="$_zsh_cache_dir/completions"
	_uv_cache="$_uv_completion_dir/_uv"
	if [[ ! -s "$_uv_cache" || "$commands[uv]" -nt "$_uv_cache" ]]; then
		[[ -d "$_uv_completion_dir" ]] || mkdir -p "$_uv_completion_dir"
		_uv_temporary="$_uv_cache.$$"
		if uv generate-shell-completion zsh >| "$_uv_temporary" && [[ -s "$_uv_temporary" ]]; then
			mv -f "$_uv_temporary" "$_uv_cache"
		else
			rm -f "$_uv_temporary"
		fi
	fi
	[[ -s "$_uv_cache" ]] && fpath=("$_uv_completion_dir" $fpath)
fi

typeset -U fpath FPATH
[[ -d "$_zsh_cache_dir" ]] || mkdir -p "$_zsh_cache_dir"
_zcompdump="$_zsh_cache_dir/zcompdump"
_rebuild_completions=false
_expired_zcompdump=(${~_zcompdump}(Nmh+24))
if [[ ! -s "$_zcompdump" ]] || (( ${#_expired_zcompdump} )); then
  _rebuild_completions=true
else
  for _completion_dir in $fpath; do
    if [[ "$_completion_dir" -nt "$_zcompdump" ]]; then
      _rebuild_completions=true
      break
    fi
  done
fi

if $_rebuild_completions; then
  # Rebuild daily or when installed completion directories change.
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zsh_cache_dir _zcompdump _expired_zcompdump _rebuild_completions _completion_dir

if (( $+commands[uv] )); then
	_uv_run_mod() {
		if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
			_arguments '*:filename:_files'
		else
			_uv "$@"
		fi
	}
	compdef _uv_run_mod uv
	unset _uv_cache _uv_completion_dir _uv_temporary
fi

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
autoload -Uz select-word-style && select-word-style bash
WORDCHARS='*?[]~&;!#$%^(){}<>'

# Initialize fzf before fzf-tab so fzf-tab retains the Tab binding.
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git' --glob '!.DS_Store'"
export FZF_DEFAULT_OPTS="--height 40% --tmux bottom,40% --layout=reverse"
FZF_ALT_C_COMMAND= _cached_shell_init fzf.zsh "$commands[fzf]" -- "$commands[fzf]" --zsh

# Load plugins from ~/.config/zsh/plugins/
source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History substring search - standard mode only
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Direnv integration
_cached_shell_init direnv.zsh "$commands[direnv]" -- "$commands[direnv]" hook zsh

autoload -U add-zsh-hook

# Background git fetch on cd into repo (smart throttling)
auto_git_fetch() {
  local git_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null) || return
  local fetch_head="$git_dir/FETCH_HEAD"
  # Only fetch if FETCH_HEAD doesn't exist or is older than 60 minutes
  if [[ ! -f "$fetch_head" ]] || [[ -n $(find "$fetch_head" -mmin +60 2>/dev/null) ]]; then
    (git fetch --quiet &)
  fi
}
add-zsh-hook chpwd auto_git_fetch

# Use minimal prompt in vscode/cursor integrated terminal
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-minimal.toml"
fi
_starship_config="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
if [[ -n "$STARSHIP_CONFIG" ]]; then
  _starship_cache=starship-minimal.zsh
else
  _starship_cache=starship.zsh
fi
_starship_init_zsh() {
  local starship="$1" continuation init line
  continuation="$("$starship" prompt --continuation)" || return
  init="$("$starship" init zsh)" || return
  while IFS= read -r line; do
    if [[ "$line" == PROMPT2=* ]]; then
      print -r -- "PROMPT2=${(qqq)continuation}"
    else
      print -r -- "$line"
    fi
  done <<< "$init"
}
_cached_shell_init "$_starship_cache" "$commands[starship]" "$_starship_config" -- _starship_init_zsh "$commands[starship]"
unfunction _starship_init_zsh
unset _starship_cache _starship_config
function prompt_precmd() {
    printf '\e]0; %s \a' "${PWD:t}"
    (( RANDOM % 20 )) || _shell_tip
}
add-zsh-hook precmd prompt_precmd

_cached_shell_init zoxide.zsh "$commands[zoxide]" -- "$commands[zoxide]" init zsh
unfunction _cached_shell_init

# Load Nix environment if available.
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# Keep profile-level Nix tools behind an active development shell.
for _nixbin in "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin; do
  if [ -d "$_nixbin" ]; then
    path=(${path:#$_nixbin})
    if [[ -n "${IN_NIX_SHELL:-}" ]]; then
      path=($path "$_nixbin")
    else
      path=("$_nixbin" $path)
    fi
  fi
done
unset _nixbin

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kai/.lmstudio/bin"
# End of LM Studio CLI section

# Re-promote guards after startup PATH changes; Nix shells remain exempt.
if (( $+functions[_prepend_runtime_guards] )); then
	_prepend_runtime_guards
	unfunction _prepend_runtime_guards
fi
