#!/usr/bin/env bash

# Install command-line tools using Homebrew.

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

# Switch to using brew-installed bash as default shell
if ! grep -F -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;

# Install `wget`
brew install wget

# Install more recent versions of some macOS tools.
brew install vim

# Install other useful binaries.
brew install git
brew install git-lfs
brew install gs
brew install imagemagick
brew install zoxide
brew install bat
brew install eza
brew install fzf
brew install ripgrep
brew install direnv

brew tap homebrew/cask

# Pro-tip: Never install electron apps, just use the web version.
brew install --cask rectangle
brew install --cask firefox
brew install --cask google-chrome
brew install --cask microsoft-edge
brew install --cask vlc
brew install --cask spotify

# Install dev tools
brew install --cask visual-studio-code
brew install --cask docker
brew install --cask iterm2

# Install fonts
brew tap homebrew/cask-fonts
brew install font-inter

# Remove outdated versions from the cellar.
brew cleanup
