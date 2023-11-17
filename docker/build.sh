#!/bin/bash
sudo docker run -d --rm --name mariadb -p 3306:3306 \
  -e MARIADB_ROOT_PASSWORD=superpass \
  -v db_vol:/var/lib/mysql \
  --network-alias=db_server \
  mariadb
sudo docker exec -it mariadb bash
mariadb -uroot -psuperpass -e \ "CREATE USER IF NOT EXISTS 'flask'@'%' IDENTIFIED BY 'flask'; \
  CREATE DATABASE IF NOT EXISTS flask; \
  GRANT ALL ON flask.* TO 'flask'@'%';"

chmod +x entrypoint.sh
hadolint Dockerfile
sudo docker build -t app .
sudo docker run -d --rm --name app -p 8000:8000 --link mariadb:db_server app

sudo docker login -u konstantait
sudo docker tag app:latest konstantait/app:stage
sudo docker push konstantait/app:stage

aws ecr get-login-password --region eu-central-1 | sudo docker login --username AWS --password-stdin 972244147361.dkr.ecr.eu-central-1.amazonaws.com
sudo docker tag app:latest 972244147361.dkr.ecr.eu-central-1.amazonaws.com/hillel:latest

sudo docker system prune -a
