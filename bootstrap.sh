#!/usr/bin/env bash
OPTIND=1

# Check if we are in the right directory
cd "$(dirname "${BASH_SOURCE}")" || exit;

# Check if we have commited all changes
if [[ $(git status --porcelain) ]]; then
	echo "There are uncommited changes. Please commit or stash them before running this script."
	exit 1
fi

# Ask for the administrator password upfront
sudo -v

function linkIt() {
	# Install oh-my-zsh
	if [ ! -d "${HOME}/.oh-my-zsh" ]; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
		ZSH_CUSTOM="${HOME}/.omz"
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
		git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
		git clone https://github.com/geometry-zsh/geometry "${ZSH_CUSTOM}/themes/geometry"
	fi

	# Symlink files and directories
	local paths
	paths=$(
		find "$(pwd)" \
			-mindepth 1 \
			-maxdepth 1 \
			-not -name .macos \
			-not -name .git \
			-not -name .DS_Store \
			-not -name "*.sh" \
			-not -name "*.md" \
			-not -name "*.txt" \
		2> /dev/null
	)
	for path in $paths; do
		relative_path=${path#"$(pwd)"/}
		ln -sfv "$path" "$HOME/$relative_path"
	done
}

while getopts "fl" opt; do
	case "$opt" in
		f) FORCE=1 ;;
		*) echo "Usage: $0 [-f]" >&2
			exit 1 ;;
	esac
done

if [ "$FORCE" == "1" ]; then
	linkIt
else
	read -r -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		linkIt
	fi
fi

source ~/.bash_profile
unset linkIt
