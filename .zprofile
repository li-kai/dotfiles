# /etc/zprofile runs path_helper first, so restore the path captured by .zshenv.
if [[ -n "${_nix_shell_path:-}" ]]; then
	export PATH="$_nix_shell_path"
fi
(( $+functions[_prepend_runtime_guards] )) && _prepend_runtime_guards
