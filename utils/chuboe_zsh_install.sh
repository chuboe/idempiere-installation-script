#!/bin/bash

sudo apt-get install -y curl git zsh
sudo bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
sudo sed -i "s|ZSH_THEME=\"robbyrussell\"|ZSH_THEME=\"ys\"|" ~/.zshrc

