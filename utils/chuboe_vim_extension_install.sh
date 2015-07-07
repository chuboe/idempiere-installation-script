#!/bin/bash

sudo apt-get install -y git exuberant-ctags
cd ~
git clone git://github.com/amix/vimrc.git ~/.vim_runtime
cd .vim_runtime/
chmod +x *.sh
./install_awesome_vimrc.sh
