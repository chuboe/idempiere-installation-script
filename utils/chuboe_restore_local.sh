#!/bin/bash

set -e

#When scripting use :rv chuboe_scipting.viminfo

# {{{ Context
#Bring chuboe.properties into context
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
source $SC_SCRIPTPATH/chuboe.properties

SC_LOGFILE="$SC_SCRIPTPATH/LOGS/$SC_BASENAME."`date +%Y%m%d`_`date +%H%M%S`".log"
SC_ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
SC_UTIL=$CHUBOE_PROP_UTIL_PATH
SC_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
SC_LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
SC_USER=$CHUBOE_PROP_DB_USERNAME

SC_ADDPG="-h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT"
SC_DATABASE=$CHUBOE_PROP_DB_NAME
SC_IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
SC_BACKUP_TAR="ExpDatDir_"`date +%Y%m%d`_`date +%H%M%S`".tar"
# You may update the number of cores used from default below
SC_BACKUP_RESTORE_JOBS=$CHUBOE_PROP_BACKUP_RESTORE_JOBS
SC_UNTAR="N"
SC_UNTAR_PATH=""
# }}}

# {{{ Options
SC_OPTSTRING="hf:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-h    Help"
            echo "-f    specify path to tar, either relative to $SC_LOCALBACKDIR or absolute"
            exit 0
            ;;

	f) SC_UNTAR="Y" ; SC_UNTAR_PATH=${OPTARG} ;;
    esac
done
# }}}

# {{{ Logging
echo "Be sure to tee to a log file, for example:"
echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
read -p "press Enter to continue, or Ctrl+C to stop" 
#REMEMBER when calling these scripts from other scripts use "echo $'\n' | #####.sh" to bypass read }}}

if [ $SC_UNTAR = "Y" ] # {{{
then
	echo $'\n' | $SC_SCRIPTPATH/chuboe_untar_local.sh -f $SC_UNTAR_PATH
fi #}}}

cd $SC_LOCALBACKDIR

sudo service idempiere stop

dropdb $SC_ADDPG -U $SC_USER $SC_DATABASE || echo IDEMPIERE DB NOT THERE!
createdb $SC_ADDPG -U $SC_USER $SC_DATABASE 
pg_restore $SC_ADDPG -vU $SC_USER -d $SC_DATABASE -j $SC_BACKUP_RESTORE_JOBS latest/

sudo service idempiere start

# {{{ reference for quick restore on very large databases
#This code will extract out the restore instructions from a pg_dump that used the -df option
#The below statements remove the instructions that populate the tables

#pg_restore -l  -Fd /home/chuboe-catch/catch/db_full/ | sed '/MATERIALIZED VIEW DATA/d' > ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere.*deleteme.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere.*delme.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_pinstance.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere t_.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere r_requestupdate.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere r_requestaction.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere chuboe_trialbalance.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere chuboe_validation.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_wf_process.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_wf_activity.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_wf_eventaudit.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_changelog.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_attachment.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere fact_acct_s.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere fact_acct.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_usermail.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere ad_issue.*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere dms_association .*/d' ~/delme/restore_ordered.lst
#sed -i '/TABLE DATA adempiere dms_content .*/d' ~/delme/restore_ordered.lst

#pg_restore -L ~/delme/restore_ordered.lst -v -U adempiere -d idempiere -Fd -j 3 /home/chuboe-catch/catch/db_full/
# )))
