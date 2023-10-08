#!/bin/bash
MYSQL_HOST="$(aws ssm get-parameter --name "/hillel/db/ip/local" --query Parameter.Value --output text)"
sed -i "s/^MYSQL_HOST=.*/MYSQL_HOST=${MYSQL_HOST}/" /home/ubuntu/.environment
