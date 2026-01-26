# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Native zsh completion setup
autoload -Uz compinit
compinit

# Completion settings
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'  # Case/hyphen insensitive
zstyle ':completion:*' menu select                      # Tab through completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completions
zstyle ':completion:*' special-dirs true                # Complete . and ..
zstyle ':completion:*' squeeze-slashes true             # Treat // as /
zstyle ':completion:*' group-name ''                    # Group completions by category
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'  # Category headers
LISTMAX=0                                               # Show all completions without asking

setopt AUTO_CD              # Type directory name to cd into it
setopt AUTO_PUSHD           # cd pushes onto directory stack
setopt PUSHD_IGNORE_DUPS    # No duplicates in directory stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
HIST_STAMPS="yyyy-mm-dd"
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_VERIFY               # Show command before executing from history
setopt SHARE_HISTORY             # Share history between sessions

setopt globdots                  # Include hidden files when globbing

# Load plugins from ~/.config/zsh/plugins/
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Direnv integration
eval "$(direnv hook zsh)"

# FNM (Fast Node Manager) configuration
eval "$(fnm env --shell zsh)"

# Auto-switch Node.js versions based on .nvmrc or .node-version files
autoload -U add-zsh-hook
load-nvmrc() {
  # Skip if direnv is active and handling the environment
  if [[ -n "$DIRENV_DIR" ]]; then
    return
  fi

  if [[ -f .nvmrc || -f .node-version ]]; then
    fnm use
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

eval "$(starship init zsh)"
function set_win_title(){
    echo -ne "\033]0; $(basename "$PWD") \007"
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

# Load Nix environment if available
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

if command -v uv &> /dev/null; then
	# License: CC0
	# https://github.com/astral-sh/uv/issues/8432#issuecomment-2453494736
	eval "$(uv generate-shell-completion zsh)"

	_uv_run_mod() {
			if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
					_arguments '*:filename:_files'
			else
					_uv "$@"
			fi
	}
		compdef _uv_run_mod uv
fi

# use homebrew curl and grep
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# End of LM Studio CLI section
export PATH="$HOME/.local/bin:$PATH"
