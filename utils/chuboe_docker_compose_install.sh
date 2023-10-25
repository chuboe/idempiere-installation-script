#!/bin/bash

# The purpose of this script is to install docker and docker compose on a new machine.
# You can either run this file as a script or simply copy/paste commands as is needed.
# Docker-compose is available through apt install on some versions of ubuntu (not aws). The below should get you the latest versions.

# If you are installing docker inside LXD, you need to issue the following from your host.
# the below commands assume your LXD/LXC instance is named docker3
lxc config set YourInstanceName security.nesting=true
lxc config set YourInstanceName security.syscalls.intercept.mknod=true
lxc config set YourInstanceName security.syscalls.intercept.setxattr=true

# Install Docker - https://docs.docker.com/engine/install/ubuntu/
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER # add your user to docker group
exit
#reconnect to server where you installed docker and run the hello world example container
docker run hello-world

# sudo service docker status
# docker -v
