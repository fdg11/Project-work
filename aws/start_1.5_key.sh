#!/usr/bin/env bash

#

# VALUES
export KEYNAME="NAT"

# Create a key pair
aws ec2 create-key-pair --key-name $KEYNAME --query 'KeyMaterial' --output text > /admin/aws/key/$KEYNAME.pem
chmod 400 /admin/aws/key/$KEYNAME.pem
