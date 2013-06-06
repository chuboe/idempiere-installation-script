# The purpose of this file is to make installing iDempiere on Linux much easier.

You can use this script to install all components on a single server, 
or you can separate the WebUI and database onto different servers. 
By choosing the correct command options, you choose what to install.

The script is currently hardcoded to work well on Ubuntu 12.04 LTS. 
I will eventually make the script more graceful; 
however, it is very important to me to keep the script readable. 
There is as much value in understanding the script is there is utility in using it.

# To install all iDempiere components on a single machine, issue the command:

# ./idempiere_install_script_master_linux.sh -P s1llyw1lly -l  &>output.txt

# Wait about 8 minutes, and iDempiere will magically appear on port 8080 of your server. Review the output.txt to ensure all worked as well.

# Use the -h option to learn more about the parameters.

# Happy learning!! Do not hesitate to contact me if I can help you learn and deploy iDempiere.

# Chuck Boecking (chuck@chuboe.com)
# http://www.chuckboecking.com
