#!/bin/bash
# This script querys the IP address of an Elastic Load balancer, and updates it in the HOSTS file
ELB_DNS_NAME="PATHtoELB.elb.amazonaws.com"
IP_ADDRESS=$(nslookup $ELB_DNS_NAME | grep -A 1 "Name:" | tail -n 1 | awk '{print $2}')
URL="url.example.com"
HOSTS_FILE="/etc/hosts"
# Check if the entry already exists in the hosts file
if grep "$URL" $HOSTS_FILE; then
    # Replace the existing entry
    TMP_FILE="/tmp/hosts_tmp"
    # Save the first 9 lines to a temporary file
    head -n 9 $HOSTS_FILE > $TMP_FILE
    # Append the new line
    echo "$IP_ADDRESS $KNOWLEDGE_URL" >> $TMP_FILE
    # Replace the original file with the updated content
    mv $TMP_FILE $HOSTS_FILE
else
    # Add a new entry
    echo "$IP_ADDRESS $KNOWLEDGE_URL" >> $HOSTS_FILE
fi