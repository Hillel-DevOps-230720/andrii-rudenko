#!/bin/bash
set -x

sudo apt-get -y install mariadb-server

# Injected environment variables:
# MYSQL_DB
# MYSQL_USER
# MYSQL_PASSWORD
# S3_NAME

# Injected source files:
# .environment -> /home/ubuntu/.environment
# backup.sh -> /home/ubuntu/backup.sh
# backup.timer -> /etc/systemd/system/backup.timer
# backup.service -> /etc/systemd/system/backup.service
# update.sh -> /home/ubuntu/update.sh
# update.service -> /etc/systemd/system/update.service

envsubst < /tmp/.environment > /home/ubuntu/.environment
cp /tmp/backup.sh /home/ubuntu/backup.sh
sudo cp /tmp/backup.timer /etc/systemd/system/backup.timer
sudo cp /tmp/backup.service /etc/systemd/system/backup.service
cp /tmp/update.sh /home/ubuntu/update.sh
sudo cp /tmp/update.service /etc/systemd/system/update.service

chmod +x /home/ubuntu/backup.sh
chmod +x /home/ubuntu/update.sh

sudo mysql -u root <<EOF
CREATE DATABASE $MYSQL_DB;
CREATE USER $MYSQL_USER IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO $MYSQL_USER;
FLUSH PRIVILEGES;
EOF

sudo sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl enable backup.timer
sudo systemctl enable update
