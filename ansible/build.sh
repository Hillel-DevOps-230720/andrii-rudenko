#!/bin/bash

ssh-add -D
ssh-add aws.key

cd ansible
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

ansible-playbook create.basis.yml
ansible-playbook create.db.yml --extra-vars "db_name=flask db_user=flask db_password=flask s3_name=hillel-main"
ansible-playbook create.app.yml --extra-vars "db_name=flask db_user=flask db_password=flask db_ip_local=10.100.1.132 app_key=2l0oX4nJB2NJAYal4j4xreacvKJf app_port=8000 app_url=https://github.com/saaverdo/flask-alb-app"

ansible-galaxy init roles/basis
ansible-galaxy init roles/db
ansible-galaxy init roles/app

ansible-inventory -i environments/stage/inventory.ini --list -vvv
ansible-playbook -i environments/stage/inventory.ini deploy.app.yml

cd packer
packer plugins install github.com/hashicorp/ansible
