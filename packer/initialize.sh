#!/bin/bash
echo "Prepare environment"
set -o allexport; source /home/ubuntu/app.env; set +o allexport

echo "Create application"
mkdir app && cd app
git clone https://github.com/saaverdo/flask-alb-app .
echo -e '\nvenv/\n*.sock' >> .gitignore

echo "Create database"
sudo mysql -u root <<EOF
CREATE DATABASE $MYSQL_DB;
CREATE USER $MYSQL_USER IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO $MYSQL_USER;
FLUSH PRIVILEGES;
EOF

echo "Prepare virtual environment"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "Configuring Gunicorn as service"
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=Gunicorn instance to serve flask
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/app
Environment="PATH=/home/ubuntu/app/venv/bin"
EnvironmentFile=/home/ubuntu/app.env
ExecStart=/home/ubuntu/app/venv/bin/gunicorn --workers 1 --bind unix:app.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

echo "Configuring Nginx to Proxy Requests"
sudo tee /etc/nginx/sites-available/flask.local >/dev/null <<EOF
server {
    listen $PROXY_PORT default_server;
    listen [::]:$PROXY_PORT default_server;

    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/app/app.sock;
    }
}
EOF

sudo chmod 755 /home/ubuntu/
sudo ln -s /etc/nginx/sites-available/flask.local /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx
