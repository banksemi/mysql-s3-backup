FROM ubuntu:latest

ENV MYSQL_HOST=mysql_host_dummy \
    MYSQL_PORT=3306 \
    MYSQL_USER=backup_user_dummy \
    MYSQL_PASSWORD=backup_password_dummy \
    MYSQL_DATABASE=all_databases \
    S3_BUCKET_NAME=my-mysql-backup-bucket-dummy \
    AWS_REGION=ap-northeast-2

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mysql-client \
        rclone \
        cron \
        bash \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY backup.sh /app/backup.sh
COPY cron_job /etc/cron.d/mysql_backup_cron

RUN chmod +x /app/backup.sh && \
    chmod 0644 /etc/cron.d/mysql_backup_cron && \
    crontab /etc/cron.d/mysql_backup_cron

RUN mkdir -p /var/lib/mysql_backup

CMD cron -f