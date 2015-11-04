## NOTE: this is not an automated isntall script (not yet)
## The below steps help you create an independent jenkins machine to build iDempiere and your plugins
## Because Jenkins runs on port 8080 by default, you will probably want to install the below on a dedicated machine
## This script was last successfully run on Ubuntu 14.04

## NOTE: if you are installing this in an AWS VPC and you are getting the following error:
##    sudo: unable to resolve host
## Execute this script: https://bitbucket.org/cboecking/idempiere-installation-script/src/default/utils/setHostName.sh

## ASSUMPTIONS
## local OS username = ubuntu
JENKINS_OS_USER="ubuntu"

#####Install needed tools
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins zip mercurial htop s3cmd openjdk-7-jdk

## NOTE: Jenkins will be launched as a daemon up on start. See the following for more detail:
##    /etc/init.d/jenkins
##    https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu (search google for "install jenkins")

#####clone a local repository of iDempiere
#  doing so insulates you (and jenkins) from the many changes that happen in the main bitbucket repository
#  FYI - jenkins will create yet another clone for its build purposes
cd /opt/
sudo mkdir source
sudo chown $JENKINS_OS_USER:$JENKINS_OS_USER source
cd source
sudo mkdir idempiere_source
cd idempiere_source
sudo hg clone https://bitbucket.org/idempiere/idempiere

#####Install Director and Buckminster 4.2 - used for iDempiere release2.1
sudo mkdir /opt/buckminster-headless-4.2
cd /opt/buckminster-headless-4.2
sudo wget http://download.eclipse.org/tools/buckminster/products/director_latest.zip
sudo unzip /opt/buckminster-headless-4.2/director_latest.zip -d /opt/buckminster-headless-4.2/
cd /opt/buckminster-headless-4.2/director

sudo ./director -r http://download.eclipse.org/tools/buckminster/headless-4.2/ -d /opt/buckminster-headless-4.2/ -p Buckminster -i org.eclipse.buckminster.cmdline.product
cd /opt/buckminster-headless-4.2
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.maven.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.core.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.pde.headless.feature

#####Install Director and Buckminster 4.4 - used for iDempiere release3.0
sudo mkdir /opt/buckminster-headless-4.4
cd /opt/buckminster-headless-4.4
sudo wget http://download.eclipse.org/tools/buckminster/products/director_latest.zip
sudo unzip /opt/buckminster-headless-4.4/director_latest.zip -d /opt/buckminster-headless-4.4/
cd /opt/buckminster-headless-4.4/director

sudo ./director -r http://download.eclipse.org/tools/buckminster/headless-4.4/ -d /opt/buckminster-headless-4.4/ -p Buckminster -i org.eclipse.buckminster.cmdline.product
cd /opt/buckminster-headless-4.4
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.4/ org.eclipse.buckminster.maven.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.4/ org.eclipse.buckminster.core.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.4/ org.eclipse.buckminster.pde.headless.feature


#####Using Apache as a reverse proxy to protect Jenkins
sudo apt-get install -y apache2
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2dissite 000-default

# The below is good for a bash script. If you are copying and pasting commands, just copy and paste the stuff inside the EOL to /etc/apache2/sites-available/jenkins.conf
JENKINS_TEMP=~/jenkins_temp.conf
JENKINS_CONF=/etc/apache2/sites-available/jenkins.conf
cat >$JENKINS_TEMP <<EOL
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName ci.company.com
        ServerAlias ci
        ProxyRequests Off
        <Proxy *>
                Order deny,allow
                Allow from all
        </Proxy>
        ProxyPreserveHost on
        ProxyPass / http://localhost:8080/ nocanon
        AllowEncodedSlashes NoDecode
</VirtualHost>
EOL
sudo mv $JENKINS_TEMP $JENKINS_CONF
sudo chown root:root $JENKINS_CONF
# end of file creation and move

sudo a2ensite jenkins
sudo service apache2 restart

#####Create web directories publishing p2 - only needed if you want to use apache instead of jenkins itself - otherwise, skip to the next step
## This section is commented out because I use apache to act as a reverse proxy
#sudo apt-get -y install apache2
#sudo mkdir /opt/idempiere-builds
#sudo mkdir /opt/idempiere-builds/idempiere.p2
#sudo mkdir /opt/idempiere-builds/idempiere.migration
#sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.p2
#sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.migration
#
#cd /var/www
#sudo ln -s /opt/idempiere-builds/idempiere.p2
#sudo ln -s /opt/idempiere-builds/idempiere.migration
#
#sudo nano /etc/apache2/sites-available/000-default.conf
#
#	#Somewhere in your VirtualHost, add the following:
#		<Directory /var/www/idempiere.p2>
#			AllowOverride AuthConfig
#		</Directory>
#
#		<Directory /var/www/idempiere.migration>
#			AllowOverride AuthConfig
#		</Directory>
#
#		Alias /idempiere/p2 /var/www/idempiere.p2
#		Alias /idempiere/migration /var/www/idempiere.migration
#	#end: Somewhere in your VirtualHost, add the following:
#
#sudo /etc/init.d/apache2 restart

