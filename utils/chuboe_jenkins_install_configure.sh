## NOTE: this is not an automated isntall script (not yet)
## The below steps help you create an independent jenkins machine to build iDempiere and your plugins

## NOTE: if you are installing this in an AWS VPC and you are getting the following error:
##    sudo: unable to resolve host
## Execute this script: https://bitbucket.org/cboecking/idempiere-installation-script/src/default/utils/setHostName.sh

#####Install needed tools
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins zip mercurial htop apache2 s3cmd

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
#may need to give ubuntu permission to this folder
cd /opt/buckminster-headless-4.2
wget http://download.eclipse.org/tools/buckminster/products/director_latest.zip
sudo unzip /opt/buckminster-headless-4.2/director_latest.zip -d /opt/buckminster-headless-4.2/
sudo chmod +x -R /opt/buckminster-headless-4.2/
cd /opt/buckminster-headless-4.2/director

sudo ./director -r http://download.eclipse.org/tools/buckminster/headless-4.2/ -d /opt/buckminster-headless-4.2/ -p Buckminster -i org.eclipse.buckminster.cmdline.product
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.maven.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.core.headless.feature
sudo ./buckminster install http://download.eclipse.org/tools/buckminster/headless-4.2/ org.eclipse.buckminster.pde.headless.feature

#####Create web directories publishing p2
sudo mkdir /opt/idempiere-builds
sudo mkdir /opt/idempiere-builds/idempiere.p2
sudo chown jenkins:www-data /opt/idempiere-builds/idempiere.p2

cd /var/www
sudo ln -s /opt/idempiere-builds/idempiere.p2

sudo nano /etc/apache2/sites-available/default

	#Somewhere in your VirtualHost, add the following:
		<Directory /var/www/idempiere.p2>
			AllowOverride AuthConfig
		</Directory>

		Alias /idempiere/p2 /var/www/idempiere.p2
	#end: Somewhere in your VirtualHost, add the following:

sudo /etc/init.d/apache2 restart

#####Install Jenkins plugins (performed in jenkins UI)
# (1) buckminster
# (2) mercurial

#####Jenkins Job Commands (performed in jenkins UI)
#1 Shell - clear workspace
rm -rf ${WORKSPACE}/buckminster.output/ ${WORKSPACE}/buckminster.temp/ ${WORKSPACE}/targetPlatform/

#2 Buckminster - build site.p2
importtargetdefinition -A '${WORKSPACE}/org.adempiere.sdk-feature/build-target-platform.target'
import '${WORKSPACE}/org.adempiere.sdk-feature/adempiere.cquery'
build -t
perform -D qualifier.replacement.*=generator:buildTimestamp -D generator.buildTimestamp.format=\'v\'yyyyMMdd-HHmm -D target.os=*   -D target.ws=*   -D target.arch=* -D product.features=org.idempiere.eclipse.platform.feature.group -D product.profile=DefaultProfile -D product.id=org.adempiere.server.product   'org.adempiere.server:eclipse.feature#site.p2'

#3 Shell - copy results (site.ps) to webserver
rm -rf /opt/idempiere-builds/idempiere.p2/*
cp -fR ${WORKSPACE}/buckminster.output/org.adempiere.server_1.0.0-eclipse.feature/site.p2/* /opt/idempiere-builds/idempiere.p2