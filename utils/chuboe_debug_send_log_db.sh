#!/bin/bash

source chuboe.properties

IDDATE2=$(date +%Y-%m-%d)
TMP_DIR=$IDDATE2-send-db-log
LOG_DIR=/var/lib/postgresql/$CHUBOE_PROP_DB_VERSION/main/log/
CHUBOE_AWS_S3_BUCKET_SUB=$CHUBOE_PROP_DEBUG_DEV_SHARE_BUCKET
CHUBOE_AWS_S3_BUCKET=s3://$CHUBOE_AWS_S3_BUCKET_SUB/

echo date2=$IDDATE2


echo copy log files to /tmp/
sudo rm -r $TMP_DIR
sudo mkdir -p $TMP_DIR

echo sudo cp $LOG_DIR/*$IDDATE2*.csv $TMP_DIR/.
sudo cp $LOG_DIR/*$IDDATE2*.csv $TMP_DIR/.

echo Push files to S3...
echo aws s3 cp $TMP_DIR/ $CHUBOE_AWS_S3_BUCKET --recursive
aws s3 cp $TMP_DIR/ $CHUBOE_AWS_S3_BUCKET --recursive

echo files sent:
ls -ltrh $TMP_DIR/*

# see chuboe_obfuscation.sh for details on how to create dev s3 buckets
