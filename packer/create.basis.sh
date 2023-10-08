#!/bin/bash
set -x

sudo apt-get -y update
sudo apt-get install -y unzip jq mc
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp/ && sudo /tmp/aws/install
