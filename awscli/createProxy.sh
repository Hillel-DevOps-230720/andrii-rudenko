#!/bin/bash
apt-get update
apt-get install -y awscli jq git nginx
systemctl enable nginx
export ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
export AWS_DEFAULT_REGION=${ZONE::-1}
export PROXY_PORT=$(aws ssm get-parameter --name "proxy_port_awscli" | jq -r ".Parameter.Value")
sed -i "s|80 default_server|$PROXY_PORT default_server|g" /etc/nginx/sites-available/default
sudo systemctl reload nginx
