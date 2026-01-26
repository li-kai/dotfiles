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
	# Install starship prompt if not already installed
	if ! command -v starship &> /dev/null; then
		brew install starship
	fi

	# Initialize and update git submodules for zsh plugins
	git submodule update --init --recursive

	# Symlink files and directories
	local paths
	paths=()
	while read -r path; do
		paths+=("$path")
	done < <(
		find "$(pwd)" \
			-mindepth 1 \
			-maxdepth 1 \
			-not -name assets \
			-not -name .git \
			-not -name .DS_Store \
			-not -name "*.sh" \
			-not -name "*.md" \
			-not -name "*.txt" \
			2> /dev/null
	)
	for path in "${paths[@]}"; do
		relative_path=${path#"$(pwd)"/}
		if [[ "$relative_path" == .macos ]]; then
			# For .macos folder, symlink its contents directly to home
			for item in "$path"/*; do
				# Only symlink directories
				if [ -d "$item" ]; then
					target_name="$(basename "$item")"
					target_path="$HOME/$target_name"

					# Remove existing symlink or directory if it exists
					if [ -L "$target_path" ] || [ -e "$target_path" ]; then
						rm -rf "$target_path"
					fi

					ln -sfv "$item" "$target_path"
				fi
			done
		elif [[ "$relative_path" == .config ]]; then
			# For .config folder, symlink its contents to ~/.config/
			for item in "$path"/*; do
				target_name="$(basename "$item")"
				target_path="$HOME/.config/$target_name"

				source_path="$item"
				if [ -d "$item" ]; then
					source_path="$item/"
				fi

				# Remove existing symlink or file/directory if it exists
				if [ -L "$target_path" ] || [ -e "$target_path" ]; then
					rm -rf "$target_path"
				fi

				ln -sfv "$source_path" "$target_path"
			done
		else
			source_path="$path"
			if [ -d "$path" ]; then
				source_path="$path/"
			fi
			target_path="$HOME/$relative_path"

			# Remove existing symlink or file if it exists
			if [ -L "$target_path" ] || [ -e "$target_path" ]; then
				rm -rf "$target_path"
			fi

			ln -sfv "$source_path" "$target_path"
		fi
	done
}

while getopts "f" opt; do
	case "$opt" in
		f) FORCE=1 ;;
		*) echo "Usage: $0 [-f]" >&2
			echo "  -f    Force installation without confirmation" >&2
			echo "" >&2
			echo "For updating dotfiles and submodules, use: ./update.sh" >&2
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

echo ""
echo "Post-install steps:"
echo ""
echo "1. Edit .gitconfig.local in the dotfiles repo with your personal git settings:"
echo "   [user]"
echo "       name = Your Name"
echo "       email = your@email.com"
echo "       signingkey = /path/to/your/key.pub"
echo "   (This file is gitignored and symlinked to ~/.gitconfig.local)"
echo ""
echo "2. Download Efficient Compression Tool (ect):"
echo "   https://github.com/fhanau/Efficient-Compression-Tool/releases"
echo "   sudo mv ~/Downloads/ect /usr/local/bin/"
echo ""

source ~/.bash_profile
unset linkIt

echo "Done. Reload your terminal to see the changes."
