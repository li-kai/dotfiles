#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install it from https://brew.sh/"
    exit 1
fi

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Install `wget`
brew install wget

# Install more recent versions of some macOS tools.
brew install vim

# Development Tools
brew install git
brew install git-lfs
brew install gnupg
brew install direnv
brew install vim
brew install tmux
brew install htop
brew install tree
brew install jq
brew install yq
brew install uv

# CLI Improvements
brew install zoxide
brew install bat
brew install eza
brew install fzf
brew install ripgrep

# Image Processing
brew install gs
brew install imagemagick

# Applications
## Pro-tip: Never install electron apps, just use the web version.

## Browsers
brew install --cask firefox
brew install --cask firefox@developer-edition
brew install --cask google-chrome
brew install --cask microsoft-edge

## Productivity
brew install --cask rectangle
brew install --cask raycast
brew install --cask obsidian
brew install --cask bitwarden
brew install --cask shottr
brew install --cask screen-studio

# Mouse Improvements
brew install --cask sanesidebuttons

## Media
brew install --cask vlc
brew install --cask spotify

## Development
brew install --cask visual-studio-code
brew install --cask docker
brew install --cask iterm2
brew install --cask cursor
brew install --cask zed
brew install --cask ollama

# Remove outdated versions from the cellar.
brew cleanup
