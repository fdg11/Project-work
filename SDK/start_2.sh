#!/usr/bin/env bash

#

# Volumes

export PROJECT="round-legacy-176809"
export INSTNAME="web-env"
export ZONE="europe-west1-d"
export REGION="europe-west1"
export DISKNAME="disk-2"
export SNAPSHOTNAME="step-1"

# Create and run instance web-env
gcloud compute --project $PROJECT instances create $INSTNAME --zone $ZONE \
	--machine-type "f1-micro" --subnet "default" --maintenance-policy "MIGRATE" \
	--service-account "427699182273-compute@developer.gserviceaccount.com" \
	--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
	--tags "http-server" --image "ubuntu-1604-xenial-v20170815a" --image-project "ubuntu-os-cloud" \
	--boot-disk-size "10" --boot-disk-type "pd-standard" --boot-disk-device-name $INSTNAME \
	--metadata-from-file startup-script=/admin/nginx/preinstall_nginx_php.sh --verbosity=none

# Create firewall rules
gcloud compute --project $PROJECT firewall-rules create default-allow-http \
	--network=default --allow=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

# Definition of external ip address
EXTIP=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter=name:web-env)

# Attaching an external ip address
gcloud compute addresses create web-env --addresses=$EXTIP --region $REGION

# Create an additional disk
gcloud compute --project $PROJECT disks create $DISKNAME --zone $ZONE --type=pd-standard --description=new-disk --size=10GB \
	--verbosity=none

# Attaching disk
gcloud compute instances attach-disk $INSTNAME --disk=$DISKNAME

# Create snapshot
gcloud compute --project $PROJECT disks snapshot $INSTNAME --zone $ZONE --snapshot-names $SNAPSHOTNAME

echo -e "\n extip: $EXTIP"
echo -e "Do you want to connect to the created instance via ssh? (y|N)\n"; read input_var

if echo $input_var | grep -iq "^y"; then
	gcloud compute --project $PROJECT ssh --zone $ZONE $INSTNAME
 else
	echo -e "Can use the script: ./SDK/ssh_access.sh later"
fi

