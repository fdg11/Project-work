#!/usr/bin/env bash

# Install AWSCLI

# Update pip
pip install --upgrade pip

# Install awscli  
pip install awscli --upgrade --user

# Add an export path to profile script.
echo "export PATH=~/.local/bin:$PATH" >> ~/.profile
echo "complete -C '/root/.local/bin/aws_completer' aws" >> ~/.profile

# Load the profile
source ~/.profile

# Version
echo -e ""
echo -e "$(aws --version)"
sleep 8
