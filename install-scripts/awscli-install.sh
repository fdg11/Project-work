#!/usr/bin/env bash

# Install AWSCLI

# Update pip
pip install --upgrade pip

# Install awscli  
pip install awscli --upgrade --user

# Add an export path to profile script.
echo "export PATH=~/.local/bin:$PATH" >> ~/.profile

# Load the profile
source ~/.profile

# Version
echo $(aws --version)

