if [[ -r "$HOME/.runtime-guards" ]]; then
	source "$HOME/.runtime-guards"
	_prepend_runtime_guards
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Homebrew's paths are static on Apple Silicon. Avoid spawning brew during
# interactive startup and normalize paths after macOS path_helper.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
_remove_path_entry() {
	local entry="$1"
	PATH=":$PATH:"
	PATH="${PATH//":$entry:"/:}"
	PATH="${PATH#:}"
	PATH="${PATH%:}"
}
_global_path=""
for _path_entry in "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$HOME/.local/bin"; do
	_remove_path_entry "$_path_entry"
	_global_path="${_global_path}${_global_path:+:}$_path_entry"
done
if [[ -n "${IN_NIX_SHELL:-}" ]]; then
	export PATH="${PATH}${PATH:+:}$_global_path"
else
	export PATH="$_global_path${PATH:+:$PATH}"
fi
unset -f _remove_path_entry
unset _global_path _path_entry
export MANPATH="$HOMEBREW_PREFIX/share/man:${MANPATH#:}"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Load shared dotfiles
for file in ~/.{path,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file
[ -f ~/.secrets ] && source ~/.secrets

declare -F _prepend_runtime_guards >/dev/null && _prepend_runtime_guards

# Keep nested shells from accumulating entries added by the files above.
IFS=: read -r -a _path_entries <<< "$PATH"
_deduplicated_path=""
_append_unique_path() {
	local entry="$1"
	case ":$_deduplicated_path:" in
		*":$entry:"*) ;;
		*) _deduplicated_path="${_deduplicated_path}${_deduplicated_path:+:}$entry" ;;
	esac
}
if [[ -n "${IN_NIX_SHELL:-}" ]]; then
	for _path_entry in "${_path_entries[@]}"; do
		[[ "$_path_entry" == /nix/store/* ]] || continue
		_append_unique_path "$_path_entry"
	done
fi
for _path_entry in "${_path_entries[@]}"; do
	_append_unique_path "$_path_entry"
done
PATH="$_deduplicated_path"
export PATH
unset -f _append_unique_path
unset _path_entries _path_entry _deduplicated_path

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

_cached_shell_init starship-full.bash "$HOMEBREW_PREFIX/bin/starship" -- "$HOMEBREW_PREFIX/bin/starship" init bash --print-full-init
_cached_shell_init zoxide.bash "$HOMEBREW_PREFIX/bin/zoxide" -- "$HOMEBREW_PREFIX/bin/zoxide" init bash
unset -f _cached_shell_init _prepend_runtime_guards
