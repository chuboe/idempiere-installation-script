sudo apt-get --yes update
sudo updatedb
sudo apt-get --yes install unzip htop s3cmd expect
sudo apt-get --yes install postgresql postgresql-contrib
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'simplejj';"
sudo sed -i '$ a\host   all     all     0.0.0.0/0       md5' /etc/postgresql/9.1/main/pg_hba.conf
sudo sed -i 's/#listen_addresses = '"'"'localhost'"'"'/listen_addresses = '"'"'*'"'"'/' /etc/postgresql/9.1/main/postgresql.conf
sudo -u postgres service postgresql restart

sudo apt-get --yes install phppgadmin
sudo sed -i 's/# allow from all/allow from all/' /etc/apache2/conf.d/phppgadmin
sudo service apache2 restart

sudo apt-get --yes install openjdk-6-jdk

sudo apt-get install -y lubuntu-desktop xrdp
sudo sed -i 's=. /etc/X11/Xsession=#. /etc/X11/Xsession=' /etc/xrdp/startwm.sh
sudo sed -i '$ a\startlubuntu' /etc/xrdp/startwm.sh
sudo passwd ubuntu

mkdir Downloads
cd Downloads/
wget http://sourceforge.net/projects/adempiere/files/ADempiere%20Official%20Release/Adempiere%203.7.0-LTS/Adempiere_370LTS.tar.gz/download
mv download Adempiere_370LTS.tar.gz
cd ..
tar zxvf Downloads/Adempiere_370LTS.tar.gz

cd Adempiere/
chmod +x *.sh
chmod +x utils/*.sh

#Use remote desktop to run "./RUN_setup.sh". Once it completes, you can exit remote desktop.

#The below will be used to bypass needing remote desktop. Currencly, this does not work.
#mv AdempiereEnvTemplate.properties AdempiereEnv.properties
##sudo sed -i '$ a\export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64' /etc/environment
##sudo sed -i '$ a\export ADEMPIERE_HOME=/home/ubuntu/Adempiere' /etc/environment
#sudo sed -i 's@#ADEMPIERE_HOME=/opt/adempiere/current@ADEMPIERE_HOME=/home/ubuntu/Adempiere@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_HOME=C@#ADEMPIERE_HOME=C@' AdempiereEnv.properties
#sudo sed -i 's@#JAVA_HOME=/usr/lib/jvm/java-6-sun@JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64@' AdempiereEnv.properties
#sudo sed -i 's@JAVA_HOME=C@#JAVA_HOME=C@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_DB_SYSTEM=postgres@ADEMPIERE_DB_SYSTEM=simplejj@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_DB_PASSWORD=adempiere@ADEMPIERE_DB_PASSWORD=simplejj@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_WEB_PORT=80@ADEMPIERE_WEB_PORT=8080@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_SSL_PORT=443@ADEMPIERE_SSL_PORT=8443@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_DB_SERVER=localhost@ADEMPIERE_DB_SERVER=ip-10-180-227-230.ec2.internal@' AdempiereEnv.properties
#sudo sed -i 's@ADEMPIERE_APPS_SERVER=localhost@ADEMPIERE_APPS_SERVER=ip-10-180-227-230.ec2.internal@' AdempiereEnv.properties
#./RUN_silentsetup.sh

cd utils
./RUN_ImportAdempiere.sh

cd ..
./RUN_silentsetup.sh

cd utils
./RUN_Server2.sh