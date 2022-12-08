#!/bin/bash

SCRIPT_DIR="$(pwd)"

for dotfile in `\find ${SCRIPT_DIR} -name '.??*' -type f`; do
    [[ "$dotfile" == "${SCRIPT_DIR}/.bin" ]] && continue
    [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
    [[ "$dotfile" == "${SCRIPT_DIR}/.github" ]] && continue
    [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue

    mkdir -p $(dirname $dotfile)
    ln -fnsv "$dotfile" "$HOME"
done

for dotfile in `\find ${SCRIPT_DIR}/.config -type f`; do
    [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue
    mkdir -p $(dirname $dotfile)
    ln -fnsv "$dotfile" "$HOME"
done

# for dotfile in "${SCRIPT_DIR}"/.??* ; do
#     [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
#     [[ "$dotfile" == "${SCRIPT_DIR}/.github" ]] && continue
#     [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue

#     ln -fnsv "$dotfile" "$HOME"
# done
