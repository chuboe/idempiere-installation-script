#!/bin/bash
set -e

# {{{ Versions
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
# Version 3 Chuck Boecking - added more variables
# Version 4 Chuck Boecking - fixed bug where script copied multiple files to latest
# Version 5 Chris Greene - Changed to use AWS CLI
# }}}

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
SC_LOCALBACKARCHIVEDIR="$CHUBOE_PROP_BACKUP_LOCAL_PATH/archive"
SC_LOCALBACKLATESTDIR="$CHUBOE_PROP_BACKUP_LOCAL_PATH/latest"
SC_ARCHIVEBUCKET=$CHUBOE_PROP_BACKUP_ARCHIVE_S3_BUCKET
SC_LATESTBUCKET=$CHUBOE_PROP_BACKUP_LATEST_S3_BUCKET
SC_IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
# }}}

# {{{ Options
# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line
# the colon after the letter specifies there should be text with the option

# Step #1 - set the variables in SC_OPTSTRING
SC_OPTSTRING="hp:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-h    Help"
            exit 0
            ;;

        p) echo "You didn't overwrite the stock prefix did you? I don't know what to do with ${OPTARG}";;
    esac
done
#}}}

# {{{ Logging
echo "Be sure to tee to a log file, for example:"
echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
read -p "press Enter to continue, or Ctrl+C to stop" 
#REMEMBER when calling these scripts from other scripts use "echo $'\n' | $SC_SCRIPTPATH/#####.sh" to bypass read }}}

echo Calling $SC_SCRIPTPATH/chuboe_backup_local.sh #{{{
echo $'\n' | $SC_SCRIPTPATH/chuboe_backup_local.sh
echo End $SC_SCRIPTPATH/chuboe_backup_local.sh #}}}

aws s3 sync "$SC_LOCALBACKARCHIVEDIR"/ s3://"$SC_ARCHIVEBUCKET"/ 
aws s3 sync "$SC_LOCALBACKLATESTDIR"/ s3://"$SC_LATESTBUCKET"/ --delete 

# {{{ Example IAM
# Below is an example AWS IAM Permission Policy that is compatible with this script. Note not all below permissions are necessary
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Sid": "VisualEditor0",
#            "Effect": "Allow",
#            "Action": [
#                "s3:PutObject",
#                "s3:GetObjectAcl",
#                "s3:GetObject",
#                "s3:ListBucketMultipartUploads",
#                "s3:GetObjectRetention",
#                "s3:ListBucketVersions",
#                "s3:GetObjectTagging",
#                "s3:ListBucket",
#                "s3:GetObjectLegalHold",
#                "s3:ListMultipartUploadParts"
#            ],
#            "Resource": [
#                "arn:aws:s3:::CHANGETOARCHIVEBUCKET",
#                "arn:aws:s3:::CHANGETOARCHIVEBUCKET/*"
#            ]
#        },
#        {
#            "Sid": "VisualEditor1",
#            "Effect": "Allow",
#            "Action": [
#                "s3:PutObject",
#                "s3:GetObjectAcl",
#                "s3:GetObject",
#                "s3:ListBucketMultipartUploads",
#                "s3:GetObjectRetention",
#                "s3:ListBucketVersions",
#                "s3:GetObjectTagging",
#                "s3:ListBucket",
#                "s3:GetObjectLegalHold",
#                "s3:DeleteObject",
#                "s3:ListMultipartUploadParts"
#            ],
#            "Resource": [
#                "arn:aws:s3:::CHANGETOLATESTBUCKET/*",
#                "arn:aws:s3:::CHANGETOLATESTBUCKET"
#            ]
#        },
#        {
#            "Sid": "VisualEditor2",
#            "Effect": "Allow",
#            "Action": [
#                "s3:ListStorageLensConfigurations",
#                "s3:GetAccessPoint",
#                "s3:GetAccountPublicAccessBlock",
#                "s3:ListAllMyBuckets",
#                "s3:ListAccessPoints",
#                "s3:ListJobs"
#            ],
#            "Resource": "*"
#        }
#    ]
#}
#}}}
