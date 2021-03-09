#!/usr/bin/env bash
OPTIND=1

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

function doIt() {
	rsync --exclude ".git/" --exclude ".DS_Store" --exclude "*.sh" --exclude "*.md" --exclude "*.txt" \
		-av --dry-run --no-perms . ~
}
function linkIt() {
	FILES=$(find "$(pwd)" -not -path "*/.git/*" -not -name .git -not -name .DS_Store -not -name "*.sh" -not -name "*.md" -not -name "*.txt")
	for file in $FILES; do
		ln -sf ${file} ~/$(basename ${file})
	done
}

while getopts "fl" opt; do
	case "$opt" in
		f)
			FORCE=1
			;;
		l)
			LINK=1
			;;
	esac
done

if [ "$FORCE" == "1" ]; then
	if [ "$LINK" == "1" ]; then
		linkIt
	else
		doIt
	fi
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		if [ "$LINK" == "1" ]; then
			linkIt
		else
			doIt
		fi
	fi
fi
source ~/.bash_profile
unset doIt
