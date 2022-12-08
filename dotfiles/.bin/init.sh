#!/bin/bash

if [ "$(uname)" == "Darwin" ] ; then
  echo "This is macOS"
  mkdir -p $HOME/bin
elif [ "$(uname)" == "Linux" ] ; then
  echo "This is Linux"
  mkdir -p $HOME/bin
else
  echo "This is $(uname)"
fi
