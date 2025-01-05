#!/bin/bash

set -eu

if [ ! command -v brew >/dev/null 2>&1 ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew ✅"
fi

if [ -f "$HOME/.config/brewfile/Brewfile" ]; then
    brew install rcmdnk/file/brew-file
    echo "Brewfile package installed ✅"
fi

if [ -f $(brew --prefix)/etc/brew-wrap ];then
    source $(brew --prefix)/etc/brew-wrap
    brew file install
    echo "All packages installed by Brewfile ✅"
fi
