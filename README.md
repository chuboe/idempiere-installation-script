# The purpose of this project is to make installing and managing iDempiere on Linux much easier.
iDempiere and Open Source ERP are quite possibly the biggest discontinuous changes and enablers for producing business efficiency and insight. 
All that power is of no good to you unless you can easily make use of it. This project and the [ERP Academy](http://erp-academy.chuckboecking.com) make open source ERP available to more organizations. You can provide open source ERP to your team for about $2 per user per month (the cost of hosting). This is true whether you are supporting a team of 2 or 200, 

#Installation
To install all components of iDempiere 6.2 on a single new Ubuntu 18.04 server, simply copy and paste the below line, change the -p password, and hit enter. The script will do all the rest. After about 8 minutes, iDempiere will appear on your machine.

```
#!bash

sudo apt-get -y install mercurial; hg clone https://bitbucket.org/cboecking/idempiere-installation-script; chmod 766 idempiere-installation-script/*.sh; ./idempiere-installation-script/idempiere_install_script_master_linux.sh -P Silly -l |& tee output.txt; nano /opt/chuboe/idempiere_installer_feedback.txt
```

You can also use this script to install components separately. You can place the WebUI and database onto different servers. By choosing the correct command options, you choose what to install. To learn more about this script and how to use it, go to [www.chuckboecking.com](https://www.chuckboecking.com/idempiere-open-source-erp-linux-installation-really-easy-2/). 

# Happy learning!! 
I worked very hard to make the installation script easy to read for the average IT person. It should provide a great learning tool to help you become an expert iDempiere host. Do not hesitate to contact me if I can help you learn, configure, audit and launch iDempiere. If you are intimidated by this script, and you want help installing it:

 1: Create an AWS account

 2: Reach out to me. I can execute the script in a couple of minutes.

# Want to learn more?
I teach an [online iDempiere ERP Academy](http://erp-academy.chuckboecking.com). We meet for live discussions 6 times per week. There are over three hundred tutorials and videos about how to learn, configure and audit iDempiere for a successful golive. Here are the course [frequently asked questions](http://erp-academy.chuckboecking.com/?page_id=32).

#Contact Me
Chuck Boecking  
chuck@chuboe.com  
<http://www.chuckboecking.com>  