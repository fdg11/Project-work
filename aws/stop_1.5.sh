#!/usr/bin/env bash

# Resetting previous actions 

# Terminates instance
INSTID=$(aws ec2 describe-instance-status --filters Name=instance-state-name,Values=running --query 'InstanceStatuses[*].InstanceId')

j=0

for i in $INSTID; do

	aws ec2 terminate-instances --instance-ids $i --query 'TerminatingInstances[*].[CurrentState.Name]'
	
	while true; do	

		STATE=$(aws ec2 describe-instances --instance-ids $i --query 'Reservations[*].Instances[*].[State.Name]')

		if [ "$STATE" = "terminated" ]; then

			let j++
			break
		
		fi

	done	

done

if [ "$j" = "3" ]; then

	# Deleting a key pair
        aws ec2 delete-key-pair --key-name $KEYNAME

	# Releases the specified Elastic IP address
 	ALLOCID=$(aws ec2 describe-addresses --query 'Addresses[*].AllocationId')       
	aws ec2 release-address --allocation-id $ALLOCID

fi

echo -e "\n Undo step 1.5"



