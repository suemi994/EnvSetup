#! /bin/bash

nvim --version
if [ $? -ne 0 ]; then
  wget --quiet https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage --output-document nvim
  ln -s /usr/bin/nvim nvim
fi

cp init.vim ~/.config/nvim/
cp conf.lua ~/.config/nvim/
