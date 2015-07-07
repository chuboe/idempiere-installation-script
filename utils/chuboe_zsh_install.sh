#!/bin/bash

echo "Note: install curl, git and zsh."
sudo apt-get install -y curl git zsh
echo ""
echo "Note: Get clone of oh-my-zsh repo."
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
echo ""
echo "Note: Create a copy of the existing .zshrc file if it exists."
echo "==> Ignore the error if it does not exit."
cp ~/.zshrc ~/.zshrc.orig
echo ""
echo "Note: create default .zshrc"
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc	
echo ""
echo "Note: changing the theme to one that reports on mercurial project status"
sudo sed -i "s|ZSH_THEME=\"robbyrussell\"|ZSH_THEME=\"ys\"|" ~/.zshrc
echo ""
echo "ACTION NEEDED: Modify the /etc/passwd file to set zsh as your username's default."
echo "==> look for something like this:"
echo "=====> ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash"
echo "==> replace the bash with zsh like this:"
echo "=====> ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/zsh"
echo ""
echo "Either type in zsh or restart your terminal to use zsh"
