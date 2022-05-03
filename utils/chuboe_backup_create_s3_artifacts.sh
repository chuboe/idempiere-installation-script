#!/bin/bash

#Summary
#The purpose of this file is to make creating aws s3 backup up artifacts easier and more standardized
#Update the chuboe_backup_awscli.sh file with the results of this file

#references - s3
#https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
#https://docs.aws.amazon.com/cli/latest/reference/s3api/put-object-lock-configuration.html

#references - iam-policy
#https://stackoverflow.com/questions/59103954/how-to-create-a-policy-using-the-aws-cli

#variables
COMPANY_NAME=delme07 #changeme
APPLICATION_NAME=idempiere
DEVELOPMENT_TEAM_NAME=logilite #changeme
COMPLIANCE_DAYS=50 #changeme
COMPLIANCE_YEARS=0
REGION="us-east-1"

#variables derived
BUCKET_NAME_LATEST="$COMPANY_NAME-$APPLICATION_NAME-latest"
BUCKET_NAME_ARCHIVE="$COMPANY_NAME-$APPLICATION_NAME-archive"
BUCKET_NAME_OBFUSCATE="$COMPANY_NAME-$APPLICATION_NAME-obfuscate"

POLICY_WRITER_NAME="s3-$COMPANY_NAME-$APPLICATION_NAME-bucket-writer"
POLICY_DEVELOPER_NAME="s3-$COMPANY_NAME-$APPLICATION_NAME-$DEVELOPMENT_TEAM_NAME-bucket-developer"

IAM_WRITER_NAME=""
IAM_DEVELOPER_NAME=""

DELETEME=$1

#delete resources and exit if requested - makes for easy testing and cleanup
if [ "$DELETEME" == "deleteme" ]
then
    aws s3api delete-bucket --bucket $BUCKET_NAME_LATEST
    aws s3api delete-bucket --bucket $BUCKET_NAME_ARCHIVE
    aws s3api delete-bucket --bucket $BUCKET_NAME_OBFUSCATE

	#aws iam delete-policy --policy-arn "arn:aws:s3:::'$BUCKET_NAME_OBFUSCATE'/*"
	#aws iam delete-policy --policy-arn "arn:aws:s3:::'$BUCKET_NAME_OBFUSCATE'/*"

    exit 0
fi

#create policy for writing to buckets
echo "creating policy named: $POLICY_WRITER_NAME"
aws iam create-policy \
    --policy-name "$POLICY_WRITER_NAME" \
    --policy-document \
'{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:ListBucketMultipartUploads",
                "s3:GetObjectRetention",
                "s3:ListBucketVersions",
                "s3:GetObjectTagging",
                "s3:ListBucket",
                "s3:GetObjectLegalHold",
                "s3:ListMultipartUploadParts",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::'$BUCKET_NAME_LATEST'",
                "arn:aws:s3:::'$BUCKET_NAME_LATEST'/*",
                "arn:aws:s3:::'$BUCKET_NAME_ARCHIVE'",
                "arn:aws:s3:::'$BUCKET_NAME_ARCHIVE'/*",
                "arn:aws:s3:::'$BUCKET_NAME_OBFUSCATE'",
                "arn:aws:s3:::'$BUCKET_NAME_OBFUSCATE'/*"
            ]
        }
    ]
}' \
| tee $POLICY_WRITER_NAME

#create policy for development team reading from buckets
echo "creating policy named: $POLICY_DEVELOPER_NAME"
aws iam create-policy \
    --policy-name "$POLICY_DEVELOPER_NAME" \
    --policy-document \
'{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::'$BUCKET_NAME_OBFUSCATE'",
                "arn:aws:s3:::'$BUCKET_NAME_OBFUSCATE'/*"
            ]
        }
    ]
}' \
| tee $POLICY_DEVELOPER_NAME


#create iam for backup writer


#create iam for development team reader


#assign policy to backup writer


#assign policy to development team


#create bucket latest
echo "creating bucket named: $BUCKET_NAME_LATEST"
aws s3api create-bucket --bucket $BUCKET_NAME_LATEST --region $REGION
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME_LATEST \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

#create bucket archive
echo "creating bucket named: $BUCKET_NAME_ARCHIVE"
aws s3api create-bucket --bucket $BUCKET_NAME_ARCHIVE --region $REGION --object-lock-enabled-for-bucket
aws s3api put-object-lock-configuration \
	--bucket $BUCKET_NAME_ARCHIVE \
	--object-lock-configuration '{ "ObjectLockEnabled": "Enabled", "Rule": { "DefaultRetention": { "Mode": "COMPLIANCE", "Days": 50 }}}'
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME_ARCHIVE \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

#create bucket obfuscate
echo "creating bucket named: $BUCKET_NAME_OBFUSCATE"
aws s3api create-bucket --bucket $BUCKET_NAME_OBFUSCATE --region $REGION
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME_OBFUSCATE \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
