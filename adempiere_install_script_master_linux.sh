#This is not a really script yet. It is a work in progress.
#It is currently a collection of commands for ubuntu to install ADempiere. 
#Eventually, it will look like the iDempiere installer script in this repository.
#You simply copy and paste each command to the command prompt.
#This scripts assumes the following:
# * You are using AWS. 
# * You are using ubuntu.

sudo apt-get --yes update
sudo updatedb
sudo apt-get --yes install unzip htop s3cmd expect

#Install the DB and make it available to everyone. This script assumes you will keep you DB behind a firewall.
#CHANGE THE PASSWORD away from SillyWilly!!!
sudo apt-get --yes install postgresql postgresql-contrib
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'SillyWilly';"
sudo sed -i '$ a\host   all     all     0.0.0.0/0       md5' /etc/postgresql/9.1/main/pg_hba.conf
sudo sed -i 's/#listen_addresses = '"'"'localhost'"'"'/listen_addresses = '"'"'*'"'"'/' /etc/postgresql/9.1/main/postgresql.conf
sudo -u postgres service postgresql restart

#Install PHPPGAdmin - a tool for querying the DB.
sudo apt-get --yes install phppgadmin
sudo sed -i 's/# allow from all/allow from all/' /etc/apache2/conf.d/phppgadmin
sudo service apache2 restart

sudo apt-get --yes install openjdk-6-jdk

#Originally, I did not want to use a desktop; 
#however, I am having trouble with getting the RUN_silentsetup.sh to function correctly.
#By adding the desktop, you get a couple of benefits
# * It only uses memory when you are connected
# * You can install Eclipse and download the ADempiere code.
sudo apt-get install -y lubuntu-desktop xrdp
sudo sed -i 's=. /etc/X11/Xsession=#. /etc/X11/Xsession=' /etc/xrdp/startwm.sh
sudo sed -i '$ a\startlubuntu' /etc/xrdp/startwm.sh
sudo passwd ubuntu

# ADempiere should be installed in the /opt directory.
mkdir Downloads
cd Downloads/
wget http://sourceforge.net/projects/adempiere/files/ADempiere%20Official%20Release/Adempiere%203.7.0-LTS/Adempiere_370LTS.tar.gz/download
mv download Adempiere_370LTS.tar.gz
cd ..
tar zxvf Downloads/Adempiere_370LTS.tar.gz

cd Adempiere/
chmod +x *.sh
chmod +x utils/*.sh

#The following body of code is supposed to update AdempiereEnv.properties to be able to execute RUN_silentsetup.sh.
#The below code works; however, the resulting AdempiereEnv.properties will now launch.
#Instead, use remote desktop to run "./RUN_setup.sh". Once it completes, you can exit remote desktop.

#mv AdempiereEnvTemplate.properties AdempiereEnv.properties
##sudo sed -i '$ a\export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64' /etc/environment
##sudo sed -i '$ a\export ADEMPIERE_HOME=/home/ubuntu/Adempiere' /etc/environment
#sudo sed -i 's@#ADEMPIERE_HOME=/opt/adempiere/current@ADEMPIERE_HOME=/home/ubuntu/Adempiere@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_HOME=C@#ADEMPIERE_HOME=C@' AdempiereEnv.properties
#sudo sed -i 's@#JAVA_HOME=/usr/lib/jvm/java-6-sun@JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64@' AdempiereEnv.properties
#sudo sed -i 's@JAVA_HOME=C@#JAVA_HOME=C@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_DB_SYSTEM=postgres@ADEMPIERE_DB_SYSTEM=SillyWilly@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_DB_PASSWORD=adempiere@ADEMPIERE_DB_PASSWORD=SillyWilly@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_WEB_PORT=80@ADEMPIERE_WEB_PORT=8080@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_SSL_PORT=443@ADEMPIERE_SSL_PORT=8443@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_DB_SERVER=localhost@ADEMPIERE_DB_SERVER=ip-10-180-227-230.ec2.internal@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_APPS_SERVER=localhost@ADEMPIERE_APPS_SERVER=ip-10-180-227-230.ec2.internal@' AdempiereEnv.properties
#./RUN_silentsetup.sh

#import the ADempiere database
cd utils
./RUN_ImportAdempiere.sh

#run setup now that the DB exists. Note that when you ran RUN_setup.sh above, the system created a valid AdempiereEnv.properties file.
#You can now execute RUN_silentsetup.sh as you wish.
cd ..
./RUN_silentsetup.sh

#Nohup allows you to run the server and disconnect your ssh session without killing the application server.
cd utils
nohup ./RUN_Server2.sh &

#The below section helps you install the latest version of Libero manufacturing
#For more information visit: http://www.adempiere.com/Libero_Manufacturing_Official_Extension
cd ../..
cd Downloads
wget http://sourceforge.net/projects/adempiere/files/Adempiere%20Packages/Libero%20Manufacturing/liberoMFG.jar/download
mv download liberoMFG.jar
wget http://sourceforge.net/projects/adempiere/files/Adempiere%20Packages/Libero%20Manufacturing/liberozkMFG.jar/download
mv download liberozkMFG.jar
cp liberoMFG.jar ../Adempiere/packages/liberoMFG/lib/
cp liberozkMFG.jar ../Adempiere/zkpackages/liberoMFG/lib/
cd ..