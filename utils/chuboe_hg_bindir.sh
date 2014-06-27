#!/bin/bash
# Created Version 1 Chuck Boecking

######################################
# The purpose of this script is to help make sure the idempiere server directory only changes when you desire it.
# In other words, you should be able to quick unwind changes caused by accident, hacks, and malicious behavior.
# This script basically adds the server directory to an hg (mercurial) repository. 
# You can then push change logs to a remote mercurial repository like bitbucket.org
# If a hacker compromises your site, just unwind their changes using standard mercurial commands.
######################################

INSTALLPATH="/opt/idempiere-server/"
IGNORENAME=".hgignore"
HGNAME=".hgrc"

# (1) create the .hgignore file
echo "">$INSTALLPATH/$IGNORENAME
sed -i '$ a\syntax: glob' $INSTALLPATH/$IGNORENAME
sed -i '$ a\chuboe_backup' $INSTALLPATH/$IGNORENAME
sed -i '$ a\chuboe_restore' $INSTALLPATH/$IGNORENAME
sed -i '$ a\chuboe_temp' $INSTALLPATH/$IGNORENAME
sed -i '$ a\log' $INSTALLPATH/$IGNORENAME
sed -i '$ a\*.tmp*' $INSTALLPATH/$IGNORENAME

# (2) create the .hgrc file if does not already exist
cd
RESULT=$(ls -l .hgrc | wc -l)
if [ $RESULT -ge 1 ]; 
then
	echo "HERE: .hgrc already exists"
else
	echo "HERE: creating .hgrc file"
	echo "">$HGNAME
	sudo sed -i '$ a\[ui]' $HGNAME
	sudo sed -i '$ a\username = iDempiere Master' $HGNAME
fi #end if migration.zip exists

# (3) commit the repository
cd $INSTALLPATH
hg init
hg add
hg commit -m "Initial Commit"

# (4) offer a script to commit and push changed/added/removed files off-machine
# coming soon.... for now just issue: hg push 'path to remote repo'

# if you ever want to undo a change that has not been committed, you can issue: hg revert --all
# if you want to revert to a previous commit, you can use: hg revert --all --rev [xxx]
# for more information, here is a great summary: http://stackoverflow.com/questions/2540454/mercurial-revert-back-to-old-version-and-continue-from-there