#####Configure Jenkins security (performed in jenkins UI)
# Jenkins Menu => Manage Jenkins => Configure Global Security
# Enable Security
# Choose Jenkin's own database
# Uncheck allow users to sign up
# Save - this will prompt you to create a username password
###
# Jenkins Menu => Manage Jenkins => Configure Global Security
# Choose Matrix Based security
# Give Anonymous Overall=>Read; Job=>Read; Job=>Workspace (nothing else - this will make all projects available to ananomous users)
# Add your user => check all check boxes for your user

#####Install Jenkins plugins (performed in jenkins UI)
# www.YourURL.com:8080
# Jenkins Menu => Manage Jenkins => Manage Plugins => Available tab => Choose following plugins => "Install Without Restart"
# (1) buckminster
# (2) mercurial

#####Configure Jenkins System (performed in jenkins UI) - Version 4.2
# Jenkins Menu => Manage Jenkins => Configure System
#   Add Buckminster Button
#   Buckminster Name: buckminster-headless-4.2
#   Install Automatically: no (uncheck)
#   Installation Directory: /opt/buckminster-headless-4.2/
#   Additonal Startup Parameters: -Xmx1024m

#####Configure Jenkins System (performed in jenkins UI) - Version 4.4
# Jenkins Menu => Manage Jenkins => Configure System
#   Add Buckminster Button
#   Buckminster Name: buckminster-headless-4.4
#   Install Automatically: no (uncheck)
#   Installation Directory: /opt/buckminster-headless-4.4/
#   Additonal Startup Parameters: -Xmx1024m

#####Create New Item (new job in jenkins UI)
# Jenkins Menu => New Item "iDempiere2.1Daily" of type "Build a freestyle Software Project" => OK
#   NO SPACES IN NAME OF JOB!
# Configuration
#  Source Code Management => Mercurial
#    Buckminster: 4.2
#    URL: /opt/source/idempiere_source/idempiere
#    Revision Type: Branch
#    Revision: release-2.1
#  Add below build steps

#####Create New Item (new job in jenkins UI)
# Jenkins Menu => New Item "iDempiere3.0Daily" of type "Build a freestyle Software Project" => OK
#   NO SPACES IN NAME OF JOB!
# Configuration
#  Source Code Management => Mercurial
#    Buckminster: 4.4
#    URL: /opt/source/idempiere_source/idempiere
#    Revision Type: Branch
#    Revision: development
#  Add below build steps


#####Jenkins Build Steps (performed in jenkins UI)
#1 Shell - clear workspace
rm -rf ${WORKSPACE}/buckminster.output/ ${WORKSPACE}/buckminster.temp/ ${WORKSPACE}/targetPlatform/

#2 Buckminster - build site.p2
importtargetdefinition -A '${WORKSPACE}/org.adempiere.sdk-feature/build-target-platform.target'
import '${WORKSPACE}/org.adempiere.sdk-feature/adempiere.cquery'
build -t
perform -D qualifier.replacement.*=generator:buildTimestamp -D generator.buildTimestamp.format=\'v\'yyyyMMdd-HHmm -D target.os=*   -D target.ws=*   -D target.arch=* -D product.features=org.idempiere.eclipse.platform.feature.group -D product.profile=DefaultProfile -D product.id=org.adempiere.server.product   'org.adempiere.server:eclipse.feature#site.p2'
perform -D 'qualifier.replacement.*=generator:buildTimestamp'  -D "generator.buildTimestamp.format='v'yyyyMMdd-HHmm"  -D 'target.os=linux'   -D 'target.ws=gtk'   -D 'target.arch=x86_64'  -D product.features=org.idempiere.eclipse.platform.feature.group   -D product.profile=DefaultProfile  -D product.id=org.adempiere.server.product   'org.adempiere.server:eclipse.feature#create.product.zip'

## NOTE: regarding the two above "perform" statements
# The first builds the p2 site
# The second builds the product and zips it

#3 Shell - copy results (site.ps) to webserver - only include this build step if you configured apache above in the "Create web directories publishing p2" step
rm -rf /opt/idempiere-builds/idempiere.p2/*
rm -rf /opt/idempiere-builds/idempiere.migration/*
cp -fR ${WORKSPACE}/buckminster.output/org.adempiere.server_2.1.0-eclipse.feature/site.p2/* /opt/idempiere-builds/idempiere.p2
cp -fR ${WORKSPACE}/migration/* /opt/idempiere-builds/idempiere.migration
cd ${WORKSPACE}
zip -r /opt/idempiere-builds/idempiere.migration/migration.zip migration/
# s3cmd sync ${WORKSPACE}/buckminster.output/org.adempiere.server_2.1.0-eclipse.feature/site.p2/ s3://YourBucket/iDempiere_backup/build/

#####Build Now
# See if she works!!

## NOTE: Here are the steps to configure s3cmd - push to Amazon's AWS S3
## Issue the following commands to enable s3cmd and create an iDempiere backup bucket in S3.
## ----> s3cmd --configure
## --------> get your access key and secred key by logging into your AWS account
## --------> enter a password. Chose something different than your AWS password. Write it down!!
## --------> Accept the default path to GPG
## --------> Answer yes to HTTPS
## ----> s3cmd mb s3://iDempiere_backup