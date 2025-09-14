# Kai's dotfiles

![Screenshot of my shell prompt](/assets/screenshot.png)

## Overview

This repository contains my personal dotfiles, forked from [Mathias Bynens](https://mathiasbynens.be/)' [dotfiles repository](https://github.com/mathiasbynens/dotfiles). Here's what differs from the original:

- Zsh is used instead of Bash
- `bootstrap.sh` symlinks instead of copying files
- `update.sh` for safely updating dotfiles and submodules
- [Rectangle](https://github.com/rxhanson/Rectangle) is used instead of [Spectacle](https://www.spectacleapp.com/)
- macOS defaults/aliases/functions are different
- Rust cli alternatives (eza, bat, ripgrep, etc.) are preferred over GNU coreutils
- Oh-my-zsh plugins and themes managed as git submodules for version control

## Installation

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don't want or need. Don't blindly use my settings unless you know what that entails. Use at your own risk!

### First-time setup

```sh
git clone --recurse-submodules git@github.com:li-kai/dotfiles.git && cd dotfiles && ./bootstrap.sh
```

**Important:** Always use `--recurse-submodules` when cloning to ensure all oh-my-zsh plugins and themes are properly initialized.

### If you already cloned without submodules

If you've already cloned the repository without the `--recurse-submodules` flag, initialize the submodules:

```sh
git submodule update --init --recursive
./bootstrap.sh
```

### Git Configuration for Submodules

To ensure submodules are automatically updated when you pull changes, configure git globally:

```sh
git config --global submodule.recurse true
git config --global diff.submodule log
```

This makes `git pull` automatically update submodules and shows meaningful diffs for submodule changes.

### Troubleshooting Submodules

If you encounter issues with submodules:

**Check submodule status:**

```sh
git submodule status
```

**Reset submodules to their tracked commits:**

```sh
git submodule update --init --recursive
```

**Update submodules to latest versions:**

```sh
git submodule update --remote --recursive
```

**If submodules appear as modified when they shouldn't be:**

```sh
git submodule foreach git reset --hard HEAD
```

### Specify the `$PATH`

If `~/.path` exists, it will be sourced along with the other files, before any feature testing (such as [detecting which version of `ls` is being used](https://github.com/mathiasbynens/dotfiles/blob/aff769fd75225d8f2e481185a71d5e05b76002dc/.aliases#L21-L26)) takes place.

Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```sh
export PATH="/usr/local/bin:$PATH"
```

### Add custom commands without creating a new fork

If `~/.extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.

Your `~/.extra` should look something like this:

```sh
# Git credentials
# Not in the repository, to prevent people from accidentally committing under my name
GIT_AUTHOR_NAME="Mathias Bynens"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="mathias@mailinator.com"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"
```

You could also use `~/.extra` to override settings, functions and aliases from my dotfiles repository. It’s probably better to [fork this repository](https://github.com/li-kai/dotfiles/fork) instead, though.

### Sensible macOS defaults

When setting up a new Mac, you may want to set some sensible macOS defaults:

```sh
./.macos/settings.sh
```

### Install Homebrew formulae

When setting up a new Mac, you may want to install some common [Homebrew](https://brew.sh/) formulae (after installing Homebrew, of course):

```sh
./.macos/brew.sh
```

Some of the functionality of these dotfiles depends on formulae installed by `brew.sh`. If you don't plan to run `brew.sh`, you should look carefully through the script and manually install any particularly important ones. A good example is Bash/Git completion: the dotfiles use a special version from Homebrew.

## Updating Everything

To update your dotfiles and all submodules to the latest versions:

```sh
./update.sh
```

This script will:

- Check for uncommitted changes (safety check)
- Pull latest changes from the main repository
- Update all submodules to their latest versions
- Show you if any submodules were updated

Or manually update everything:

```sh
git pull --recurse-submodules
git submodule update --remote --recursive
```

### Troubleshooting Submodules

If you encounter issues with submodules:

**Check submodule status:**

```sh
git submodule status
```

**Reset submodules to their tracked commits:**

```sh
git submodule update --init --recursive
```

**Update submodules to latest versions:**

```sh
git submodule update --remote --recursive
```

**If submodules appear as modified when they shouldn't be:**

```sh
git submodule foreach git reset --hard HEAD
```

## Thanks to…

- [Mathias Bynens](https://mathiasbynens.be/) and his [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
- @ptb and [his _macOS Setup_ repository](https://github.com/ptb/mac-setup)
- [Ben Alman](http://benalman.com/) and his [dotfiles repository](https://github.com/cowboy/dotfiles)
- [Cătălin Mariș](https://github.com/alrra) and his [dotfiles repository](https://github.com/alrra/dotfiles)
- [Gianni Chiappetta](https://butt.zone/) for sharing his [amazing collection of dotfiles](https://github.com/gf3/dotfiles)
- [Jan Moesen](http://jan.moesen.nu/) and his [ancient `.bash_profile`](https://gist.github.com/1156154) + [shiny _tilde_ repository](https://github.com/janmoesen/tilde)
- Lauri ‘Lri’ Ranta for sharing [loads of hidden preferences](https://web.archive.org/web/20161104144204/http://osxnotes.net/defaults.html)
- [Matijs Brinkhuis](https://matijs.brinkhu.is/) and his [dotfiles repository](https://github.com/matijs/dotfiles)
- [Nicolas Gallagher](http://nicolasgallagher.com/) and his [dotfiles repository](https://github.com/necolas/dotfiles)
- [Sindre Sorhus](https://sindresorhus.com/)
- [Tom Ryder](https://sanctum.geek.nz/) and his [dotfiles repository](https://sanctum.geek.nz/cgit/dotfiles.git/about)
- [Kevin Suttle](http://kevinsuttle.com/) and his [dotfiles repository](https://github.com/kevinSuttle/dotfiles) and [macOS-Defaults project](https://github.com/kevinSuttle/macOS-Defaults), which aims to provide better documentation for [`~/.macos`](https://mths.be/macos)
- [Haralan Dobrev](https://hkdobrev.com/)
- Anyone who [contributed a patch](https://github.com/mathiasbynens/dotfiles/contributors) or [made a helpful suggestion](https://github.com/mathiasbynens/dotfiles/issues)
