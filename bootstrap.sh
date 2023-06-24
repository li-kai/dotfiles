#!/usr/bin/env bash
OPTIND=1

# Check if we are in the right directory
cd "$(dirname "${BASH_SOURCE}")" || exit;

# Check if we have commited all changes
if [[ $(git status --porcelain) ]]; then
	echo "There are uncommited changes. Please commit or stash them before running this script."
	exit 1
fi

# Check if we are root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";

function linkIt() {
	FILES=$(
		find "$(pwd)" \
			-maxdepth 1 -type f \
			-not -path "*/.git/*" \
			-not -name .git \
			-not -name .DS_Store \
			-not -name "app_config" \
			-not -name "*.sh" \
			-not -name "*.md" \
			-not -name "*.txt" \
		2> /dev/null
	)
	for file in $FILES; do
		ln -sf "${file}" "${HOME}/$(basename "${file}")"
	done
	# copy folders in app_config to /Library/Application Support
	# because apps will overwrite the files in ~/Library/Application Support
	rsync --exclude ".DS_Store" -av --no-perms app_config/ ~/Library/Application\ Support/
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
