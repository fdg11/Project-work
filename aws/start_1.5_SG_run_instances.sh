#!/usr/bin/env bash

#
# VALUES
VPCID=$(aws ec2 describe-vpcs --filter Name=tag:Name,Values=NAT --query 'Vpcs[*].VpcId')
AVZ="eu-central-1b"
SUBNETID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values="Private subnet" --query 'Subnets[*].SubnetId')
SGNAME="SSHAccess"
SGNAME_LOCAL="LOCAL"
AMIID="ami-1e339e71"

# Create a security group in your VPC, and add a rule that allows SSH access from anywhere and ICMP ping
SGID=$(aws ec2 create-security-group --group-name $SGNAME --description "Security group for SSH access and ICMP ping" --vpc-id $VPCID)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol icmp --port -1 --cidr 0.0.0.0/0

INSTID=$(aws ec2 describe-instances --filters Name=key-name,Values=NAT Name=instance-state-name,Values=running --query 'Reservations[*].Instances[*].[InstanceId]')
aws ec2 modify-instance-attribute --instance-id $INSTID --groups $SGID

# Create a security group in your VPC, and add a rule that allows SSH access from anywhere and ICMP ping
SGID_LOCAL=$(aws ec2 create-security-group --group-name $SGNAME_LOCAL --description "Local network access" --vpc-id $VPCID)
aws ec2 authorize-security-group-ingress --group-id $SGID_LOCAL --protocol all --port -1 --cidr 10.0.0.0/16

# Create and running instances
aws ec2 run-instances --image-id $AMIID --count 2 --instance-type t2.micro \
	--key-name $KEYNAME --security-group-ids $SGID_LOCAL --subnet-id $SUBNETID \
	 --output table 

PUBLICIP=$(aws ec2 describe-instances --instance-ids $INSTID --query 'Reservations[*].Instances[*].[PublicIpAddress]')

scp -i aws/key/$KEYNAME.pem aws/key/$KEYNAME.pem ec2-user@$PUBLICIP: &> /dev/null
echo -e "\n NAT instance: ssh -i aws/key/$KEYNAME.pem ec2-user@$PUBLICIP"
echo -e "\n local network instances: ssh -i $KEYNAME.pem ubuntu@X.X.X.X"

