#!/bin/bash
#The purpose of this script is to create self-signed certificates for apache.
#You man run this script as many times as you wish.
#Each execution overwrites the previous certs.
#Note that you need to restart apache2 service after each execution to have the new certificates recognized.

#Update the below as you deem appropriate
country="XX"
state="XX"
locality="XX"
organization="idempiere"
organizationalunit="trainig"
commonname="XX"
email="XX"

#Creates a cert that is valid for 10 years
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" \
-keyout /etc/ssl/private/apache-selfsigned.key \
-out /etc/ssl/certs/apache-selfsigned.crt

