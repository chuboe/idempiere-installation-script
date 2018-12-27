#!/bin/bash

# install bashdb manually since no longer supported by ubuntu 18.04

sudo apt-get -y update
sudo apt-get -y install texi2html texinfo build-essential

# update below for most current version
# see all versions:  https://sourceforge.net/projects/bashdb/files/bashdb/
BASHDB_CURRENT=bashdb-4.4-1.0.1

cd ~
mkdir bashdb_install
cd bashdb_install
wget https://sourceforge.net/projects/bashdb/files/bashdb/4.4-1.0.1/$BASHDB_CURRENT.tar.gz
tar xpf $BASHDB_CURRENT.tar.gz
cd $BASHDB_CURRENT
./configure
make
sudo make install