#!/bin/bash

sudo apt-get install -y curl git zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.zshrc ~/.zshrc.orig
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc	
sudo sed -i "s|ZSH_THEME=\"robbyrussell\"|ZSH_THEME=\"ys\"|" ~/.zshrc
echo "modify the /etc/passwd file to set zsh as your username's default."
echo "==> look for something like this: ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash"
echo "==> replace the bash with zsh like this: ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/zsh"
echo ""
echo "Either type in zsh or restart your terminal to use zsh"
