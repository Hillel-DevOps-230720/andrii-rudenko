
# Flask Applications with Gunicorn and Nginx

## Prepare environment

```bash
sudo curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com jammy main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt update && sudo apt install packer
packer plugins install github.com/hashicorp/amazon
mkdir packer && cd packer
```

Создадим файл с переменными окружения для передачи в новый образ. Эти переменные будут использоваться как для создания базы данных приложения, так и для передачи процессу gunicorn, работающего как сервис:

<details>
  <summary>app.env</summary>

```bash
MYSQL_USER=flask
MYSQL_PASSWORD=<YOUR PASSWORD>
MYSQL_DB=flask
MYSQL_HOST=127.0.0.1
SECRET_KEY=<YOUR SECRET KEY>
PROXY_PORT=8000
```

</details>

## Packer configuration file

Разработаем близкий к immutable образ с работающим в виртуальном окружении flask приложением. Нужно будет только обновлять приложение, ставить новые версии пакетов, иногда чистить pycache. Для его создания будем использовать кастомизированный образ t2.micro с Ubuntu 22.04 и root-разделом размером 4 Gb:

<details>
  <summary>app.pkr.hcl</summary>

```
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "base_ami" {
  type    = string
  default = "${env("AWS_ID_AMI_UNUNTU22_4G")}"
}

variable "instance_size" {
  type    = string
  default = "t2.micro"
}

variable "region" {
  type    = string
  default = "${env("AWS_DEFAULT_REGION")}"
}

source "amazon-ebs" "flask" {
  ami_name      = "ubuntu22-flask"
  instance_type = "${var.instance_size}"
  region        = "${var.region}"
  source_ami    = "${var.base_ami}"
  ssh_timeout   = "10m"
  ssh_username  = "ubuntu"
  tags = {
    BuiltBy  = "Packer"
    OS       = "Ubuntu 22.04 with 4 Gb root partition"
    Project  = "Devops"
    ami_type = "Flask applications with Gunicorn and Nginx"
  }
}

build {
  sources = ["source.amazon-ebs.flask"]

  provisioner "file" {
    destination = "/home/ubuntu/app.env"
    source      = "app.env"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get remove -y needrestart",
      "sudo apt-get update -y",
      "sudo apt-get install -y git mariadb-server",
      "sudo apt-get install -y unzip jq",
      "sudo apt-get install -y python3-pip python3.10-venv default-libmysqlclient-dev build-essential pkg-config",
      "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip",
      "unzip /tmp/awscliv2.zip -d /tmp/ && sudo /tmp/aws/install",
      "sudo apt-get install -y nginx"
    ]
  }

  provisioner "shell" {
    execute_command = "{{ .Path }}"
    script          = "initialize.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}

```

</details>

## AMI Initialization Scripts

<details>
  <summary>initialize.sh</summary>

```bash
#!/bin/bash
echo "Prepare environment"
set -o allexport; source /home/ubuntu/app.env; set +o allexport

echo "Create application"
mkdir app && cd app
git git clone https://github.com/saaverdo/flask-alb-app -b alb app
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
sudo usermod -a -G www-data ubuntu
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
```

</details>

## Build image and run instance from custom AMI

Перед созданием образа нужно проверить имеет ли дефолтная vpc выход в сеть. В моем случае packer прицепился к vpc default без дефолтного маршрута на шлюз. В итоге я долго ждал `Waiting for SSH to become available...`, читал маны и пробовал `"temporary_key_pair_type": "ed25519"`. Можно прописать в кофигурационном файле созданные пользователем vpc, subnet, security group, IAM profile.

```bash
packer build app.pkr.hcl

export AWS_ID_AMI_FLASK=$(jq -r '.builds[-1].artifact_id' manifest.json | cut -d ":" -f2) && cd ..

export AWSCLI_ID_AMI_PROXY=$AWS_ID_AMI_FLASK

export AWSCLI_ID_I_PROXY=$(aws ec2 run-instances \
    --cli-input-yaml "$(envsubst < ./awscli/i-proxy.yaml)" \
    --user-data ./packer/backup.sh | jq -r ".Instances[].InstanceId")
```

Скрипт для создания сервиса бэкапа базы по расписанию:

<details>
  <summary>backup.sh</summary>

```bash
tee /home/ubuntu/backupSQLtoS3.sh >/dev/null <<"EOF"
#!/bin/bash
BUCKET_NAME="awscli-main"
BACKUP_NAME="backup-flask-$(date +%Y-%m-%d-%H-%M-%S).sql.gz"
mysqldump -h $MYSQL_HOST -P 3306 -u $MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DB | gzip > /tmp/${BACKUP_NAME}
aws s3 cp /tmp/${BACKUP_NAME} s3://${BUCKET_NAME}/backups/flask/${BACKUP_NAME}
rm /tmp/${BACKUP_NAME}
olderThan=$(date --date "-7 days" +%s)
aws s3 ls awscli-main/backups/flask/ | while read -r line; do
    createDate=$(echo $line | awk '{print $1" "$2}')
    createDate=$(date -d "$createDate" +%s)
    if [[ $createDate -lt $olderThan ]]; then
        fileName=$(echo $line | awk '{print $4}')
        echo $filename
        if [[ $fileName != "" ]]; then
            aws s3 rm s3://awscli-main/backups/flask/$fileName
        fi
    fi
done
EOF

sudo chmod +x /home/ubuntu/backupSQLtoS3.sh

sudo tee /etc/systemd/system/backupSQLtoS3.service >/dev/null <<EOF
[Unit]
Description=Backup SQL dump to AWS S3 service

[Service]
User=ubuntu
Group=www-data
EnvironmentFile=/home/ubuntu/app.env
ExecStart=/bin/bash /home/ubuntu/backupSQLtoS3.sh

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/backupSQLtoS3.timer >/dev/null <<EOF
[Unit]
Description=Backup SQL dump to AWS S3 timer
Requires=backupSQLtoS3.service

[Timer]
Unit=backupSQLtoS3.service
OnCalendar=*-*-* 1:00:00
#OnCalendar=*-*-* *:0/5

[Install]
WantedBy=timers.target
EOF

sudo systemctl enable backupSQLtoS3.timer
sudo systemctl daemon-reload
sudo systemctl start backupSQLtoS3.timer
```

</details>
