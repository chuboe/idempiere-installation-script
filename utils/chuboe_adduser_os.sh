#!/bin/bash

USER_TO_ADD=$1
INSTALL_DATE=`date +%Y%m%d`_`date +%H%M%S`
PEM_NAME="$USER_TO_ADD"_"$INSTALL_DATE".pem
PEM_LOCATION=/home/$USER/pem_created

if [ -z "$USER_TO_ADD" ]
then
	echo "need user argument"
	exit 1
fi

echo Adding user: $USER_TO_ADD
echo Install date: $INSTALL_DATE
echo Pem name: $PEM_NAME

sudo adduser $USER_TO_ADD --disabled-password --gecos "$USER_TO_ADD,none,none,none"

# add user to sudo group
# sudo echo "$USER_TO_ADD ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoer

# give new user a copy of your .bashrc
# sudo rm /home/$USER_TO_ADD/.bashrc
# cat ~/.bashrc | sudo -u $USER_TO_ADD tee /home/$CHUBOE_USER/.bashrc
# make bash the default
# sudo chsh $USER_TO_ADD -s /bin/bash

# create user credential in the tmp directory
TEMP_DIR=/tmp/"$USER_TO_ADD".pem
mkdir -p $TEMP_DIR
cd $TEMP_DIR
sudo ssh-keygen -f $USER_TO_ADD -N ''
# rename pem file
sudo mv $USER_TO_ADD $PEM_NAME

# make you the current user the owner of these files so you can download .pem later via scp
sudo chown -R $USER:$USER $TEMP_DIR

sudo -u $USER_TO_ADD mkdir /home/$USER_TO_ADD/.ssh
sudo chmod 700 /home/$USER_TO_ADD/.ssh
sudo -u $USER_TO_ADD cat $TEMP_DIR/$USER_TO_ADD.pub | sudo tee --append /home/$USER_TO_ADD/.ssh/authorized_keys
sudo chmod 600 /home/$USER_TO_ADD/.ssh/authorized_keys
sudo chown $USER_TO_ADD:$USER_TO_ADD /home/$USER_TO_ADD/.ssh/authorized_keys

mkdir -p $PEM_LOCATION
mv $TEMP_DIR/$PEM_NAME $PEM_LOCATION
rm -r $TEMP_DIR

echo ***************************************************
echo You can find the pem in $PEM_LOCATION
echo ***************************************************
