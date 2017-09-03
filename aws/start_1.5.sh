#!/usr/bin/env bash

#
AVZ="eu-central-1b"

VPCID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.[VpcId])
aws ec2 modify-vpc-attribute --vpc-id $VPCID --enable-dns-hostnames '{"Value":true}'
SUBNETID=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.1.0/24 --availability-zone $AVZ --query Subnet.[SubnetId])


export SGNAME="SSHAccess"
export KEYNAME="fdg"
AMIID="ami-1e339e71"

# Create a key pair
aws ec2 create-key-pair --key-name $KEYNAME --query 'KeyMaterial' --output text > /admin/aws/key/$KEYNAME.pem
chmod 400 /admin/aws/key/$KEYNAME.pem

# Create a security group in your VPC, and add a rule that allows SSH access from anywhere and ICMP ping
SGID=$(aws ec2 create-security-group --group-name $SGNAME --description "Security group for SSH access and ICMP ping" --vpc-id $VPCID)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol icmp --port -1 --cidr 0.0.0.0/0


aws ec2 run-instances --image-id $AMIID --count 2 --instance-type t2.micro \
	--key-name $KEYNAME --security-group-ids $SGID --subnet-id $SUBNETID \
	--output table

