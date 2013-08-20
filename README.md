# The purpose of this file is to make installing iDempiere on Linux much easier.
You can use this script to install all components on a single server, 
or you can separate the WebUI and database onto different servers. 
By choosing the correct command options, you choose what to install.

The script is currently configured to work well on Ubuntu 12.04 LTS. 
I will eventually make the script more graceful; 
however, it is very important to keep the script readable to Linux newbies. 
There is as much value in understanding the script is there is utility in using it.

# To install iDempiere 
To install all iDempiere components on a single machine, issue the command:

./idempiere_install_script_master_linux.sh -P s1llyw1lly -l  &>output.txt

Wait about 8 minutes, and iDempiere will magically appear on port 8080 of your server. 
Review the output.txt to ensure all worked as well.
Use the -h option to learn more about the parameters.

# Happy learning!! 
Do not hesitate to contact me if I can help you learn, configure, audit and 
launch iDempiere. If you are intimidated by this script, adn you want 
help installing it:

 1: Create an AWS account

 2: Reach out to me. I can execute the script in a couple of minutes.

# Want to learn more?
Once you get iDempiere up and running, check out my blog. There are many tutorials 
designed to help you learn how to perform wholesale distribution
and manufacturing in iDempiere.

#Contact Me
'Chuck Boecking'_

chuck@chuboe.com


Note:
20130820
- updated script to use more variables
- updated script to install and launch idempiere as a service
-- use "sudo /etc/init.d/idempiere start" to start the server
-- use "sudo /etc/init.d/idempiere stop" to stop the server

.. _`Django`: http://djangoproject.com/
.. _'Chuck Boecking': http://www.chuckboecking.com/
