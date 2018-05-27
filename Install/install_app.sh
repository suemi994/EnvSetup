#!/bin/bash
pacman -Sy

# 安装Terminal
pacman -S yaourt terminator
pacman -Rs gnome-terminal

# 安装i3-wm桌面管理器
pacman -S i3-gaps
pacman -S i3blocks
pacman -S i3scrot

# 安装文档查阅软件
yaourt -S zeal
