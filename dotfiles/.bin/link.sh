#!/bin/bash

SCRIPT_DIR="$(pwd)"

realpath() {
  case "$1" in /*) ;; *) printf '%s/' "$PWD";; esac; echo "$1"
}

for dotfile in `\find . -name '.??*' -type f`; do
    [[ "$dotfile" == ".DS_Store" ]] && continue

    echo "$(realpath $dotfile) -> $HOME/$(dirname $dotfile)"
    mkdir -p $HOME/$(dirname $dotfile)
    ln -fnsv "$(realpath $dotfile)" "$HOME/$(dirname $dotfile)"
done

for dotfile in `\find .config -type f`; do
    [[ "$dotfile" == ".DS_Store" ]] && continue

    echo "$(realpath $dotfile) -> $HOME/$(dirname $dotfile)"
    mkdir -p $HOME/$(dirname $dotfile)
    ln -fnsv "$(realpath $dotfile)" "$HOME/$(dirname $dotfile)"
done

