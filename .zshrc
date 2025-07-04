# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_CUSTOM=$HOME/.omz

ZSH_THEME="geometry/geometry"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    direnv
    nvm
    rust
    zsh-autosuggestions
    zsh-syntax-highlighting
)

setopt globdots                        # include hidden files when globbing
zstyle ':omz:update' mode auto         # update automatically without asking
zstyle ':omz:update' frequency 11      # check for updates every 11 days
zstyle ':omz:plugins:nvm' lazy yes     # load nvm when calling `node`, etc.

source $ZSH/oh-my-zsh.sh;
unset plugins;

eval "$(/opt/homebrew/bin/brew shellenv)" # enable brew
eval "$(zoxide init zsh)"                 # enable zoxide
export FZF_DEFAULT_COMMAND="rg"
export FZF_DEFAULT_OPTS="--height 40% --tmux bottom,40% --layout=reverse"
FZF_ALT_C_COMMAND= source <(fzf --zsh)    # enable fzf

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
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
