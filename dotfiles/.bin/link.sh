#!/bin/bash

SCRIPT_DIR="$(pwd)"

realpath() {
  case "$1" in /*) ;; *) printf '%s/' "$PWD";; esac; echo "$1"
}

for dotfile in `\find . -name '.??*' -type f`; do
    [[ "$dotfile" == ".bin" ]] && continue
    [[ "$dotfile" == ".git" ]] && continue
    [[ "$dotfile" == ".github" ]] && continue
    [[ "$dotfile" == ".DS_Store" ]] && continue

    echo "$(realpath $dotfile) -> $HOME/$(dirname $dotfile)"
    # ln -fnsv "$(realpath $dotfile)" "$HOME/$(dirname $dotfile)"
done

for dotfile in `\find .config -type f`; do
    [[ "$dotfile" == ".DS_Store" ]] && continue

    echo "$(realpath $dotfile) -> $HOME/$(dirname $dotfile)"

    mkdir -p $(dirname $dotfile)
    # ln -fnsv "$dotfile" "$HOME"
done

# for dotfile in "${SCRIPT_DIR}"/.??* ; do
#     [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
#     [[ "$dotfile" == "${SCRIPT_DIR}/.github" ]] && continue
#     [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue

#     ln -fnsv "$dotfile" "$HOME"
# done
