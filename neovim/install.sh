#! /bin/bash

nvim --version
if [ $? -ne 0 ]; then
  wget --quiet https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage --output-document nvim
  ln -s nvim /usr/bin/nvim
fi

if [ ! -d "~/.config/nvim" ]; then
    mkdir -p ~/.config/nvim
fi
ls | grep -v install.sh | xargs -i cp -r {} ~/.config/nvim/
