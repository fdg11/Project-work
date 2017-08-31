#!/usr/bin/env bash

# Create an instance of a virtual machine
# Add a hard disk to the instance
# Add "white IP" to the instance
# Configure the firewall, open / close the port on AWS for the instance

# Check for availability VPC default
aws ec2 describe-vpcs --filters Name=isDefault,Values=true &> /dev/null
if [ "$?" = 0 ]; then 
	echo -e "VPC by default exists"
else
	aws ec2 create-default-vpc
fi

# VALUES
VPCID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true | head -1 | awk '{print $7}')
SUBNETID=$(aws ec2 describe-subnets | grep eu-central-1b | awk '{print $9}')
KEYNAME="fdg"
AMIID="ami-1e339e71"

# Create a key pair
aws ec2 create-key-pair --key-name $KEYNAME --query 'KeyMaterial' --output text > /admin/aws/key/$KEYNAME.pem
chmod 400 /admin/aws/key/$KEYNAME.pem

# Create a security group in your VPC, and add a rule that allows SSH access from anywhere and ICMP ping
SGID=$(aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access and ICMP ping" --vpc-id $VPCID)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol icmp --port -1 --cidr 0.0.0.0/0

# Create and running instance
aws ec2 run-instances --image-id $AMIID --count 1 --instance-type t2.micro \
	--key-name $KEYNAME --security-group-ids $SGID --subnet-id $SUBNETID --output table

# instanceID
while true; do  
	INSTID=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[*].Instances[*].{ID:InstanceId}')
	if [ ! -z "$INSTID" ]; then
		break
	fi
done

# Allocates an Elastic IP address
ALLOCID=$(aws ec2 allocate-address | awk '{print $1}')

# Associates an Elastic IP address with an instance
EIPASSOCID=$(aws ec2 associate-address --instance-id $INSTID --allocation-id $ALLOCID)

# Availability Zone
AZONE=$(aws ec2 describe-instances --instance-ids $INSTID --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone]')

# Create and attach volume an instance
VOLID=$(aws ec2 create-volume --size 30 --availability-zone $AZONE --volume-type gp2 | awk '{print $7}')
aws ec2 attach-volume --volume-id $VOLID --instance-id $INSTID --device /dev/sdf


