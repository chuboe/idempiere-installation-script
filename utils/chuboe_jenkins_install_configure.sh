## NOTE: this is not an automated isntall script (not yet)
## The below steps help you create an independent jenkins machine to build iDempiere and your plugins
## Because Jenkins runs on port 8080 by default, you will probably want to install the below on a dedicated machine
## This script was last successfully run on Ubuntu 14.04

## NOTE: if you are installing this in an AWS VPC and you are getting the following error:
##    sudo: unable to resolve host
## Execute this script: https://bitbucket.org/cboecking/idempiere-installation-script/src/default/utils/setHostName.sh

## ASSUMPTIONS
## local OS username = ubuntu

#####Install needed tools
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins zip mercurial htop apache2 s3cmd openjdk-6-jdk openjdk-7-jdk

## NOTE: Jenkins will be launched as a daemon up on start. See the following for more detail:
##    /etc/init.d/jenkins
##    https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu (search google for "install jenkins")

#####clone a local repository of iDempiere
#  doing so insulates you (and jenkins) from the many changes that happen in the main bitbucket repository
#  FYI - jenkins will create yet another clone for its build purposes
mkdir source
cd source
mkdir id
cd id
hg clone https://bitbucket.org/idempiere/idempiere

#####Install Director and Buckminster
sudo mkdir /opt/buckminster-headless-4.2
sudo chown -R ubuntu:ubuntu /opt/buckminster-headless-4.2
cd /opt/buckminster-headless-4.2
wget http://download.eclipse.org/tools/buckminster/products/director_latest.zip
sudo unzip /opt/buckminster-headless-4.2/director_latest.zip -d /opt/buckminster-headless-4.2/
sudo chmod +x -R /opt/buckminster-headless-4.2/*.sh
cd /opt/buckminster-headless-4.2/director

sudo ./director -r http://download.eclipse.org/tools/buckminster/headless-4.2/ -d /opt/buckminster-headless-4.2/ -p Buckminster -i org.eclipse.buckminster.cmdline.product
cd /opt/buckminster-headless-4.2
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.maven.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.core.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.pde.headless.feature

#####Create web directories publishing p2
sudo mkdir /opt/idempiere-builds
sudo mkdir /opt/idempiere-builds/idempiere.p2
sudo mkdir /opt/idempiere-builds/idempiere.migration
sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.p2
sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.migration

cd /var/www
sudo ln -s /opt/idempiere-builds/idempiere.p2
sudo ln -s /opt/idempiere-builds/idempiere.migration

sudo nano /etc/apache2/sites-available/000-default.conf

	#Somewhere in your VirtualHost, add the following:
		<Directory /var/www/idempiere.p2>
			AllowOverride AuthConfig
		</Directory>

		<Directory /var/www/idempiere.migration>
			AllowOverride AuthConfig
		</Directory>

		Alias /idempiere/p2 /var/www/idempiere.p2
		Alias /idempiere/migration /var/www/idempiere.migration
	#end: Somewhere in your VirtualHost, add the following:

sudo /etc/init.d/apache2 restart

#####Install Jenkins plugins (performed in jenkins UI)
# www.YourURL.com:8080
# Jenkins Menu => Manage Jenkins => Manage Plugins => Available tab => Choose following plugins => "Install Without Restart"
# (1) buckminster
# (2) mercurial

#####Configure Jenkins System (performed in jenkins UI)
# Jenkins Menu => Manage Jenkins => Configure System
#   Add Buckminster Button
#   Buckminster Name: buckminster-headless-4.2
#   Install Automatically: no (uncheck)
#   Installation Directory: /opt/buckminster-headless-4.2/
#   Additonal Startup Parameters: -Xmx1024m

#####Create New Item (new job in jenkins UI)
# Jenkins Menu => New Item "iDempiere-2.1" of type "Build a freestyle Software Project" => OK
#   NO SPACES IN NAME OF JOB!
# Configuration
#  Source Code Management => Mercurial
#    URL: /home/ubuntu/source/id/idempiere
#    Revision Type: Branch
#    Revision: release-2.1
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

#3 Shell - copy results (site.ps) to webserver
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