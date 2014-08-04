#!/bin/sh

# Created per this thread :https://forums.aws.amazon.com/thread.jspa?threadID=92092
# to solve a hostname resolution issue in ubuntu in AWS VPC
# Without running this file, iDempiere will not install inside a VPC

insert_point="# vpc dhcp hostname"

if grep -q "$insert_point" /etc/hosts; then
  sed -i "/$insert_point/{n; s/.*/127.0.0.1 $(hostname)/}" /etc/hosts
else
  echo "
$insert_point
127.0.0.1 $(hostname)" >>/etc/hosts
fi