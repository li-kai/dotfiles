# Preserve Nix precedence across macOS path_helper and guard selected runtimes.
if [[ -n "${IN_NIX_SHELL:-}" ]]; then
	_nix_shell_path="$PATH"
fi
if [[ -z "${IN_NIX_SHELL:-}" && -r "$HOME/.runtime-guards" ]]; then
	source "$HOME/.runtime-guards"
	_prepend_runtime_guards
fi
