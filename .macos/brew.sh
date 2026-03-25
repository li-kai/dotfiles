#!/usr/bin/env bash

# Install command-line tools using Homebrew.

if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install it from https://brew.sh/"
    exit 1
fi

brew update
brew upgrade

# Install everything from the Brewfile
brew bundle --file="$(dirname "${BASH_SOURCE[0]}")/../Brewfile"

# Create sha256sum symlink for coreutils
BREW_PREFIX=$(brew --prefix)
ln -sf "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

brew cleanup
