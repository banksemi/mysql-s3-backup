#!/bin/bash

set -e

echo "----------------------------------------------------"
echo "MySQL Backup and S3 Sync started at $(date)"
echo "----------------------------------------------------"

: "${MYSQL_HOST:?MYSQL_HOST not set}"
: "${MYSQL_PORT:?MYSQL_PORT not set}"
: "${MYSQL_USER:?MYSQL_USER not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD not set}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE not set}"
: "${S3_BUCKET_NAME:?S3_BUCKET_NAME not set}"
: "${AWS_REGION:?AWS_REGION not set}"

BACKUP_DIR="/var/lib/mysql_backup"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/mysql_backup_${TIMESTAMP}.sql"

echo "Backing up MySQL database(s) to ${BACKUP_FILE}..."


if [ "$MYSQL_DATABASE" = "all_databases" ]; then
    mariadb-dump --host="$MYSQL_HOST" \
              --port="$MYSQL_PORT" \
              --user="$MYSQL_USER" \
              --password="$MYSQL_PASSWORD" \
              --all-databases \
              --single-transaction \
              --quick \
              --events \
              --routines \
              --triggers \
              --add-drop-database \
              --add-drop-table \
              --default-character-set=utf8mb4 \
              --skip-ssl \
              > "$BACKUP_FILE"
else
    mariadb-dump --host="$MYSQL_HOST" \
              --port="$MYSQL_PORT" \
              --user="$MYSQL_USER" \
              --password="$MYSQL_PASSWORD" \
              --databases "$MYSQL_DATABASE" \
              --single-transaction \
              --quick \
              --events \
              --routines \
              --triggers \
              --add-drop-database \
              --add-drop-table \
              --default-character-set=utf8mb4 \
              --skip-ssl \
              > "$BACKUP_FILE"
fi

if [ $? -eq 0 ]; then
    echo "MySQL backup successful: $(basename "$BACKUP_FILE")"
else
    echo "ERROR: MySQL backup failed!"
    exit 1
fi

# S3 Sync (Use IAM Role)
echo "Syncing backup files to S3 bucket s3://${S3_BUCKET_NAME}..."

rclone move "$BACKUP_DIR" ":s3:${S3_BUCKET_NAME}" \
    --s3-env-auth \
    --s3-region "$AWS_REGION" \
    --progress

if [ $? -eq 0 ]; then
    echo "S3 sync successful."
else
    echo "ERROR: S3 sync failed! Check /var/log/rclone.log for details."
    exit 1
fi

echo "----------------------------------------------------"
echo "MySQL Backup and S3 Sync finished at $(date)"
echo "----------------------------------------------------"