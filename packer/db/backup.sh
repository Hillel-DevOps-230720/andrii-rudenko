#!/bin/bash
# shellcheck source=/dev/null
set -o allexport; source /home/ubuntu/.environment; set +o allexport

BACKUP_PATH="s3://${S3_NAME}/backups/app"
BACKUP_NAME="$(date +%Y-%m-%d-%H-%M-%S).sql.gz"

mysqldump -h 127.0.0.1 -P 3306 -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" | gzip > "/tmp/${BACKUP_NAME}"
aws s3 cp "/tmp/${BACKUP_NAME}" "${BACKUP_PATH}/${BACKUP_NAME}"
rm "/tmp/${BACKUP_NAME}"

olderThan="$(date --date "-7 days" +%s)"
aws s3 ls "${BACKUP_PATH}/" | while read -r line; do
    createDate="$(echo "$line" | awk '{print $1" "$2}')"
    createDate="$(date -d "$createDate" +%s)"
    if [[ "$createDate" -lt "$olderThan" ]]; then
        fileName="$(echo "$line" | awk '{print $4}')"
        if [[ "$fileName" != "" ]]; then
            aws s3 rm "${BACKUP_PATH}/$fileName"
        fi
    fi
done
