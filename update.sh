#!/usr/bin/env bash

# Update script for dotfiles and submodules
# This script safely updates the dotfiles repository and all submodules

set -e

# Check if we are in the right directory
if [ ! -f "bootstrap.sh" ]; then
	echo "Error: This script must be run from the dotfiles repository root."
	exit 1
fi

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
	echo "Warning: You have uncommitted changes. Please commit or stash them before updating."
	echo "Run 'git status' to see what files have changed."
	echo ""
	echo "To stash your changes: git stash"
	echo "To commit your changes: git add . && git commit -m 'Your message'"
	exit 1
fi

echo "Updating dotfiles and submodules..."

# Update the main repository
echo "Pulling latest changes from main repository..."
git pull --recurse-submodules

# Update all submodules to their latest versions
echo "Updating submodules to latest versions..."
git submodule update --remote --recursive

# Check if any submodules were updated
if [[ $(git status --porcelain) ]]; then
	echo ""
	echo "Submodules have been updated. You may want to commit these changes:"
	echo "  git add .gitmodules .config/zsh/plugins/"
	echo "  git commit -m 'Update submodules to latest versions'"
	echo ""
	echo "Current submodule status:"
	git submodule status
fi

echo ""
echo "Update complete!"
echo "You may need to reload your terminal to see any changes."
