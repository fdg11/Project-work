#!/usr/bin/env bash

# Create an instance of a virtual machine


# Check for availability VPC default
TEST=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true)
if [ ! -z "$TEST" ]; then 
	echo -e "VPC by default exists"
else
	aws ec2 create-default-vpc
fi

# VALUES
AVZ="eu-central-1b"
VPCID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true | head -1 | awk '{print $7}')
SUBNETID=$(aws ec2 describe-subnets | grep $AVZ | awk '{print $9}')
export SGNAME="WEBAccess"
export KEYNAME="fdg"
export DBSGNAME="DB_DEFAULT"
export DBIDENT="web-backend"
DBENGINE="mariadb"
DBUSER="fdg"
DBPASSWD="Qwerty23"
DBNAME="wordpress" 
AMIID="ami-1e339e71"

# Create a key pair
aws ec2 create-key-pair --key-name $KEYNAME --query 'KeyMaterial' --output text > /admin/aws/key/$KEYNAME.pem
chmod 400 /admin/aws/key/$KEYNAME.pem

# Create a security group in your VPC, and add a rule that allows SSH access from anywhere and ICMP ping
SGID=$(aws ec2 create-security-group --group-name $SGNAME --description "Security group for SSH, HTTP access and ICMP ping" --vpc-id $VPCID)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol icmp --port -1 --cidr 0.0.0.0/0

DBSGID=$(aws ec2 create-security-group --group-name $DBSGNAME --description "LOCALDB" --vpc-id $VPCID)
aws ec2 authorize-security-group-ingress --group-id $DBSGID --protocol all --port -1 --cidr 172.31.0.0/16

# Create and running instance
aws ec2 run-instances --image-id $AMIID --count 1 --instance-type t2.micro \
	--key-name $KEYNAME --security-group-ids $SGID --subnet-id $SUBNETID \
	 --user-data file:///admin/nginx/preinstall_nginx_php.sh \
	  --output table

# instanceID
while true; do  
	INSTID=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[*].Instances[*].{ID:InstanceId}')
	if [ ! -z "$INSTID" ]; then
		break
	fi
done

# Create and running RDS instance 
aws rds create-db-instance --db-instance-identifier $DBIDENT --db-instance-class db.t2.micro --engine $DBENGINE \
    --allocated-storage 5 --master-username $DBUSER --master-user-password $DBPASSWD \
     --backup-retention-period 3 --db-name $DBNAME --vpc-security-group-ids $DBSGID \
      --output table 

# Status DB-instance
while true; do
	DBSTATUS=$(aws rds describe-db-instances --db-instance-identifier $DBIDENT --query 'DBInstances[*].DBInstanceStatus')
	if [ "$DBSTATUS" = "backing-up" ]; then 
		echo -e "DB-instance ready"
		break
	else 
		echo -e "Wait DB-instance is not ready"
		sleep 25
	fi
done

# Endpoint db-instance
ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DBIDENT --query 'DBInstances[*].Endpoint.[Address]')

# Allocates an Elastic IP address
export ALLOCID=$(aws ec2 allocate-address | awk '{print $1}')

# Associates an Elastic IP address with an instance
EIPASSOCID=$(aws ec2 associate-address --instance-id $INSTID --allocation-id $ALLOCID)

# Availability Zone
AZONE=$(aws ec2 describe-instances --instance-ids $INSTID --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone]')

# Information output
ELIP=$(aws ec2 describe-addresses --filters Name=association-id,Values=$EIPASSOCID --query 'Addresses[*].[PublicIp]')

echo -e "\nTo connect, use the following command: ssh -i /admin/aws/key/$KEYNAME.pem ubuntu@$ELIP\n"
echo -e "Web Ip: $ELIP"
echo -e "Access DB ####################"
echo -e "DB-user: $DBUSER"
echo -e "DB-name: $DBNAME"
echo -e "DB-password: $DBPASSWD"
echo -e "DB-path: $ENDPOINT"



