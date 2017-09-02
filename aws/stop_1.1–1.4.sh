#!/usr/bin/env bash

# Resetting previous actions 

# Terminates instance
INSTID=$(aws ec2 describe-instance-status --filters Name=instance-state-name,Values=running --query 'InstanceStatuses[*].InstanceId')
aws ec2 terminate-instances --instance-ids $INSTID --query 'TerminatingInstances[*].[CurrentState.Name]'

# Checking the status
while true; do

	STATE=$(aws ec2 describe-instances --instance-ids $INSTID --query 'Reservations[*].Instances[*].[State.Name]')

	if [ "$STATE" = "terminated" ]; then

		# Deleting a security group
		aws ec2 delete-security-group --group-name $SGNAME	
		
		# Deleting a key pair
		aws ec2 delete-key-pair --key-name $KEYNAME
		
		# Releases the specified Elastic IP address
		aws ec2 release-address --allocation-id $ALLOCID
		
		# Deletes  the  specified EBS volume 
		aws ec2 delete-volume --volume-id $VOLID
		
		break

	fi

done

