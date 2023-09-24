#!/bin/bash
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
. /home/ubuntu/backupSQLtoS3.sh

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
