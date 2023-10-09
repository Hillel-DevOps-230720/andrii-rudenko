#!/bin/bash
DB_IP_LOCAL="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
aws ssm put-parameter --name "/hillel/db/ip/local" --type "String" --value "$DB_IP_LOCAL" --overwrite
