#!/bin/bash
set -x

sudo apt-get -y install nginx
sudo apt-get -y install python3-pip python3.10-venv default-libmysqlclient-dev build-essential pkg-config

# Injected environment variables:
# MYSQL_DB
# MYSQL_USER
# MYSQL_PASSWORD
# MYSQL_HOST
# SECRET_KEY
# APP_PORT
# APP_URL

# Injected source files:
# .environment -> /home/ubuntu/.environment
# app.service -> /etc/systemd/system/app.service
# app.conf -> /etc/nginx/sites-available/app.conf
# update.sh -> /home/ubuntu/update.sh
# update.service -> /etc/systemd/system/update.service

envsubst < /tmp/.environment > /home/ubuntu/.environment
sudo cp /tmp/app.service /etc/systemd/system/app.service
sudo cat /tmp/app.conf | envsubst | sudo sh -c "exec cat > /etc/nginx/sites-available/app.conf"
sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
cp /tmp/update.sh /home/ubuntu/update.sh
sudo cp /tmp/update.service /etc/systemd/system/update.service

sudo chmod 755 /home/ubuntu/
chmod +x /home/ubuntu/update.sh

mkdir app && cd app || exit 1
git clone "$APP_URL" .
python3 -m venv venv
# shellcheck source=/dev/null
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

sudo systemctl enable app
sudo systemctl enable update
