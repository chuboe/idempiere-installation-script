#!/bin/bash

# The purpose of this script is to install docker and docker compose on a new machine.
# You can either run this file as a script or simply copy/paste commands as is needed.

# Install Docker - https://linuxize.com/post/how-to-install-and-use-docker-on-ubuntu-18-04/
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce

# Check to see if all executed as expected
# sudo service docker status
# docker -v
# sudo docker container run hello-world

# Add your user to the docker group to prevent needing to use sudo
# sudo usermod -aG docker $USER
# docker container run hello-world

# Install Docker Compose - https://linuxize.com/post/how-to-install-and-use-docker-compose-on-ubuntu-18-04/
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# docker-compose --version