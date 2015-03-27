#!/bin/bash
# Created Version 1 Chuck Boecking
# 1.1 - Chuck Boecking - update to run repeatedly in cron to create daily commits

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

# (1) create the .hgrc file if does not already exist
cd
RESULT=$(ls -l $HGNAME | wc -l)
if [ $RESULT -ge 1 ]; 
then
	echo "HERE: $HGNAME already exists"
else
	echo "HERE: creating $HGNAME file"
	echo "">$HGNAME
	echo "[ui]">>$HGNAME
	echo "username = iDempiere Master">>$HGNAME
	echo "">>$HGNAME
	echo "[extensions]">>$HGNAME
	echo "purge =">>$HGNAME
	echo "hgext.mq =">>$HGNAME
	echo "extdiff =">>$HGNAME
fi #end if .hgrc file exists

# (2) create the .hgignore file
cd $INSTALLPATH
RESULT=$(ls -l $IGNORENAME | wc -l)
if [ $RESULT -ge 1 ]; 
then
	echo "HERE: $IGNORENAME already exists"
	echo "HERE: perform addremove and commit"
	hg addremove
	hg commit -m "Daily Commit"
else
	echo "HERE: creating $IGNORENAME file"
	echo "syntax: glob" >> $INSTALLPATH/$IGNORENAME
	echo "log" >>  $INSTALLPATH/$IGNORENAME
	echo "data/*" >>  $INSTALLPATH/$IGNORENAME
	echo "*.tmp*" >>  $INSTALLPATH/$IGNORENAME
	echo "HERE: perform init, add, and commit"
	hg init
	hg add
	hg commit -m "Initial Commit"
fi #end if .hgignore file exists

# (3) when you create a private remote repository, uncommend the below command and update the URL
# hg push www.url_to_remote_repository

# to see what has changed since the last commit, issue: hg status
# if you ever want to undo a change that has not been committed, you can issue: hg revert --all (you can also use hg purge)
# if you want to revert to a previous commit, you can use: hg revert --all --rev [xxx]
# for more information, here is a great summary: http://stackoverflow.com/questions/2540454/mercurial-revert-back-to-old-version-and-continue-from-there