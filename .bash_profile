# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# Load shared dotfiles
for file in ~/.{path,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file
[ -f ~/.secrets ] && source ~/.secrets

# Bash-specific history
HISTSIZE=5000
HISTFILESIZE=5000
HISTCONTROL=ignoreboth
shopt -s histappend nocaseglob cdspell checkwinsize

for option in autocd globstar; do
	shopt -s "$option" 2>/dev/null
done

# Tab completion for git alias
if type _git &>/dev/null; then
	complete -o default -o nospace -F _git g
fi

eval "$(starship init bash)"
eval "$(zoxide init bash)"
