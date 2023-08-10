#!/bin/bash

# The purpose of this script is to install docker and docker compose on a new machine.
# You can either run this file as a script or simply copy/paste commands as is needed.
# Docker-compose is available through apt install on some versions of ubuntu (not aws). The below should get you the latest versions.

# If you are installing docker inside LXD, you need to issue the following from your host.
# the below commands assume your LXD/LXC instance is named docker3
lxc config set docker3 security.nesting=true
lxc config set docker3 security.syscalls.intercept.mknod=true
lxc config set docker3 security.syscalls.intercept.setxattr=true

# Install Docker - https://docs.docker.com/engine/install/ubuntu/
sudo apt-get install ca-certificates curl gnupg
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

# Check to see if all executed as expected
# sudo service docker status
# docker -v
# sudo docker container run hello-world

# Add your user to the docker group to prevent needing to use sudo
# sudo usermod -aG docker $USER
# docker container run hello-world

# Install Docker Compose - https://linuxize.com/post/how-to-install-and-use-docker-compose-on-ubuntu-18-04/
# NOTE: Check for latest version: https://github.com/docker/compose/releases
COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-$(uname -s)-$(uname -m)"
COMPOSE_URL_LOWER="${COMPOSE_URL,,}"
sudo curl -L $COMPOSE_URL_LOWER -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
