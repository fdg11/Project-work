#!/usr/bin/env bash

#Update && Upgrade;
#Base utils install;
#AWSCLI install
#Google Cloud CLI install
#IPV6 disable;

DIR='/admin'
echo -e "Enter PUB_KEY(In RSA format):\n"; read PUB_KEY

# Checking for an empty value
if [ -z "$PUB_KEY" ]; then
	echo -e "The public key variable in the script body is not defined!"
	exit 1
fi

# Update & upgrade & base utils install:
apt-get update && apt upgrade -y 
apt-get install wget curl git htop atop build-essential tree python-pip groff vim -y
apt-get autoremove -y && apt-get autoclean && apt-get clean
 
# Default dir:
if [ ! -d "$DIR" ]; then
	mkdir $DIR
fi
echo "cd $DIR" >> ~/.bashrc

# Install awscli & SDK google
git clone https://github.com/fdg11/Project-work.git $DIR
cd /$DIR
 ./install-scripts/awscli-install.sh
 ./install-scripts/SDK-install.sh

# Permit root login by the key:
mkdir -p /root/.ssh
touch ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
echo $PUB_KEY >> ~/.ssh/authorized_keys
sed -i '/#AuthorizedKeysFile/s/#//' /etc/ssh/sshd_config
sed -i '/#PasswordAuthentication/s/#//;/PasswordAuthentication/s/yes/no/' /etc/ssh/sshd_config
service ssh restart

# IPv6 disable:
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub
update-grub

# Show ips:
echo -e "\nNetworks:\n"
ip a | grep inet" "

echo -e "\nReboot now? (y|N)\n"; read input_var

if echo $input_var | grep -iq "^y"; then
	reboot
 else
	echo -e "\nDon't forget to do that\n"
fi
